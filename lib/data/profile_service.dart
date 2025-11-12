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
    return _asMap(response.data);
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

  Future<Map<String, dynamic>> patchProfile({
    required Map<String, dynamic> delta,
    int? userId,
  }) async {
    if (delta.isEmpty) {
      throw ArgumentError('delta no puede estar vacio');
    }
    final token = await _token();
    if (token == null) throw Exception('Sin token');
    final options = _auth(token);
    try {
      final response = await _dio.patch(
        'auth/me',
        data: delta,
        options: options,
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final needsFallback = userId != null && (status == 404 || status == 405);
      if (needsFallback) {
        final fallback = await _dio.patch(
          'admin/users/$userId',
          data: delta,
          options: options,
        );
        return _asMap(fallback.data);
      }
      rethrow;
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

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }
}
