import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tokens.dart';
import 'incident_controller.dart';
import 'pin_dialog.dart';

class CountdownScreen extends ConsumerWidget {
  const CountdownScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(incidentControllerProvider);
    final ctl = ref.read(incidentControllerProvider.notifier);

    // Vibración leve por segundo
    HapticFeedback.selectionClick();

    if (st.status == IncidentStatus.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/incident');
      });
    }

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${st.countdown}', style: const TextStyle(fontSize: 120, color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Enviando alerta en...', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Tokens.primary),
            onPressed: () async {
              final pin = await askPin(context);
              if (pin != null && pin.isNotEmpty) {
                ctl.cancelCountdown();
                if (context.mounted) Navigator.pop(context); // volver a Home
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

