import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

class ChangePinPage extends ConsumerStatefulWidget {
  const ChangePinPage({super.key});

  @override
  ConsumerState<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends ConsumerState<ChangePinPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _nextCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _nextCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    if (value.length < 4 || value.length > 6) return 'PIN de 4 a 6 digitos';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Solo numeros';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nextCtrl.text.trim() != _confirmCtrl.text.trim()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los PIN no coinciden')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(pinVaultProvider).changePin(
            current: _currentCtrl.text.trim(),
            next: _nextCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN actualizado')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el PIN: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar PIN')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _currentCtrl,
                  decoration: const InputDecoration(labelText: 'PIN actual'),
                  keyboardType: TextInputType.number,
                  validator: _validator,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nextCtrl,
                  decoration: const InputDecoration(labelText: 'PIN nuevo'),
                  keyboardType: TextInputType.number,
                  validator: _validator,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  decoration: const InputDecoration(labelText: 'Confirmar PIN'),
                  keyboardType: TextInputType.number,
                  validator: _validator,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const CircularProgressIndicator.adaptive()
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
