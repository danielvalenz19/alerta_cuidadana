import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(AuthRepository());
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthController(this._repo) : super(const AuthState());

  void setAuthenticated(bool value) {
    state = state.copyWith(authenticated: value);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.login(email, password);
      state = state.copyWith(loading: false, authenticated: true);
    } catch (e) {
      var message = 'Error al iniciar sesion. Verifica tus credenciales.';
      final text = e.toString();
      if (text.isNotEmpty) {
        message = text.replaceFirst('Exception: ', '');
      }
      state = state.copyWith(loading: false, error: message, authenticated: false);
    }
  }
}
