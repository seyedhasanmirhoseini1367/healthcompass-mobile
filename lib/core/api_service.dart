import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

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

  static Future<bool> _refreshToken() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return false;
    try {
      final dio = Dio(BaseOptions(baseUrl: _base));
      final res = await dio.post('/auth/refresh/', data: {'refresh': refresh});
      await _storage.write(key: 'access_token', value: res.data['access']);
      return true;
    } catch (_) {
      await _storage.deleteAll();
      return false;
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final dio = await _client();
    final res = await dio.post('/auth/login/', data: {'email': email, 'password': password});
    await _storage.write(key: 'access_token',  value: res.data['access']);
    await _storage.write(key: 'refresh_token', value: res.data['refresh']);
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
    return res.data;
  }

  static Future<void> forgotPassword(String email) async {
    final dio = await _client();
    await dio.post('/auth/forgot-password/', data: {'email': email});
  }

  static Future<void> logout() async => _storage.deleteAll();

  static Future<bool> isLoggedIn() async =>
      (await _storage.read(key: 'access_token')) != null;

  // ── User ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> me() async {
    final dio = await _client();
    final res = await dio.get('/auth/me/');
    return res.data;
  }

  // ── Records ───────────────────────────────────────────────────────────────


  static Future<Map<String, dynamic>> recordDetail(String id) async {
    final dio = await _client();
    final res = await dio.get('/records/$id/');
    return res.data;
  }

  static Future<Map<String, dynamic>> uploadRecord({
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
    return Map<String, dynamic>.from(res.data);
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> dashboard() async {
    final dio = await _client();
    final res = await dio.get('/dashboard/');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? firstName, String? lastName, String? phone, String? dob,
  }) async {
    final dio = await _client();
    final res = await dio.patch('/auth/profile/', data: {
      if (firstName != null) 'first_name': firstName,
      if (lastName  != null) 'last_name':  lastName,
      if (phone     != null) 'phone_number': phone,
      if (dob       != null) 'date_of_birth': dob,
    });
    return Map<String, dynamic>.from(res.data);
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

  static Future<Map<String, dynamic>> emergencyCard() async {
    final dio = await _client();
    final res = await dio.get('/auth/emergency-card/');
    return Map<String, dynamic>.from(res.data);
  }

  static Future<Map<String, dynamic>> updateEmergencyCard({
    String? bloodType, String? allergies, String? contactName, String? contactPhone,
  }) async {
    final dio = await _client();
    final res = await dio.patch('/auth/emergency-card/', data: {
      'blood_type':              bloodType   ?? '',
      'allergies':               allergies   ?? '',
      'emergency_contact_name':  contactName ?? '',
      'emergency_contact_phone': contactPhone ?? '',
    });
    return Map<String, dynamic>.from(res.data);
  }

  static Future<void> deleteRecord(String id) async {
    final dio = await _client();
    await dio.delete('/records/$id/delete/');
  }

  static Future<List<dynamic>> myPredictions() async {
    final dio = await _client();
    final res = await dio.get('/predictions/');
    return List<dynamic>.from(res.data);
  }

  static Future<Map<String, dynamic>> predictionDetail(String id) async {
    final dio = await _client();
    final res = await dio.get('/predictions/$id/');
    return Map<String, dynamic>.from(res.data);
  }

  static Future<Map<String, dynamic>> aiModelDetail(String slug) async {
    final dio = await _client();
    final res = await dio.get('/ai-models/$slug/');
    return Map<String, dynamic>.from(res.data);
  }

  static Future<Map<String, dynamic>> runModel(
      String slug, Map<String, dynamic> inputData) async {
    final dio = await _client();
    final res = await dio.post('/ai-models/$slug/run/', data: inputData);
    return Map<String, dynamic>.from(res.data);
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

  static Future<List<dynamic>> notifications() async {
    final dio = await _client();
    final res = await dio.get('/notifications/');
    return List<dynamic>.from(res.data);
  }

  static Future<void> markNotificationRead(String id) async {
    final dio = await _client();
    await dio.patch('/notifications/$id/read/');
  }

  // ── AI Models ─────────────────────────────────────────────────────────────

  static Future<List<dynamic>> aiModels() async {
    final dio = await _client();
    final res = await dio.get('/ai-models/');
    return List<dynamic>.from(res.data);
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

  static Future<List<dynamic>> records({String? type, String? q, String? dateFrom, String? dateTo}) async {
    final dio = await _client();
    final params = <String, String>{};
    if (type     != null && type.isNotEmpty)     params['type']      = type;
    if (q        != null && q.isNotEmpty)        params['q']         = q;
    if (dateFrom != null && dateFrom.isNotEmpty) params['date_from'] = dateFrom;
    if (dateTo   != null && dateTo.isNotEmpty)   params['date_to']   = dateTo;
    final res = await dio.get('/records/', queryParameters: params.isEmpty ? null : params);
    return res.data;
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

  static Future<List<dynamic>> appointments({String show = 'upcoming'}) async {
    final dio = await _client();
    final res = await dio.get('/appointments/', queryParameters: {'show': show});
    return List<dynamic>.from(res.data);
  }

  static Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> data) async {
    final dio = await _client();
    final res = await dio.post('/appointments/', data: data);
    return Map<String, dynamic>.from(res.data);
  }

  static Future<Map<String, dynamic>> updateAppointment(String id, Map<String, dynamic> data) async {
    final dio = await _client();
    final res = await dio.patch('/appointments/$id/', data: data);
    return Map<String, dynamic>.from(res.data);
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

  static Future<Map<String, dynamic>> ask(String query,
      {List history = const []}) async {
    final dio = await _client();
    final res = await dio.post('/assistant/ask/',
        data: {'query': query, 'history': history});
    return res.data;
  }
}
