import 'package:flutter/material.dart';

import '../../app/theme/greencrew_colors.dart';
import '../../infrastructure/update/update_check_service.dart';

class GreenCrewUpdateBanner extends StatelessWidget {
  const GreenCrewUpdateBanner({
    required this.update,
    required this.onDownload,
    required this.onDismiss,
    super.key,
  });

  final AvailableUpdate update;
  final VoidCallback onDownload;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: GreenCrewColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: GreenCrewColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.system_update_alt,
            size: 16,
            color: GreenCrewColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dostępna nowa wersja: ${update.version}',
              style: const TextStyle(
                fontSize: 12,
                color: GreenCrewColors.textSecondary,
              ),
            ),
          ),
          TextButton(onPressed: onDownload, child: const Text('Pobierz')),
          IconButton(
            tooltip: 'Zamknij',
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}
