import 'package:flutter/material.dart';

import '../../../core/constants/app_metadata.dart';
import '../../../infrastructure/backup/app_backup_service.dart';
import '../../../infrastructure/local_database/app_database_provider.dart';
import '../../../shared/widgets/greencrew_button.dart';
import '../../../shared/widgets/greencrew_card.dart';
import '../../../shared/widgets/stagecalc_mark.dart';
import '../../catalog/data/drift_catalog_repository.dart';
import '../../clients/data/drift_client_repository.dart';
import '../../locations/data/drift_location_repository.dart';
import '../../power_presets/data/drift_power_preset_repository.dart';
import '../../projects/data/drift_project_repository.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  var _isCreatingBackup = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const GreenCrewCard(
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
        const SizedBox(height: 12),
        const GreenCrewCard(
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
        const SizedBox(height: 12),
        GreenCrewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kopia zapasowa',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Eksportuje wszystkie lokalne dane (projekty, katalog, '
                'klientow, lokacje i presety rozdzielnic) do jednego pliku JSON.',
              ),
              const SizedBox(height: 12),
              GreenCrewButton(
                label: _isCreatingBackup
                    ? 'Tworzenie kopii...'
                    : 'Utworz kopie zapasowa (JSON)',
                icon: Icons.save_alt,
                onPressed: _isCreatingBackup ? null : _createBackup,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const GreenCrewCard(
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

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);

    final database = AppDatabaseProvider.instance;
    final service = AppBackupService(
      projectRepository: DriftProjectRepository(database),
      clientRepository: DriftClientRepository(database),
      locationRepository: DriftLocationRepository(database),
      catalogRepository: DriftCatalogRepository(database),
      powerPresetRepository: DriftPowerPresetRepository(database),
    );

    try {
      final location = await service.createBackupFile();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kopia zapasowa utworzona'),
          content: SelectableText(location),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udalo sie utworzyc kopii: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingBackup = false);
      }
    }
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
