import 'package:flutter/material.dart';

import '../../../core/constants/app_metadata.dart';
import '../../../shared/widgets/greencrew_card.dart';
import '../../../shared/widgets/stagecalc_mark.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        GreenCrewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StageCalcMark(size: 48),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppMetadata.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(AppMetadata.description),
            ],
          ),
        ),
        SizedBox(height: 12),
        GreenCrewCard(
          child: Column(
            children: [
              _InfoRow(label: 'Wersja', value: AppMetadata.version),
              _InfoRow(label: 'Autor', value: AppMetadata.author),
              _InfoRow(label: 'Organizacja', value: AppMetadata.organization),
              _InfoRow(label: 'Strona', value: AppMetadata.website),
              _InfoRow(label: 'Repozytorium', value: AppMetadata.repository),
              _InfoRow(label: 'Licencja', value: AppMetadata.license),
              _InfoRow(label: 'Pakiet', value: AppMetadata.packageId),
            ],
          ),
        ),
        SizedBox(height: 12),
        GreenCrewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppMetadata.ecosystem),
              SizedBox(height: 8),
              Text(AppMetadata.copyright),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
