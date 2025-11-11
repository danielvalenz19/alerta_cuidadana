import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'env.dart';
import '../features/auth/data/auth_interceptor.dart';

class HttpClient {
  static final Dio dio = Dio(BaseOptions(
    baseUrl: Env.apiBaseUrl, // ej. http://10.0.2.2:4000/api/v1
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  static final FlutterSecureStorage secure = const FlutterSecureStorage();

  static void setupInterceptors() {
    dio.interceptors.clear();
    dio.interceptors.add(AuthInterceptor(dio, secure));
    dio.interceptors.add(LogInterceptor(
      requestBody: true, responseBody: true, requestHeader: false));
  }
}
