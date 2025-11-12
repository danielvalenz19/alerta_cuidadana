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
  bool _editing = false;
  String _origName = '';
  String _origPhone = '';
  int? _userId;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>();
    _origName = settings.name;
    _origPhone = settings.phone;
    _userId = settings.userId;
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    Future.microtask(_loadProfileFromBackend);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_editing) return;
    if (!_formKey.currentState!.validate()) return;

    final trimmedName = _nameCtrl.text.trim();
    final phoneDigits = _phoneCtrl.text.trim();
    final normalizedPhone = phoneDigits.isEmpty
        ? ''
        : _normalizePhoneForApi(phoneDigits);

    final delta = <String, dynamic>{};
    if (trimmedName.isNotEmpty && trimmedName != _origName) {
      delta['full_name'] = trimmedName;
    }
    if (normalizedPhone.isNotEmpty && normalizedPhone != _origPhone) {
      delta['phone'] = normalizedPhone;
    }

    if (delta.isEmpty) {
      _showSnackBar('Sin cambios');
      return;
    }

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

    final profileService = context.read<ProfileService>();
    final settingsController = context.read<SettingsController>();

    setState(() => _saving = true);
    try {
      final response = await profileService.patchProfile(
        delta: delta,
        userId: _userId,
      );
      final responseName = _pickName(response);
      final responsePhone = _normalizeBackendPhone(_pickPhone(response));
      final nextUserId = _userId ?? _extractUserId(response);

      final effectiveName = responseName.isNotEmpty
          ? responseName
          : trimmedName;
      final effectivePhone = responsePhone.isNotEmpty
          ? responsePhone
          : (normalizedPhone.isNotEmpty ? normalizedPhone : _origPhone);

      _origName = effectiveName;
      _origPhone = effectivePhone;
      _userId = nextUserId;

      await settingsController.saveProfile(
        newName: effectiveName,
        newPhone: effectivePhone,
        newUserId: nextUserId,
      );
      if (!mounted) return;
      setState(() {
        _editing = false;
        _nameCtrl.clear();
        _phoneCtrl.clear();
      });
      _showSnackBar('Perfil actualizado');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 405) {
        if (_userId == null) {
          _showSnackBar('No se encontro endpoint de autoedicion (404/405).');
        } else {
          _showSnackBar(
            'El backend no acepta PATCH /auth/me (status $status).',
          );
        }
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

  void _enterEdit(SettingsController settings) {
    setState(() {
      _editing = true;
      _nameCtrl.text = settings.name;
      _phoneCtrl.text = _formatPhoneForInput(settings.phone);
      _origName = settings.name;
      _origPhone = settings.phone;
      _userId = settings.userId ?? _userId;
    });
  }

  void _cancelEdit() {
    FocusScope.of(context).unfocus();
    setState(() {
      _editing = false;
      _nameCtrl.clear();
      _phoneCtrl.clear();
    });
    _formKey.currentState?.reset();
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
      final controller = context.read<SettingsController>();
      final me = await svc.getMe();
      final name = _pickName(me);
      final normalizedPhone = _normalizeBackendPhone(_pickPhone(me));
      final userId = _extractUserId(me);
      if (!mounted) return;
      _origName = name;
      _origPhone = normalizedPhone;
      _userId = userId ?? _userId;
      if (_editing) {
        setState(() {
          _nameCtrl.text = name;
          _phoneCtrl.text = _formatPhoneForInput(normalizedPhone);
        });
      }
      await controller.saveProfile(
        newName: name,
        newPhone: normalizedPhone,
        newUserId: _userId,
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

  String _pickName(Map<String, dynamic> source) {
    final value = _pickFromKeys(source, const [
      'full_name',
      'fullName',
      'name',
    ]);
    if (value != null && value.isNotEmpty) return value;
    for (final nestedKey in ['user', 'data']) {
      final nested = source[nestedKey];
      if (nested is Map<String, dynamic>) {
        final nestedValue = _pickName(nested);
        if (nestedValue.isNotEmpty) return nestedValue;
      }
    }
    return '';
  }

  String _pickPhone(Map<String, dynamic> source) {
    final value = _pickFromKeys(source, const [
      'phone',
      'telefono',
      'tel',
      'mobile',
    ]);
    if (value != null && value.isNotEmpty) return value;
    for (final nestedKey in ['user', 'data']) {
      final nested = source[nestedKey];
      if (nested is Map<String, dynamic>) {
        final nestedValue = _pickPhone(nested);
        if (nestedValue.isNotEmpty) return nestedValue;
      }
    }
    return '';
  }

  int? _extractUserId(Map<String, dynamic> source) {
    final raw = _pickFromKeys(source, const ['id', 'user_id', 'userId']);
    final parsed = raw != null ? int.tryParse(raw) : null;
    if (parsed != null) return parsed;
    for (final nestedKey in ['user', 'data']) {
      final nested = source[nestedKey];
      if (nested is Map<String, dynamic>) {
        final nestedId = _extractUserId(nested);
        if (nestedId != null) return nestedId;
      }
    }
    return null;
  }

  String? _pickFromKeys(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num) {
        return value.toString();
      }
    }
    return null;
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
                      Row(
                        children: [
                          Text(
                            'Tu perfil',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          if (!_editing)
                            TextButton.icon(
                              onPressed: () => _enterEdit(settings),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar'),
                            )
                          else
                            TextButton.icon(
                              onPressed: _saving ? null : _cancelEdit,
                              icon: const Icon(Icons.close),
                              label: const Text('Cancelar'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        enabled: _editing && !_saving,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: _editing ? _validateName : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        enabled: _editing && !_saving,
                        decoration: const InputDecoration(
                          labelText: 'Telefono',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: _editing ? _validatePhone : null,
                      ),
                      if (_editing) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
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
                      ],
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
