import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../services/incident_service.dart';
import '../state/incident_state.dart';
import '../theme/brand_decorations.dart';

final incidentServiceProvider = Provider<IncidentService>(
  (_) => IncidentService(),
);
final incidentStateProvider = ChangeNotifierProvider<IncidentState>(
  (_) => IncidentState(),
);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _pulse;
  bool _cancelingCountdown = false;
  bool _cancelingIncident = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _startCountdown() async {
    final st = ref.read(incidentStateProvider);
    st.startCountdown(5);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final state = ref.read(incidentStateProvider);
      if (state.countdown <= 1) {
        timer.cancel();
        await _createIncident();
      } else {
        state.tickCountdown();
      }
    });
  }

  Future<void> _createIncident() async {
    final st = ref.read(incidentStateProvider);
    try {
      final svc = ref.read(incidentServiceProvider);
      final id = await svc.createIncident();
      if (!mounted) return;
      st.setActive(id);
      _showSnackBar('Alerta enviada!');
    } catch (e) {
      if (!mounted) return;
      st.reset();
      _showSnackBar('No se pudo crear el incidente: $e');
    }
  }

  Future<void> _cancelIncident() async {
    final st = ref.read(incidentStateProvider);
    final id = st.currentIncidentId;
    if (id == null || _cancelingIncident) return;

    final vault = ref.read(pinVaultProvider);
    if (!await vault.exists()) {
      _showSnackBar('Configura tu PIN antes de cancelar');
      return;
    }
    final lock = await vault.lockoutRemaining();
    if (lock != null) {
      _showSnackBar(_lockMessage(lock));
      return;
    }

    final pin = await _askPin(title: 'Cancelar alerta');
    if (pin == null || pin.isEmpty) return;

    setState(() => _cancelingIncident = true);
    try {
      final valid = await vault.verify(pin);
      if (!valid) {
        final remaining = await vault.lockoutRemaining();
        _showSnackBar(
          remaining != null ? _lockMessage(remaining) : 'PIN incorrecto',
        );
        return;
      }
      final svc = ref.read(incidentServiceProvider);
      await svc.cancelIncident(id, reason: 'cancelado_desde_app');
      st.reset();
      if (!mounted) return;
      _showSnackBar('Incidente cancelado');
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      if (status == 409) {
        st.reset();
        _showSnackBar('El incidente ya habia finalizado');
      } else {
        _showSnackBar('No se pudo cancelar: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('No se pudo cancelar: $e');
    } finally {
      if (mounted) {
        setState(() => _cancelingIncident = false);
      }
    }
  }

  void _showSnackBar(String message) {
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

  Future<String?> _askPin({required String title}) async {
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

  Future<void> _handleCountdownCancel() async {
    if (_cancelingCountdown) return;
    final vault = ref.read(pinVaultProvider);
    final hasPin = await vault.exists();
    if (!hasPin) {
      if (!mounted) return;
      _showSnackBar('Configura tu PIN antes de cancelar');
      return;
    }
    final lock = await vault.lockoutRemaining();
    if (lock != null) {
      _showSnackBar(_lockMessage(lock));
      return;
    }
    final pin = await _askPin(title: 'Cancelar envio');
    if (pin == null) return;
    setState(() => _cancelingCountdown = true);
    final valid = await vault.verify(pin);
    if (!mounted) return;
    if (valid) {
      _timer?.cancel();
      ref.read(incidentStateProvider).reset();
      _showSnackBar('Cuenta regresiva cancelada');
    } else {
      final remaining = await vault.lockoutRemaining();
      _showSnackBar(
        remaining != null ? _lockMessage(remaining) : 'PIN incorrecto',
      );
    }
    setState(() => _cancelingCountdown = false);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(incidentStateProvider);
    final scheme = Theme.of(context).colorScheme;
    final deco = Theme.of(context).extension<BrandDecorations>()!;
    final isIdle = st.phase == IncidentPhase.idle;
    final isCountdown = st.phase == IncidentPhase.countdown;
    final isActive = st.phase == IncidentPhase.active;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alerta Ciudadana'),
            Text(
              isActive
                  ? 'Alerta en curso'
                  : isCountdown
                  ? 'Preparando envio'
                  : 'Listo para actuar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: scheme.primary.withOpacity(0.15),
              ),
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: deco.screenGradient),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusStrip(
                    scheme: scheme,
                    phase: st.phase,
                    countdown: st.countdown,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: _buildActionButton(
                        scheme: scheme,
                        deco: deco,
                        isIdle: isIdle,
                        isActive: isActive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InsightsCard(
                    scheme: scheme,
                    deco: deco,
                    phase: st.phase,
                    countdown: st.countdown,
                    canceling: _cancelingIncident,
                    onCancel: _cancelIncident,
                  ),
                ],
              ),
            ),
            if (isCountdown)
              _CountdownOverlay(
                countdown: st.countdown,
                cancelingCountdown: _cancelingCountdown,
                onCancel: _handleCountdownCancel,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required ColorScheme scheme,
    required BrandDecorations deco,
    required bool isIdle,
    required bool isActive,
  }) {
    final gradient = isActive
        ? deco.actionGradient
        : LinearGradient(
            colors: [scheme.primary, scheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final icon = isActive ? Icons.sos_rounded : Icons.shield_moon_outlined;
    final label = isActive ? 'Alerta activa' : 'Enviar alerta';

    return ScaleTransition(
      scale: isActive ? _pulse : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: isIdle ? _startCountdown : null,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: deco.cardGradient,
            shape: BoxShape.circle,
            boxShadow: deco.floatingShadow,
          ),
          child: Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 72, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isIdle)
                  Text(
                    'Un toque activa la alerta',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _StatusStrip({
    required ColorScheme scheme,
    required IncidentPhase phase,
    required int countdown,
  }) {
    late final String statusLabel;
    late final Color statusColor;
    switch (phase) {
      case IncidentPhase.idle:
        statusLabel = 'Modo seguro activado';
        statusColor = scheme.primary;
        break;
      case IncidentPhase.countdown:
        statusLabel = 'Preparando envio';
        statusColor = scheme.secondary;
        break;
      case IncidentPhase.active:
        statusLabel = 'Transmitiendo a central';
        statusColor = scheme.error;
        break;
    }

    final detailLabel = phase == IncidentPhase.countdown
        ? 'Envio en ${countdown}s'
        : 'PIN requerido para cancelar';

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _miniBadge(
          icon: Icons.podcasts_outlined,
          label: statusLabel,
          color: statusColor,
        ),
        _miniBadge(
          icon: Icons.vpn_key_outlined,
          label: detailLabel,
          color: scheme.secondary,
        ),
      ],
    );
  }

  Widget _miniBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _InsightsCard({
    required ColorScheme scheme,
    required BrandDecorations deco,
    required IncidentPhase phase,
    required int countdown,
    required bool canceling,
    required Future<void> Function() onCancel,
  }) {
    late final String title;
    late final String subtitle;
    late final IconData icon;
    late final Color accent;

    switch (phase) {
      case IncidentPhase.idle:
        title = 'Listo para responder';
        subtitle = 'Tu ubicacion y dispositivos estan sincronizados.';
        icon = Icons.safety_check;
        accent = scheme.primary;
        break;
      case IncidentPhase.countdown:
        title = 'Cuenta regresiva en ${countdown}s';
        subtitle = 'Puedes cancelar con tu PIN si fue un toque accidental.';
        icon = Icons.timer_outlined;
        accent = scheme.secondary;
        break;
      case IncidentPhase.active:
        title = 'Alerta enviada';
        subtitle =
            'Equipos en campo reciben tu informacion. Cancela si es un falso positivo.';
        icon = Icons.broadcast_on_home_outlined;
        accent = scheme.error;
        break;
    }

    final highlights = <({IconData icon, String label})>[
      (icon: Icons.remember_me_outlined, label: 'PIN local'),
      (icon: Icons.near_me_outlined, label: 'GPS continuo'),
      (icon: Icons.backup_table_rounded, label: 'Historial cifrado'),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: deco.cardGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: deco.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accent.withOpacity(0.15),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: highlights
                .map(
                  (item) => _miniBadge(
                    icon: item.icon,
                    label: item.label,
                    color: scheme.primary,
                  ),
                )
                .toList(),
          ),
          if (phase == IncidentPhase.active) ...[
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onPressed: canceling ? null : () => onCancel(),
              child: canceling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Text('Cancelar alerta'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _CountdownOverlay({
    required int countdown,
    required bool cancelingCountdown,
    required Future<void> Function() onCancel,
  }) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xE6000000), Color(0xCC000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$countdown',
              style: const TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enviando alerta en...',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              onPressed: cancelingCountdown ? null : () => onCancel(),
              child: cancelingCountdown
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
