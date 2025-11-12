import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../../settings/settings_controller.dart';
import '../../../theme/brand_decorations.dart';
import '../../../theme/tokens.dart';
import 'auth_controller.dart';
import 'widgets/auth_gradient_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label es obligatorio';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final text = value ?? '';
    if (text.trim().isEmpty) return 'Correo es obligatorio';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!regex.hasMatch(text.trim())) return 'Correo invalido';
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Contrasena obligatoria';
    if (value.length < 6) return 'Minimo 6 caracteres';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contrasenas no coinciden')),
      );
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState.authenticated) {
      await context.read<SettingsController>().saveProfile(
        newName: _nameCtrl.text.trim(),
        newPhone: _phoneCtrl.text.trim(),
      );
      final next = authState.needsPinSetup ? '/set-pin' : '/home';
      Navigator.of(context).pushNamedAndRemoveUntil(next, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final deco = Theme.of(context).extension<BrandDecorations>()!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: deco.screenGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RegisterHeader(scheme: scheme),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _StepChips(scheme: scheme),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre completo',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (v) => _required(v, 'Nombre'),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Correo',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: _emailValidator,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _phoneCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Telefono (opcional)',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Contrasena',
                                    prefixIcon: const Icon(Icons.lock_outline),
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
                                  validator: _passwordValidator,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar contrasena',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  obscureText: _obscureConfirm,
                                  validator: _passwordValidator,
                                ),
                                const SizedBox(height: 28),
                                AuthGradientButton(
                                  loading: state.loading,
                                  label: 'Activar mi cuenta',
                                  onPressed: state.loading ? null : _submit,
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: const Text('Ya tengo cuenta'),
                                ),
                                if (state.error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Tokens.danger.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      state.error!,
                                      style: TextStyle(
                                        color: Tokens.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _ValuePropsRow(scheme: scheme),
                      ],
                    ),
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

class _RegisterHeader extends StatelessWidget {
  final ColorScheme scheme;
  const _RegisterHeader({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conectate a la red de seguridad',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Tu perfil sincroniza dispositivos, PIN local y notificaciones en tiempo real.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _StepChips extends StatelessWidget {
  final ColorScheme scheme;
  const _StepChips({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final steps = [('1', 'Tus datos'), ('2', 'Contacto'), ('3', 'PIN')];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: steps
          .map(
            (step) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: step.$1 == '1'
                      ? scheme.primary.withOpacity(0.15)
                      : scheme.surfaceVariant.withOpacity(0.6),
                  border: Border.all(
                    color: step.$1 == '1'
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      step.$1,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: step.$1 == '1'
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.$2,
                      style: TextStyle(
                        fontSize: 12,
                        color: step.$1 == '1'
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ValuePropsRow extends StatelessWidget {
  final ColorScheme scheme;
  const _ValuePropsRow({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.shield_moon_outlined, 'Escudo nocturno'),
      (Icons.key_rounded, 'PIN offline'),
      (Icons.near_me, 'Ubicacion precisa'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: scheme.surface.withOpacity(0.7),
                border: Border.all(color: scheme.primary.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$1, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    item.$2,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
