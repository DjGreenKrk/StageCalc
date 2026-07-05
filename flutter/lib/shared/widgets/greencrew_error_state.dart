import 'package:flutter/material.dart';

import '../../app/theme/greencrew_colors.dart';

class GreenCrewErrorState extends StatelessWidget {
  const GreenCrewErrorState({required this.message, super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: GreenCrewColors.error,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Sprobuj ponownie'),
            ),
          ],
        ],
      ),
    );
  }
}
