import 'dart:convert';

import '../../core/constants/app_metadata.dart';
import '../../features/catalog/data/catalog_repository.dart';
import '../../features/clients/data/client_repository.dart';
import '../../features/locations/data/location_repository.dart';
import '../../features/power_presets/data/power_preset_repository.dart';
import '../../features/projects/data/project_repository.dart';
import 'backup_file_writer/backup_file_writer.dart';

/// Format version of the JSON backup produced by [AppBackupService]. This is
/// independent of the local Drift schema version: it only needs to change
/// when the shape of the exported JSON itself changes, not every time a
/// column is added to the local database.
const appBackupFormatVersion = 1;

/// Builds and writes a full JSON backup of all local StageCalc data
/// (projects with their full group/distro/connection/truss trees, clients,
/// locations, catalog devices and power presets).
///
/// This is export-only for now (ADR pending for import): it does not read
/// backups back into the local database. See `docs/DATA_MODEL.md` ("Backup")
/// and ADR-012D for the format this follows.
class AppBackupService {
  const AppBackupService({
    required this.projectRepository,
    required this.clientRepository,
    required this.locationRepository,
    required this.catalogRepository,
    required this.powerPresetRepository,
  });

  final ProjectRepository projectRepository;
  final ClientRepository clientRepository;
  final LocationRepository locationRepository;
  final CatalogRepository catalogRepository;
  final PowerPresetRepository powerPresetRepository;

  Future<Map<String, Object?>> buildBackup() async {
    final projects = await projectRepository.getProjects();
    final clients = await clientRepository.getClients();
    final locations = await locationRepository.getLocations();
    final catalogDevices = await catalogRepository.getDevices();
    final powerPresets = await powerPresetRepository.getPresets();

    return {
      'manifest': {
        'schemaVersion': appBackupFormatVersion,
        'appName': AppMetadata.name,
        'appVersion': AppMetadata.version,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'workspaceId': 'local',
        'recordCounts': {
          'projects': projects.length,
          'clients': clients.length,
          'locations': locations.length,
          'catalogDevices': catalogDevices.length,
          'powerPresets': powerPresets.length,
        },
      },
      'data': {
        'projects': projects.map((project) => project.toJson()).toList(),
        'clients': clients.map((client) => client.toJson()).toList(),
        'locations': locations.map((location) => location.toJson()).toList(),
        'catalogDevices': catalogDevices
            .map((device) => device.toJson())
            .toList(),
        'powerPresets': powerPresets.map((preset) => preset.toJson()).toList(),
      },
    };
  }

  /// Builds the backup and writes it to a file, returning a message
  /// describing where it ended up (a filesystem path on native platforms).
  /// Throws [UnsupportedError] on platforms without a backup file writer
  /// (currently: web).
  Future<String> createBackupFile() async {
    final backup = await buildBackup();
    final json = const JsonEncoder.withIndent('  ').convert(backup);
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final fileName = 'stagecalc_backup_$timestamp.json';

    return writeBackupFile(fileName, json);
  }
}
