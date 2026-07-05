import 'package:flutter/material.dart';

class GreenCrewButton extends StatelessWidget {
  const GreenCrewButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.secondary = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    if (secondary) {
      return OutlinedButton(onPressed: onPressed, child: child);
    }

    return FilledButton(onPressed: onPressed, child: child);
  }
}
