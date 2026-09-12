import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_metadata.dart';
import '../../../infrastructure/backup/app_backup_import_service.dart';
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
  final _importPathController = TextEditingController();
  var _isCreatingBackup = false;
  var _isImportingBackup = false;

  @override
  void dispose() {
    _importPathController.dispose();
    super.dispose();
  }

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
        GreenCrewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Przywracanie z kopii zapasowej',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Wczytuje plik kopii zapasowej JSON. Rekordy o tych samych ID '
                'co juz istniejace zostana nadpisane; nic innego nie zostanie usuniete.',
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _importPathController,
                      decoration: const InputDecoration(
                        labelText: 'Sciezka do pliku kopii zapasowej',
                        hintText:
                            r'np. C:\Users\...\Documents\StageCalc\backups\stagecalc_backup_...json',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Wybierz plik',
                    icon: const Icon(Icons.folder_open_outlined),
                    onPressed: _isImportingBackup ? null : _pickBackupFile,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GreenCrewButton(
                label: _isImportingBackup
                    ? 'Wczytywanie...'
                    : 'Wczytaj i zwaliduj',
                icon: Icons.file_open_outlined,
                secondary: true,
                onPressed: _isImportingBackup ? null : _startImport,
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

    try {
      final location = await _backupService().createBackupFile();
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

  Future<void> _pickBackupFile() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final path = result?.path;
      if (path == null || !mounted) {
        return;
      }
      setState(() => _importPathController.text = path);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udalo sie otworzyc wyboru pliku: $error')),
      );
    }
  }

  Future<void> _startImport() async {
    final path = _importPathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Podaj sciezke do pliku.')));
      return;
    }

    setState(() => _isImportingBackup = true);

    final importService = _importService();

    try {
      final preview = await importService.loadAndValidate(path);

      if (!mounted) {
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Zaimportowac kopie zapasowa?'),
          content: Text(
            'Plik z wersji aplikacji ${preview.appVersion}'
            '${preview.createdAt == null ? '' : ' (${preview.createdAt})'}.\n\n'
            'Znaleziono:\n'
            '${preview.projects.length} projektow\n'
            '${preview.clients.length} klientow\n'
            '${preview.locations.length} lokacji\n'
            '${preview.catalogDevices.length} pozycji katalogu\n'
            '${preview.powerPresets.length} presetow rozdzielnic\n\n'
            'Rekordy o tych samych ID co juz istniejace zostana nadpisane. '
            'Tej operacji nie mozna cofnac.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Importuj'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }

      await importService.import(preview);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zaimportowano ${preview.totalRecords} rekordow.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udalo sie zaimportowac kopii: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isImportingBackup = false);
      }
    }
  }

  AppBackupService _backupService() {
    final database = AppDatabaseProvider.instance;
    return AppBackupService(
      projectRepository: DriftProjectRepository(database),
      clientRepository: DriftClientRepository(database),
      locationRepository: DriftLocationRepository(database),
      catalogRepository: DriftCatalogRepository(database),
      powerPresetRepository: DriftPowerPresetRepository(database),
    );
  }

  AppBackupImportService _importService() {
    final database = AppDatabaseProvider.instance;
    return AppBackupImportService(
      projectRepository: DriftProjectRepository(database),
      clientRepository: DriftClientRepository(database),
      locationRepository: DriftLocationRepository(database),
      catalogRepository: DriftCatalogRepository(database),
      powerPresetRepository: DriftPowerPresetRepository(database),
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
