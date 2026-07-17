import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

import '../models/ai_model.dart';
import '../models/appointment.dart';
import '../models/chat_event.dart';
import '../models/chat_session.dart';
import '../models/medical_record.dart';
import '../models/notification_item.dart';
import '../models/prediction.dart';
import '../models/user_profile.dart';
import 'auth_state.dart';

class ApiService {
  static const _base    = 'https://healthcompass.hasanai.net/api/v1';
  static final _storage = const FlutterSecureStorage();

  static Future<Dio> _client({bool retry = true}) async {
    final token = await _storage.read(key: 'access_token');
    final dio = Dio(BaseOptions(
      baseUrl: _base,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));
    if (retry) {
      dio.interceptors.add(InterceptorsWrapper(
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final newToken = await _storage.read(key: 'access_token');
              e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryClient = await _client(retry: false);
              final resp = await retryClient.fetch(e.requestOptions);
              return handler.resolve(resp);
            }
          }
          return handler.next(e);
        },
      ));
    }
    return dio;
  }

  // Guards against concurrent 401s each independently calling /auth/refresh/:
  // without this, two requests failing at once would race two refreshes,
  // and if either network call threw, that path's `deleteAll()` would wipe
  // out the access token the *other* concurrent refresh had just written —
  // forcing a spurious logout even though a valid session existed.
  static Completer<bool>? _refreshInFlight;

  static Future<bool> _refreshToken() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<bool>();
    _refreshInFlight = completer;
    _doRefresh().then((result) {
      _refreshInFlight = null;
      completer.complete(result);
    });
    return completer.future;
  }

  static Future<bool> _doRefresh() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return false;
    try {
      final dio = Dio(BaseOptions(baseUrl: _base));
      final res = await dio.post('/auth/refresh/', data: {'refresh': refresh});
      await _storage.write(key: 'access_token', value: res.data['access']);
      return true;
    } catch (_) {
      await _storage.deleteAll();
      authState.markLoggedOut();
      return false;
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final dio = await _client();
    final res = await dio.post('/auth/login/', data: {'email': email, 'password': password});
    await _storage.write(key: 'access_token',  value: res.data['access']);
    await _storage.write(key: 'refresh_token', value: res.data['refresh']);
    authState.markLoggedIn();
    return res.data;
  }

  static Future<Map<String, dynamic>> register(
      String email, String password, String fullName) async {
    final dio = await _client();
    final parts = fullName.trim().split(' ');
    final res = await dio.post('/auth/register/', data: {
      'email':      email,
      'password':   password,
      'password2':  password,
      'first_name': parts.first,
      'last_name':  parts.length > 1 ? parts.sublist(1).join(' ') : '',
    });
    await _storage.write(key: 'access_token',  value: res.data['access']);
    await _storage.write(key: 'refresh_token', value: res.data['refresh']);
    authState.markLoggedIn();
    return res.data;
  }

  static Future<void> forgotPassword(String email) async {
    final dio = await _client();
    await dio.post('/auth/forgot-password/', data: {'email': email});
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
    authState.markLoggedOut();
  }

  static Future<bool> isLoggedIn() async =>
      (await _storage.read(key: 'access_token')) != null;

  // ── User ──────────────────────────────────────────────────────────────────

  static Future<UserProfile> me() async {
    final dio = await _client();
    final res = await dio.get('/auth/me/');
    return UserProfile.fromJson(Map<String, dynamic>.from(res.data));
  }

  // ── Records ───────────────────────────────────────────────────────────────


  static Future<MedicalRecord> recordDetail(String id) async {
    final dio = await _client();
    final res = await dio.get('/records/$id/');
    return MedicalRecord.fromJson(Map<String, dynamic>.from(res.data));
  }

  static Future<MedicalRecord> uploadRecord({
    required Uint8List fileBytes,
    required String fileName,
    required String title,
    required String recordType,
    String? recordDate,
    String? notes,
  }) async {
    final dio = await _client();
    final formData = FormData.fromMap({
      'title':       title,
      'record_type': recordType,
      if (recordDate != null && recordDate.isNotEmpty) 'record_date': recordDate,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final res = await dio.post('/records/upload/', data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));
    return MedicalRecord.fromJson(Map<String, dynamic>.from(res.data));
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> dashboard() async {
    final dio = await _client();
    final res = await dio.get('/dashboard/');
    return res.data;
  }

  static Future<UserProfile> updateProfile({
    String? firstName, String? lastName, String? phone, String? dob,
  }) async {
    final dio = await _client();
    final res = await dio.patch('/auth/profile/', data: {
      if (firstName != null) 'first_name': firstName,
      if (lastName  != null) 'last_name':  lastName,
      if (phone     != null) 'phone_number': phone,
      if (dob       != null) 'date_of_birth': dob,
    });
    return UserProfile.fromJson(Map<String, dynamic>.from(res.data));
  }

  static Future<void> changePassword({
    required String oldPassword, required String newPassword,
  }) async {
    final dio = await _client();
    final res = await dio.post('/auth/change-password/',
        data: {'old_password': oldPassword, 'new_password': newPassword});
    await _storage.write(key: 'access_token',  value: res.data['access']);
    await _storage.write(key: 'refresh_token', value: res.data['refresh']);
  }

  static Future<EmergencyCard> emergencyCard() async {
    final dio = await _client();
    final res = await dio.get('/auth/emergency-card/');
    return EmergencyCard.fromJson(Map<String, dynamic>.from(res.data));
  }

  static Future<EmergencyCard> updateEmergencyCard({
    String? bloodType, String? allergies, String? contactName, String? contactPhone,
  }) async {
    final dio = await _client();
    final res = await dio.patch('/auth/emergency-card/', data: {
      'blood_type':              bloodType   ?? '',
      'allergies':               allergies   ?? '',
      'emergency_contact_name':  contactName ?? '',
      'emergency_contact_phone': contactPhone ?? '',
    });
    return EmergencyCard.fromJson(Map<String, dynamic>.from(res.data));
  }

  static Future<void> deleteRecord(String id) async {
    final dio = await _client();
    await dio.delete('/records/$id/delete/');
  }

  static Future<List<Prediction>> myPredictions() async {
    final dio = await _client();
    final res = await dio.get('/predictions/');
    return List<dynamic>.from(res.data)
        .map((e) => Prediction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Prediction> predictionDetail(String id) async {
    final dio = await _client();
    final res = await dio.get('/predictions/$id/');
    return Prediction.fromJson(Map<String, dynamic>.from(res.data));
  }

  static Future<AIModel> aiModelDetail(String slug) async {
    final dio = await _client();
    final res = await dio.get('/ai-models/$slug/');
    return AIModel.fromJson(Map<String, dynamic>.from(res.data));
  }

  static Future<Prediction> runModel(
      String slug, Map<String, dynamic> inputData) async {
    final dio = await _client();
    final res = await dio.post('/ai-models/$slug/run/', data: inputData);
    return Prediction.fromJson(Map<String, dynamic>.from(res.data));
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> analytics() async {
    final dio = await _client();
    final res = await dio.get('/analytics/');
    return Map<String, dynamic>.from(res.data);
  }

  static Future<List<dynamic>> alerts() async {
    final dio = await _client();
    final res = await dio.get('/alerts/');
    return List<dynamic>.from(res.data);
  }

  static Future<void> markAlertRead(String id) async {
    final dio = await _client();
    await dio.patch('/alerts/$id/read/');
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  static Future<List<NotificationItem>> notifications() async {
    final dio = await _client();
    final res = await dio.get('/notifications/');
    return List<dynamic>.from(res.data)
        .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> markNotificationRead(String id) async {
    final dio = await _client();
    await dio.patch('/notifications/$id/read/');
  }

  // ── AI Models ─────────────────────────────────────────────────────────────

  static Future<List<AIModel>> aiModels() async {
    final dio = await _client();
    final res = await dio.get('/ai-models/');
    return List<dynamic>.from(res.data)
        .map((e) => AIModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Map<String, dynamic>> uploadProfilePicture(
      Uint8List bytes, String fileName) async {
    final dio = await _client();
    // Infer MIME type from extension so the backend accepts it
    final ext = fileName.toLowerCase();
    String mime = 'image/jpeg';
    if (ext.endsWith('.png'))  mime = 'image/png';
    if (ext.endsWith('.webp')) mime = 'image/webp';
    if (ext.endsWith('.gif'))  mime = 'image/gif';
    final parts = mime.split('/');
    final formData = FormData.fromMap({
      'profile_picture': MultipartFile.fromBytes(bytes, filename: fileName,
          contentType: http_parser.MediaType(parts[0], parts[1])),
    });
    final res = await dio.post('/auth/profile/picture/', data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));
    return Map<String, dynamic>.from(res.data);
  }

  static Future<Map<String, dynamic>> populationInsights() async {
    final dio = await _client();
    final res = await dio.get('/population/');
    return Map<String, dynamic>.from(res.data);
  }

  static Future<List<MedicalRecord>> records({String? type, String? q, String? dateFrom, String? dateTo}) async {
    final dio = await _client();
    final params = <String, String>{};
    if (type     != null && type.isNotEmpty)     params['type']      = type;
    if (q        != null && q.isNotEmpty)        params['q']         = q;
    if (dateFrom != null && dateFrom.isNotEmpty) params['date_from'] = dateFrom;
    if (dateTo   != null && dateTo.isNotEmpty)   params['date_to']   = dateTo;
    final res = await dio.get('/records/', queryParameters: params.isEmpty ? null : params);
    return List<dynamic>.from(res.data)
        .map((e) => MedicalRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ── Seizure Analysis ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> seizureAnalysis(
      Uint8List fileBytes, String fileName) async {
    final dio = await _client();
    final formData = FormData.fromMap({
      'signal_file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final res = await dio.post('/seizure-analysis/', data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 150),
        ));
    return Map<String, dynamic>.from(res.data);
  }

  // ── Specialised record uploads ────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadPdf({
    required Uint8List bytes, required String fileName,
    String? recordType, String? notes,
  }) async {
    final dio = await _client();
    final form = FormData.fromMap({
      'pdf_file': MultipartFile.fromBytes(bytes, filename: fileName),
      if (recordType != null) 'record_type': recordType,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final res = await dio.post('/records/upload/pdf/', data: form,
        options: Options(headers: {'Content-Type': 'multipart/form-data'},
            receiveTimeout: const Duration(seconds: 60)));
    return Map<String, dynamic>.from(res.data);
  }

  static Future<Map<String, dynamic>> uploadText({
    required String text, String? recordType, String? notes,
  }) async {
    final dio = await _client();
    final res = await dio.post('/records/upload/text/', data: {
      'text': text,
      'record_type': recordType ?? 'auto',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Map<String, dynamic>.from(res.data);
  }

  static Future<Map<String, dynamic>> uploadKanta({
    required Uint8List bytes, required String fileName, String? notes,
  }) async {
    final dio = await _client();
    final form = FormData.fromMap({
      'xml_file': MultipartFile.fromBytes(bytes, filename: fileName),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final res = await dio.post('/records/upload/kanta/', data: form,
        options: Options(headers: {'Content-Type': 'multipart/form-data'},
            receiveTimeout: const Duration(seconds: 60)));
    return Map<String, dynamic>.from(res.data);
  }

  static Future<Map<String, dynamic>> uploadWearable({
    required Uint8List bytes, required String fileName, String? notes,
  }) async {
    final dio = await _client();
    final form = FormData.fromMap({
      'data_file': MultipartFile.fromBytes(bytes, filename: fileName),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final res = await dio.post('/records/upload/wearable/', data: form,
        options: Options(headers: {'Content-Type': 'multipart/form-data'},
            receiveTimeout: const Duration(seconds: 60)));
    return Map<String, dynamic>.from(res.data);
  }

  static Future<String> scanOcr({
    required Uint8List imageBytes, required String fileName,
  }) async {
    final dio = await _client();
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(imageBytes, filename: fileName),
    });
    final res = await dio.post('/records/upload/scan/', data: form,
        options: Options(headers: {'Content-Type': 'multipart/form-data'},
            receiveTimeout: const Duration(seconds: 60)));
    return (res.data['text'] ?? '').toString();
  }

  // ── Appointments ─────────────────────────────────────────────────────────

  static Future<List<Appointment>> appointments({String show = 'upcoming'}) async {
    final dio = await _client();
    final res = await dio.get('/appointments/', queryParameters: {'show': show});
    return List<dynamic>.from(res.data)
        .map((e) => Appointment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Appointment> createAppointment(Map<String, dynamic> data) async {
    final dio = await _client();
    final res = await dio.post('/appointments/', data: data);
    return Appointment.fromJson(Map<String, dynamic>.from(res.data));
  }

  static Future<Appointment> updateAppointment(String id, Map<String, dynamic> data) async {
    final dio = await _client();
    final res = await dio.patch('/appointments/$id/', data: data);
    return Appointment.fromJson(Map<String, dynamic>.from(res.data));
  }

  static Future<void> deleteAppointment(String id) async {
    final dio = await _client();
    await dio.delete('/appointments/$id/');
  }

  // ── Push notifications ────────────────────────────────────────────────────

  static Future<void> registerFcmToken(String token) async {
    final dio = await _client();
    await dio.post('/auth/fcm-token/', data: {'token': token});
  }

  // ── Assistant ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> ask(String query, {String? sessionId}) async {
    final dio = await _client();
    final res = await dio.post('/assistant/ask/', data: {
      'query': query,
      if (sessionId != null) 'session_id': sessionId,
    });
    return res.data;
  }

  /// Streams the assistant's reply token-by-token via SSE. The resolved
  /// session id (only available as a response header, not an SSE event) is
  /// reported through [onSessionId] as soon as the response starts.
  static Stream<ChatEvent> askStream(
    String query, {
    String? sessionId,
    void Function(String sessionId)? onSessionId,
  }) async* {
    final dio = await _client();
    final response = await dio.post<ResponseBody>(
      '/assistant/stream/',
      data: {
        'query': query,
        if (sessionId != null) 'session_id': sessionId,
      },
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 5),
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    final sid = response.headers.value('x-session-id');
    if (sid != null) onSessionId?.call(sid);

    var buffer = '';
    await for (final chunk in response.data!.stream) {
      buffer += utf8.decode(chunk, allowMalformed: true);
      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // keep the (possibly incomplete) trailing line
      for (final line in lines) {
        final event = ChatEvent.parseSseLine(line);
        if (event != null) yield event;
      }
    }
    if (buffer.isNotEmpty) {
      final event = ChatEvent.parseSseLine(buffer);
      if (event != null) yield event;
    }
  }

  static Future<List<ChatSession>> chatSessions() async {
    final dio = await _client();
    final res = await dio.get('/assistant/sessions/');
    final sessions = (res.data['sessions'] as List? ?? const []);
    return sessions.map((e) => ChatSession.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<({String title, List<ChatHistoryMessage> messages})> chatSessionDetail(String id) async {
    final dio = await _client();
    final res = await dio.get('/assistant/sessions/$id/');
    final data = Map<String, dynamic>.from(res.data);
    final messages = (data['messages'] as List? ?? const [])
        .map((e) => ChatHistoryMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (title: (data['title'] ?? 'Chat').toString(), messages: messages);
  }

  static Future<void> deleteChatSession(String id) async {
    final dio = await _client();
    await dio.delete('/assistant/sessions/$id/');
  }

  static Future<void> renameChatSession(String id, String title) async {
    final dio = await _client();
    await dio.patch('/assistant/sessions/$id/', data: {'title': title});
  }

  // ── ICU Dashboard ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> icuDashboard() async {
    final dio = await _client();
    final res = await dio.get('/icu/');
    return Map<String, dynamic>.from(res.data);
  }

  // ── Seizure Realtime Analyze ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> seizureRealtimeAnalyze(
      Uint8List fileBytes, String fileName) async {
    final dio = await _client();
    final formData = FormData.fromMap({
      'signal_file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final res = await dio.post('/seizure-realtime/analyze/', data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 180),
        ));
    return Map<String, dynamic>.from(res.data);
  }
}
