import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'env.dart';
import '../features/auth/data/auth_interceptor.dart';

class HttpClient {
  static final Dio dio = Dio(BaseOptions(
    baseUrl: _normalizeBaseUrl(Env.apiBaseUrl), // asegura / final para rutas relativas
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  static final FlutterSecureStorage secure = const FlutterSecureStorage();

  static void setupInterceptors() {
    dio.interceptors.clear();
    dio.interceptors.add(AuthInterceptor(dio, secure));
    dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
    ));
  }

  static String _normalizeBaseUrl(String url) {
    if (url.isEmpty) return url;
    return url.endsWith('/') ? url : '$url/';
  }
}
