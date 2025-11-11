class AuthState {
  final bool loading;
  final String? error;
  final bool authenticated;

  const AuthState({this.loading=false, this.error, this.authenticated=false});

  AuthState copyWith({bool? loading, String? error, bool? authenticated}) =>
    AuthState(
      loading: loading ?? this.loading,
      error: error,
      authenticated: authenticated ?? this.authenticated,
    );
}
