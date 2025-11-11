import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._dio, this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refresh = await _storage.read(key: 'refresh_token');
      if (refresh != null) {
        try {
          final resp = await _dio.post('/auth/refresh', data: {'refresh_token': refresh});
          final newAccess = resp.data['access_token'] as String?;
          if (newAccess != null) {
            await _storage.write(key: 'access_token', value: newAccess);
            final req = err.requestOptions;
            req.headers['Authorization'] = 'Bearer $newAccess';
            final retry = await _dio.fetch(req);
            return handler.resolve(retry);
          }
        } catch (_) {}
      }
      await _storage.deleteAll();
    }
    super.onError(err, handler);
  }
}
