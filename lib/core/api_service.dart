import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  static Future<List<dynamic>> records({String? type}) async {
    final dio = await _client();
    final res = await dio.get('/records/',
        queryParameters: type != null ? {'type': type} : null);
    return res.data;
  }

  static Future<Map<String, dynamic>> recordDetail(int id) async {
    final dio = await _client();
    final res = await dio.get('/records/$id/');
    return res.data;
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> dashboard() async {
    final dio = await _client();
    final res = await dio.get('/dashboard/');
    return res.data;
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
