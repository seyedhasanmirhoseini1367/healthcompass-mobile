import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const _base = 'https://healthcompass.hasanai.net/api/v1';
  static final _storage = FlutterSecureStorage();

  static Future<Dio> _client() async {
    final token = await _storage.read(key: 'access_token');
    return Dio(BaseOptions(
      baseUrl: _base,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final dio = await _client();
    final res = await dio.post('/auth/login/', data: {'email': email, 'password': password});
    await _storage.write(key: 'access_token',  value: res.data['access']);
    await _storage.write(key: 'refresh_token', value: res.data['refresh']);
    return res.data;
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  // ── User ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> me() async {
    final dio = await _client();
    final res = await dio.get('/auth/me/');
    return res.data;
  }

  // ── Records ───────────────────────────────────────────────────────────────

  static Future<List<dynamic>> records({String? type}) async {
    final dio = await _client();
    final res = await dio.get('/records/', queryParameters: type != null ? {'type': type} : null);
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

  static Future<Map<String, dynamic>> ask(String query, {List history = const []}) async {
    final dio = await _client();
    final res = await dio.post('/assistant/ask/', data: {'query': query, 'history': history});
    return res.data;
  }
}
