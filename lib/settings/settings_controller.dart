import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const _kTheme = 'pref_theme_dark';

  bool _isDark = false;
  bool get isDark => _isDark;

  String name;
  String phone;
  int? userId;

  SettingsController({required this.name, required this.phone, this.userId});

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _isDark = sp.getBool(_kTheme) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kTheme, _isDark);
    notifyListeners();
  }

  Future<void> saveProfile({
    required String newName,
    required String newPhone,
    int? newUserId,
  }) async {
    name = newName.trim();
    phone = newPhone.trim();
    if (newUserId != null) {
      userId = newUserId;
    }
    notifyListeners();
  }
}
