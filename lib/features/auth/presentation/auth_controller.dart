import 'dart:io';

import 'package:alerta_ciudadana/core/providers.dart';
import 'package:alerta_ciudadana/security/pin_vault.dart';
import 'package:dio/dio.dart';
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
      state = state.copyWith(
        loading: false,
        error: _describeError(
          e,
          fallback: 'No pudimos iniciar sesion. Verifica tus datos e intenta de nuevo.',
        ),
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
      state = state.copyWith(
        loading: false,
        error: _describeError(
          e,
          fallback: 'No se pudo registrar. Intenta mas tarde.',
        ),
        authenticated: false,
        needsPinSetup: false,
      );
    }
  }

  void setNeedsPin(bool value) {
    state = state.copyWith(needsPinSetup: value);
  }

  String _describeError(
    Object error, {
    required String fallback,
  }) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401) {
        return 'Correo o contrasena incorrectos. Vuelve a intentarlo.';
      }
      final backend = _extractBackendMessage(error.response?.data);
      if (backend != null && backend.isNotEmpty) {
        return backend;
      }
      if (_isTimeout(error.type)) {
        return 'La conexion tardo demasiado. Revisa tu internet.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.error is SocketException) {
        return 'No pudimos conectarnos con el servidor. Comprueba tu conexion.';
      }
      if (status != null) {
        if (status >= 500) {
          return 'Estamos presentando inconvenientes. Intenta nuevamente mas tarde.';
        }
        if (status >= 400) {
          return 'No pudimos procesar la solicitud ($status). Verifica los datos ingresados.';
        }
      }
    } else if (error is SocketException) {
      return 'No pudimos conectarnos. Revisa tu internet.';
    }

    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.isNotEmpty && !text.startsWith('DioException')) {
      return text;
    }
    return fallback;
  }

  bool _isTimeout(DioExceptionType type) {
    return type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout;
  }

  String? _extractBackendMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final text = data.trim();
      if (text.isNotEmpty) return text;
    }
    if (data is Map) {
      final map = <String, dynamic>{};
      data.forEach((key, value) {
        map[key.toString()] = value;
      });
      const candidates = ['message', 'error', 'detail', 'description'];
      for (final key in candidates) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      final errors = map['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is String && first.trim().isNotEmpty) {
          return first.trim();
        }
        if (first is Map) {
          for (final key in candidates) {
            final value = first[key];
            if (value is String && value.trim().isNotEmpty) {
              return value.trim();
            }
          }
        }
      }
    }
    return null;
  }
}
