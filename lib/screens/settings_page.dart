import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../data/profile_service.dart';
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
    _phoneCtrl = TextEditingController(
      text: _formatPhoneForInput(settings.phone),
    );
    Future.microtask(_loadProfileFromBackend);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final storage = context.read<FlutterSecureStorage>();
    final vault = PinVault(storage);
    if (!await vault.exists()) {
      _showSnackBar('Configura tu PIN antes de guardar');
      return;
    }
    final locked = await vault.lockoutRemaining();
    if (locked != null) {
      _showSnackBar(_lockMessage(locked));
      return;
    }

    final pin = await _askPinDialog('Ingresa tu PIN para confirmar');
    if (pin == null) return;
    final ok = await vault.verify(pin);
    if (!ok) {
      final remaining = await vault.lockoutRemaining();
      _showSnackBar(
        remaining != null ? _lockMessage(remaining) : 'PIN incorrecto',
      );
      return;
    }

    final normalizedPhone = _normalizePhoneForApi(_phoneCtrl.text);
    final trimmedName = _nameCtrl.text.trim();
    setState(() => _saving = true);
    try {
      await context.read<ProfileService>().updateMe(
        name: trimmedName,
        phone: normalizedPhone,
      );
      await context.read<SettingsController>().saveProfile(
        newName: trimmedName,
        newPhone: normalizedPhone,
      );
      _showSnackBar('Perfil actualizado');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        _showSnackBar(
          'El backend no tiene PUT /api/v1/users/me habilitado (404).',
        );
      } else if (status == 403) {
        _showSnackBar('Tu rol no tiene permiso para editar (403).');
      } else {
        final backend = e.response?.data;
        if (backend is String && backend.trim().isNotEmpty) {
          _showSnackBar('Error actualizando: ${backend.trim()}');
        } else {
          _showSnackBar('Error actualizando: ${e.message}');
        }
      }
    } catch (e) {
      _showSnackBar('Error: $e');
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
      _showSnackBar('PIN creado');
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

  Future<void> _loadProfileFromBackend() async {
    try {
      final svc = context.read<ProfileService>();
      final me = await svc.getMe();
      final name = (me['name'] ?? '').toString();
      final normalizedPhone = _normalizeBackendPhone(me['phone']);
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = name;
        _phoneCtrl.text = _formatPhoneForInput(normalizedPhone);
      });
      await context.read<SettingsController>().saveProfile(
        newName: name,
        newPhone: normalizedPhone,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('No pude leer perfil: $e');
    }
  }

  Future<String?> _askPinDialog(String title) async {
    String buffer = '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          keyboardType: TextInputType.number,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'PIN (4-6 digitos)'),
          onChanged: (value) => buffer = value,
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(buffer.trim()),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    final value = result?.trim() ?? '';
    if (value.isEmpty) return null;
    return value;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _lockMessage(Duration remaining) {
    final totalSeconds = remaining.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return 'PIN bloqueado. Intenta en $minutes:$seconds';
  }

  String _normalizePhoneForApi(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    var normalized = digits;
    if (!normalized.startsWith('502')) {
      normalized = '502$normalized';
    }
    return '+$normalized';
  }

  String _normalizeBackendPhone(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) return '';
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    var normalized = digits;
    if (!normalized.startsWith('502')) {
      normalized = '502$normalized';
    }
    return '+$normalized';
  }

  String _formatPhoneForInput(String phone) {
    if (phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('502')) {
      return digits.substring(3);
    }
    return digits;
  }

  String? _validateName(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Requerido' : null;

  String? _validatePhone(String? value) {
    if (value == null || !RegExp(r'^\d{8}$').hasMatch(value.trim())) {
      return 'Telefono invalido (8 digitos)';
    }
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
