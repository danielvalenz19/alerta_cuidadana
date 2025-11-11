import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/tokens.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _ss = const FlutterSecureStorage();

  Future<void> _debugTokensOnce() async {
    try {
      final a = await _ss.read(key: 'access_token');
      final r = await _ss.read(key: 'refresh_token');
      // ignore: avoid_print
      print('tokens: access=${a != null && a.isNotEmpty}, refresh=${r != null && r.isNotEmpty}');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: Tokens.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_rounded, size: 84, color: Tokens.primary),
                    const SizedBox(height: 16),
                    Text('Alerta Ciudadana', 
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Tokens.text, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v)=> (v==null||v.isEmpty) ? 'Obligatorio' : null,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (v)=> (v==null||v.isEmpty) ? 'Obligatorio' : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Tokens.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                        onPressed: state.loading ? null : () async {
                          if (_formKey.currentState!.validate()) {
                            await ref.read(authControllerProvider.notifier)
                                    .login(_emailCtrl.text.trim(), _passCtrl.text);
                            if (!context.mounted) return;
                            if (ref.read(authControllerProvider).authenticated) {
                              await _debugTokensOnce();
                              Navigator.of(context).pushReplacementNamed('/home');
                            }
                          }
                        },
                        child: state.loading
                          ? const CircularProgressIndicator.adaptive()
                          : const Text('Ingresar'),
                      ),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(state.error!, style: const TextStyle(color: Tokens.danger)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
