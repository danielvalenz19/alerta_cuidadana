import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../../../core/profile_cache.dart';
import '../../../settings/settings_controller.dart';
import '../../../theme/brand_decorations.dart';
import '../../../theme/tokens.dart';
import 'widgets/auth_gradient_button.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _ss = const FlutterSecureStorage();
  bool _obscurePassword = true;

  Future<void> _debugTokensOnce() async {
    try {
      final a = await _ss.read(key: 'access_token');
      final r = await _ss.read(key: 'refresh_token');
      // ignore: avoid_print
      print(
        'tokens: access=${a != null && a.isNotEmpty}, refresh=${r != null && r.isNotEmpty}',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final deco = Theme.of(context).extension<BrandDecorations>()!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: deco.screenGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroHeader(scheme: scheme),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Ingresa y activa tu escudo',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Mantente conectado y listo para responder a cualquier emergencia en segundos.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: _emailCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Correo',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Obligatorio'
                                      : null,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Contrasena',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Obligatorio'
                                      : null,
                                ),
                                const SizedBox(height: 24),
                                AuthGradientButton(
                                  loading: state.loading,
                                  label: 'Ingresar',
                                  onPressed: () async {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    final notifier = ref.read(
                                      authControllerProvider.notifier,
                                    );
                                    await notifier.login(
                                      _emailCtrl.text.trim(),
                                      _passCtrl.text,
                                    );
                                    if (!context.mounted) return;
                                    final authState = ref.read(
                                      authControllerProvider,
                                    );
                                    if (authState.authenticated) {
                                      await _debugTokensOnce();
                                      final profile = await loadCachedProfile(
                                        _ss,
                                      );
                                      if (!context.mounted) return;
                                      await context
                                          .read<SettingsController>()
                                          .saveProfile(
                                            newName: profile.name,
                                            newPhone: profile.phone,
                                          );
                                      if (!context.mounted) return;
                                      final nextRoute = authState.needsPinSetup
                                          ? '/set-pin'
                                          : '/home';
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed(nextRoute);
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed('/register'),
                                  icon: const Icon(Icons.person_add_alt_1),
                                  label: const Text('Crear cuenta ciudadana'),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: state.error == null
                                      ? const SizedBox.shrink()
                                      : Padding(
                                          key: ValueKey(state.error),
                                          padding: const EdgeInsets.only(
                                            top: 16,
                                          ),
                                          child: _ErrorBanner(
                                            message: state.error!,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _FooterBadge(scheme: scheme),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final ColorScheme scheme;
  const _HeroHeader({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.radar_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Red ciudadana activa',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            text: 'Protege tu entorno\n',
            style: Theme.of(context).textTheme.headlineLarge,
            children: [
              TextSpan(
                text: 'con un toque',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: scheme.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Recibe asistencia y cancela alertas con tu PIN personal. Toda la potencia de la plataforma en la palma de tu mano.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Tokens.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Tokens.danger.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: Tokens.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Tokens.danger,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterBadge extends StatelessWidget {
  final ColorScheme scheme;
  const _FooterBadge({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withOpacity(0.2)),
        color: scheme.surface.withOpacity(0.6),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primary.withOpacity(0.15),
            child: Icon(Icons.bolt, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Respuesta promedio: 14 segundos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Tu reporte prioriza a los equipos en campo.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
