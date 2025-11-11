import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../security/pin_vault.dart';
import 'http_client.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((_) => HttpClient.secure);

final pinVaultProvider = Provider<PinVault>((ref) {
  final storage = ref.read(secureStorageProvider);
  return PinVault(storage);
});
