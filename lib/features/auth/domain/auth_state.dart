class AuthState {
  final bool loading;
  final String? error;
  final bool authenticated;
  final bool needsPinSetup;

  const AuthState({
    this.loading = false,
    this.error,
    this.authenticated = false,
    this.needsPinSetup = false,
  });

  AuthState copyWith({
    bool? loading,
    String? error,
    bool? authenticated,
    bool? needsPinSetup,
  }) =>
      AuthState(
        loading: loading ?? this.loading,
        error: error,
        authenticated: authenticated ?? this.authenticated,
        needsPinSetup: needsPinSetup ?? this.needsPinSetup,
      );
}
