import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl {
    final v = dotenv.env['API_BASE_URL'];
    if (v == null || v.isEmpty) {
      throw Exception('API_BASE_URL no configurado');
    }
    return v;
  }
}
