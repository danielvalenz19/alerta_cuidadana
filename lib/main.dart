import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart' as app_provider;

import 'app.dart';
import 'core/http_client.dart';
import 'core/profile_cache.dart';
import 'data/profile_service.dart';
import 'settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  HttpClient.setupInterceptors();

  final storage = HttpClient.secure;
  final profileService = ProfileService(HttpClient.dio, storage);
  final profile = await loadCachedProfile(storage);
  final settings = SettingsController(
    name: profile.name,
    phone: profile.phone,
  );
  await settings.load();

  runApp(
    ProviderScope(
      child: app_provider.MultiProvider(
        providers: [
          app_provider.ChangeNotifierProvider.value(value: settings),
          app_provider.Provider<FlutterSecureStorage>.value(value: storage),
          app_provider.Provider<ProfileService>.value(value: profileService),
        ],
        child: const App(initialRoute: '/'),
      ),
    ),
  );
}
