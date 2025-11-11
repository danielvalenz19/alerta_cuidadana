import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tokens.dart';
import 'incident_controller.dart';
import 'countdown_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(incidentControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Alerta Ciudadana')),
      body: Center(
        child: GestureDetector(
          onTapDown: (_) => HapticFeedback.heavyImpact(),
          onTap: () {
            ctl.startCountdown();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CountdownScreen()));
          },
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Tokens.primary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Tokens.primary.withOpacity(.4), blurRadius: 32)],
            ),
            child: const Center(
              child: Text('PÁNICO', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    );
  }
}

