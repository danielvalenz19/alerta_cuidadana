import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/http_client.dart';

class AuthRepository {
  final Dio _dio = HttpClient.dio;
  final FlutterSecureStorage _storage = HttpClient.secure;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    // Esperado: { access_token, refresh_token, user }
    final data = res.data as Map<String, dynamic>;
    await _storage.write(key: 'access_token', value: data['access_token']);
    await _storage.write(key: 'refresh_token', value: data['refresh_token']);
    await _storage.write(key: 'user', value: data['user'] != null ? data['user'].toString() : '{}');
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try { await _dio.post('/auth/logout'); } catch (_) {}
    await _storage.deleteAll();
  }
}
