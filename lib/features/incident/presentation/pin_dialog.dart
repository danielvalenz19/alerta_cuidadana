import 'package:flutter/material.dart';

Future<String?> askPin(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Cancelar con PIN'),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'PIN'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Confirmar')),
      ],
    ),
  );
}

