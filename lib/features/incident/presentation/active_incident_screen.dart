import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tokens.dart';
import 'incident_controller.dart';
import 'pin_dialog.dart';

class ActiveIncidentScreen extends ConsumerWidget {
  const ActiveIncidentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(incidentControllerProvider);
    final ctl = ref.read(incidentControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Incidente activo')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.warning_rounded, size: 96, color: Tokens.primary),
          const SizedBox(height: 12),
          Text('Caso #${st.id ?? '-'}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('Esperando confirmación…'),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tokens.primary),
            onPressed: () async {
              final pin = await askPin(context);
              if (pin == null || pin.isEmpty) return;
              await ctl.cancelActive(pin);
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
              }
            },
            child: const Text('Cancelar alerta', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}

