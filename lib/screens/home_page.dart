import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/incident_service.dart';
import '../state/incident_state.dart';

final incidentServiceProvider = Provider<IncidentService>((_) => IncidentService());
final incidentStateProvider = ChangeNotifierProvider<IncidentState>((_) => IncidentState());

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _pulse;

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
    if (id == null) return;

    try {
      final svc = ref.read(incidentServiceProvider);
      await svc.cancelIncident(id, reason: 'cancelado_desde_app');
      if (!mounted) return;
      _showSnackBar('Incidente cancelado');
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 409) {
        _showSnackBar('El incidente ya habia finalizado');
      } else {
        _showSnackBar('No se pudo cancelar: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('No se pudo cancelar: $e');
    } finally {
      ref.read(incidentStateProvider).reset();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(incidentStateProvider);
    final scheme = Theme.of(context).colorScheme;
    final isIdle = st.phase == IncidentPhase.idle;
    final isCountdown = st.phase == IncidentPhase.countdown;
    final isActive = st.phase == IncidentPhase.active;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(color: scheme.surface),
          ScaleTransition(
            scale: isActive ? _pulse : const AlwaysStoppedAnimation(1.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? scheme.error : scheme.primary,
                foregroundColor: isActive ? scheme.onError : scheme.onPrimary,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(56),
                shadowColor: scheme.primary.withValues(alpha: 0.4),
                elevation: 12,
              ),
              onPressed: isIdle ? _startCountdown : null,
              child: Icon(isActive ? Icons.sos : Icons.shield, size: 64),
            ),
          ),
          if (isCountdown)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${st.countdown}',
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
                    FilledButton.tonal(
                      onPressed: () {
                        _timer?.cancel();
                        ref.read(incidentStateProvider).reset();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Text('Cancelar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isActive)
            Positioned(
              bottom: 48,
              child: Column(
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _cancelIncident,
                    child: const Text('Cancelar alerta'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Alerta enviada - esperando respuesta',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
