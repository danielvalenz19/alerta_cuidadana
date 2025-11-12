import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../security/pin_vault.dart';
import '../settings/settings_controller.dart';
import '../theme/brand_decorations.dart';
import 'change_pin_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>();
    _nameCtrl = TextEditingController(text: settings.name);
    _phoneCtrl = TextEditingController(text: settings.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<SettingsController>().saveProfile(
        newName: _nameCtrl.text,
        newPhone: _phoneCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Guardado')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _ensureLocalPin() async {
    final storage = context.read<FlutterSecureStorage>();
    final vault = PinVault(storage);
    if (await vault.exists()) return true;
    if (!mounted) return false;
    final created = await _askSetPin(context);
    if (created && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN creado')));
      return true;
    }
    return false;
  }

  Future<bool> _askSetPin(BuildContext context) async {
    String first = '';
    String confirm = '';
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Configurar PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'PIN (4-6)'),
                  onChanged: (value) => first = value,
                ),
                const SizedBox(height: 12),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Confirmar PIN'),
                  onChanged: (value) => confirm = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  final formatOk = RegExp(r'^\d{4,6}$').hasMatch(first);
                  if (first == confirm && formatOk) {
                    final storage = context.read<FlutterSecureStorage>();
                    await PinVault(storage).setPin(first);
                    if (context.mounted) Navigator.of(context).pop(true);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String? _validateName(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Requerido' : null;

  String? _validatePhone(String? value) {
    if (value == null || value.trim().length < 8) return 'Telefono invalido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final colors = Theme.of(context).colorScheme;
    final deco = Theme.of(context).extension<BrandDecorations>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion')),
      body: Container(
        decoration: BoxDecoration(gradient: deco.screenGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _HeroBanner(
              name: settings.name,
              phone: settings.phone,
              colors: colors,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Tu perfil',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: _validateName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Telefono',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _saveProfile,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? 'Guardando...' : 'Guardar cambios',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Seguridad',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: colors.primary.withOpacity(0.15),
                            child: Icon(
                              Icons.pin_outlined,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tu PIN local se almacena cifrado en este dispositivo.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: colors.secondary.withOpacity(0.15),
                        child: Icon(
                          Icons.vpn_key_outlined,
                          color: colors.secondary,
                        ),
                      ),
                      title: const Text('Cambiar PIN'),
                      subtitle: const Text(
                        'Usado solo para cancelar una alerta',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final ready = await _ensureLocalPin();
                        if (!mounted || !ready) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChangePinPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Apariencia',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        settings.isDark ? 'Modo oscuro' : 'Modo claro',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: const Text('Se guarda en este dispositivo'),
                      value: settings.isDark,
                      onChanged: (_) => settings.toggleTheme(),
                      activeColor: colors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String name;
  final String phone;
  final ColorScheme colors;

  const _HeroBanner({
    required this.name,
    required this.phone,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final deco = Theme.of(context).extension<BrandDecorations>()!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: deco.cardGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: deco.floatingShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colors.primary.withOpacity(0.2),
            child: Icon(Icons.person_outline, color: colors.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Sin nombre' : name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  phone.isEmpty ? 'Telefono no asignado' : phone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Chip(
            avatar: Icon(Icons.shield_outlined, color: colors.onSecondary),
            label: Text(
              'Perfil activo',
              style: TextStyle(color: colors.onSecondary),
            ),
            backgroundColor: colors.secondary,
          ),
        ],
      ),
    );
  }
}
