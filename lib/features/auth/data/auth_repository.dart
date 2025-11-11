import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/http_client.dart';
import '../../../security/pin_vault.dart';

class AuthRepository {
  final Dio _dio = HttpClient.dio;
  final FlutterSecureStorage _storage = HttpClient.secure;
  final PinVault _vault = PinVault(HttpClient.secure);

  Future<void> login(String email, String password) async {
    await _clearAuthKeys();
    final res = await _dio.post('auth/login', data: {
      'email': email,
      'password': password,
    });
    await _persistSession(res.data);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    await _clearAuthKeys();
    final body = {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };
    final res = await _dio.post('auth/register', data: body);
    await _persistSession(res.data);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try {
      await _dio.post('auth/logout');
    } catch (_) {}
    await _clearAuthKeys();
    await _vault.clear();
  }

  Future<Map<String, dynamic>> _persistSession(dynamic raw) async {
    if (raw is! Map) {
      throw Exception('El backend retorno una respuesta invalida');
    }
    final data = Map<String, dynamic>.from(raw);
    final nested = _asMap(data['data']);

    String? pickToken(Map<String, dynamic>? m, List<String> keys) {
      if (m == null) return null;
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    final access = pickToken(data, const ['access_token', 'accessToken', 'token', 'jwt']) ??
        pickToken(nested, const ['access_token', 'accessToken', 'token', 'jwt']);
    final refresh = pickToken(data, const ['refresh_token', 'refreshToken']) ??
        pickToken(nested, const ['refresh_token', 'refreshToken']);

    if (access == null || access.isEmpty) {
      throw Exception('El backend no retorno access_token en login');
    }

    final role = _extractRole(access);
    if (role != null && role != 'citizen') {
      await _clearAuthKeys();
      throw Exception('El rol $role no esta autorizado para reportar incidentes');
    }

    await _storage.write(key: 'access_token', value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: 'refresh_token', value: refresh);
    }

    final user = _asMap(data['user']) ?? _asMap(nested?['user']);
    await _storage.write(key: 'user', value: jsonEncode(user ?? const {}));

    final payload = {
      ...data,
      if (nested != null) 'data': nested,
      if (user != null) 'user': user,
    };
    return payload;
  }

  Future<void> _clearAuthKeys() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user');
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String? _extractRole(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = json.decode(payload);
      if (decoded is Map<String, dynamic>) {
        final dynamic role = decoded['role'] ?? decoded['rol'];
        if (role is String && role.isNotEmpty) {
          return role.toLowerCase();
        }
      }
    } catch (_) {}
    return null;
  }
}
