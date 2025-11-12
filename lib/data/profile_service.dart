import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileService {
  ProfileService(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<Map<String, dynamic>> getMe() async {
    final token = await _token();
    if (token == null) throw Exception('Sin token');
    final response = await _dio.get('auth/me', options: _auth(token));
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Respuesta invalida del perfil');
  }

  Future<void> updateMe({required String name, required String phone}) async {
    final token = await _token();
    if (token == null) throw Exception('Sin token');
    final response = await _dio.put(
      'users/me',
      data: {'name': name, 'phone': phone},
      options: _auth(token),
    );
    final status = response.statusCode;
    if (status != null && status != 200 && status != 204) {
      throw Exception('Update perfil fallo ($status)');
    }
  }

  Future<String?> _token() async {
    final primary = await _storage.read(key: 'access_token');
    if (primary != null && primary.isNotEmpty) return primary;
    final legacy = await _storage.read(key: 'accessToken');
    if (legacy != null && legacy.isNotEmpty) return legacy;
    return null;
  }

  Options _auth(String token) => Options(
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
}
