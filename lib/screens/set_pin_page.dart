import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/auth/presentation/auth_controller.dart';

class SetPinPage extends ConsumerStatefulWidget {
  const SetPinPage({super.key});

  @override
  ConsumerState<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends ConsumerState<SetPinPage> {
  final _formKey = GlobalKey<FormState>();
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validator(String? value) {
    if (value == null || value.trim().isEmpty) return 'PIN requerido';
    if (value.length < 4 || value.length > 6) return 'PIN de 4 a 6 digitos';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Solo numeros';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pinCtrl.text.trim() != _confirmCtrl.text.trim()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los PIN no coinciden')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final pin = _pinCtrl.text.trim();
      await ref.read(pinVaultProvider).setPin(pin);
      ref.read(authControllerProvider.notifier).setNeedsPin(false);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el PIN: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar PIN')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Define un PIN de 4 a 6 digitos. Lo necesitaras para cancelar una alerta activa.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _pinCtrl,
                      decoration: const InputDecoration(labelText: 'PIN'),
                      keyboardType: TextInputType.number,
                      validator: _validator,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmCtrl,
                      decoration: const InputDecoration(labelText: 'Confirmar PIN'),
                      keyboardType: TextInputType.number,
                      validator: _validator,
                      obscureText: true,
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const CircularProgressIndicator.adaptive()
                          : const Text('Guardar PIN'),
                    ),
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
