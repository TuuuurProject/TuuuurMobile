import 'package:flutter/material.dart';

Future<void> runWithConfirmIfNeeded(
  BuildContext context, {
  required bool confirm,
  required String message,
  required VoidCallback action,
}) async {
  if (!confirm) {
    action();
    return;
  }

  final shouldProceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmation'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Oui'),
        ),
      ],
    ),
  );

  if (shouldProceed == true) {
    action();
  }
}
