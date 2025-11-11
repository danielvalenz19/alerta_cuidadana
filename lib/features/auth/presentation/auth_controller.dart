import 'package:alerta_ciudadana/core/providers.dart';
import 'package:alerta_ciudadana/security/pin_vault.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(AuthRepository(), ref.read(pinVaultProvider));
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final PinVault _vault;
  AuthController(this._repo, this._vault) : super(const AuthState());

  void setAuthenticated(bool value) {
    state = state.copyWith(authenticated: value);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.login(email, password);
      final hasPin = await _vault.exists();
      state = state.copyWith(
        loading: false,
        authenticated: true,
        needsPinSetup: !hasPin,
      );
    } catch (e) {
      var message = 'Error al iniciar sesion. Verifica tus credenciales.';
      final text = e.toString();
      if (text.isNotEmpty) {
        message = text.replaceFirst('Exception: ', '');
      }
      state = state.copyWith(
        loading: false,
        error: message,
        authenticated: false,
        needsPinSetup: false,
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      await _vault.clear();
      state = state.copyWith(
        loading: false,
        authenticated: true,
        needsPinSetup: true,
      );
    } catch (e) {
      var message = 'No se pudo registrar. Intenta mas tarde.';
      final text = e.toString();
      if (text.isNotEmpty) {
        message = text.replaceFirst('Exception: ', '');
      }
      state = state.copyWith(
        loading: false,
        error: message,
        authenticated: false,
        needsPinSetup: false,
      );
    }
  }

  void setNeedsPin(bool value) {
    state = state.copyWith(needsPinSetup: value);
  }
}
