import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<({String name, String phone})> loadCachedProfile(
  FlutterSecureStorage storage,
) async {
  try {
    final raw = await storage.read(key: 'user');
    if (raw == null || raw.isEmpty) return (name: '', phone: '');
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return (name: '', phone: '');
    final name = _pick(decoded, const ['name', 'fullName', 'full_name']) ?? '';
    final phone =
        _pick(decoded, const ['phone', 'telefono', 'tel', 'mobile']) ?? '';
    return (name: name.trim(), phone: phone.trim());
  } catch (_) {
    return (name: '', phone: '');
  }
}

String? _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}
