import 'package:flutter/material.dart';

import '../../app/theme/greencrew_colors.dart';

class GreenCrewOfflineBanner extends StatelessWidget {
  const GreenCrewOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: GreenCrewColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: GreenCrewColors.border)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 16, color: GreenCrewColors.info),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tryb offline. Dane sa zapisywane lokalnie.',
              style: TextStyle(
                fontSize: 12,
                color: GreenCrewColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
