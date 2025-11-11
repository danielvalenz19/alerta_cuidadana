import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/http_client.dart';

class AuthRepository {
  final Dio _dio = HttpClient.dio;
  final FlutterSecureStorage _storage = HttpClient.secure;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('auth/login', data: {
      'email': email,
      'password': password,
    });
    // Maneja múltiples formatos posibles del backend
    final data = Map<String, dynamic>.from(res.data as Map);

    String? pickToken(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    // tokens en raíz o anidado en 'data'
    final nested = (data['data'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(data['data'])
        : <String, dynamic>{};
    final access = pickToken(data, const ['access_token', 'accessToken', 'token', 'jwt'])
        ?? pickToken(nested, const ['access_token', 'accessToken', 'token', 'jwt']);
    final refresh = pickToken(data, const ['refresh_token', 'refreshToken'])
        ?? pickToken(nested, const ['refresh_token', 'refreshToken']);

    if (access == null || access.isEmpty) {
      throw Exception('El backend no retornó access_token en login');
    }

    await _storage.write(key: 'access_token', value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: 'refresh_token', value: refresh);
    }
    await _storage.write(key: 'user', value: (data['user'] ?? nested['user'])?.toString() ?? '{}');
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try { await _dio.post('auth/logout'); } catch (_) {}
    await _storage.deleteAll();
  }
}
