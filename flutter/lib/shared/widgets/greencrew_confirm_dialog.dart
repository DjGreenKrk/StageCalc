import 'package:flutter/material.dart';

class GreenCrewConfirmDialog extends StatelessWidget {
  const GreenCrewConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
