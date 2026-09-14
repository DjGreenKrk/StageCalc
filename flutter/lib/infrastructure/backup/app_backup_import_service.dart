import 'dart:convert';

import '../../features/catalog/data/catalog_repository.dart';
import '../../features/catalog/domain/entities/catalog_device.dart';
import '../../features/clients/data/client_repository.dart';
import '../../features/clients/domain/entities/client.dart';
import '../../features/locations/data/location_repository.dart';
import '../../features/locations/domain/entities/location.dart';
import '../../features/power_presets/data/power_preset_repository.dart';
import '../../features/power_presets/domain/entities/power_preset.dart';
import '../../features/projects/data/project_repository.dart';
import '../../features/projects/domain/entities/project_models.dart';
import 'app_backup_service.dart';
import '../files/local_file_reader/local_file_reader.dart';

/// Thrown when backup content fails validation. The message is meant to be
/// shown directly to the user, so it stays specific about what and where.
class BackupValidationException implements Exception {
  const BackupValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A backup that has been parsed and validated, but not written to the
/// local database yet.
class BackupImportPreview {
  const BackupImportPreview({
    required this.appVersion,
    required this.createdAt,
    required this.projects,
    required this.clients,
    required this.locations,
    required this.catalogDevices,
    required this.powerPresets,
  });

  final String appVersion;
  final String? createdAt;
  final List<Project> projects;
  final List<Client> clients;
  final List<Location> locations;
  final List<CatalogDevice> catalogDevices;
  final List<PowerPreset> powerPresets;

  int get totalRecords =>
      projects.length +
      clients.length +
      locations.length +
      catalogDevices.length +
      powerPresets.length;
}

/// Validates and imports a StageCalc JSON backup produced by
/// [AppBackupService]. See ADR-019: import is a two-step
/// validate-then-write, so a malformed or incompatible backup never leaves
/// the local database partially overwritten.
class AppBackupImportService {
  const AppBackupImportService({
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

  Future<BackupImportPreview> loadAndValidate(String path) async {
    final content = await readLocalTextFile(path);
    return validate(content);
  }

  /// Parses and validates [jsonContent] without writing anything. Throws
  /// [BackupValidationException] if the content isn't a valid, compatible
  /// StageCalc backup.
  BackupImportPreview validate(String jsonContent) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonContent);
    } on FormatException catch (error) {
      throw BackupValidationException(
        'Plik nie jest poprawnym JSON-em: $error',
      );
    }

    if (decoded is! Map) {
      throw BackupValidationException(
        'Plik nie ma oczekiwanej struktury kopii zapasowej StageCalc.',
      );
    }

    final manifest = decoded['manifest'];
    if (manifest is! Map) {
      throw const BackupValidationException(
        'Brak sekcji "manifest" w pliku kopii zapasowej.',
      );
    }

    final schemaVersion = manifest['schemaVersion'];
    if (schemaVersion is! int) {
      throw const BackupValidationException(
        'Brak lub niepoprawna wersja formatu kopii zapasowej ("schemaVersion").',
      );
    }
    if (schemaVersion > appBackupFormatVersion) {
      throw BackupValidationException(
        'Ta kopia zapasowa pochodzi z nowszej wersji formatu ($schemaVersion) '
        'niż obsługiwana przez tę wersję aplikacji ($appBackupFormatVersion). '
        'Zaktualizuj StageCalc przed importem.',
      );
    }

    final data = decoded['data'];
    if (data is! Map) {
      throw const BackupValidationException(
        'Brak sekcji "data" w pliku kopii zapasowej.',
      );
    }

    return BackupImportPreview(
      appVersion: manifest['appVersion'] as String? ?? 'nieznana',
      createdAt: manifest['createdAt'] as String?,
      projects: _parseList(data['projects'], 'projekty', Project.fromJson),
      clients: _parseList(data['clients'], 'klienci', Client.fromJson),
      locations: _parseList(data['locations'], 'lokacje', Location.fromJson),
      catalogDevices: _parseList(
        data['catalogDevices'],
        'katalog',
        CatalogDevice.fromJson,
      ),
      powerPresets: _parseList(
        data['powerPresets'],
        'presety rozdzielnic',
        PowerPreset.fromJson,
      ),
    );
  }

  List<T> _parseList<T>(
    Object? value,
    String sectionLabel,
    T Function(Map<String, Object?>) fromJson,
  ) {
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw BackupValidationException(
        'Sekcja "$sectionLabel" ma niepoprawny format.',
      );
    }

    final result = <T>[];
    for (final (index, item) in value.indexed) {
      if (item is! Map) {
        throw BackupValidationException(
          'Rekord ${index + 1} w sekcji "$sectionLabel" ma niepoprawny format.',
        );
      }
      try {
        result.add(fromJson(Map<String, Object?>.from(item)));
      } catch (error) {
        throw BackupValidationException(
          'Rekord ${index + 1} w sekcji "$sectionLabel" jest niepoprawny: $error',
        );
      }
    }
    return result;
  }

  /// Writes an already-validated [preview] to the local database. Existing
  /// records with a matching id are overwritten (the repositories upsert);
  /// nothing already in the local database is deleted.
  Future<void> import(BackupImportPreview preview) async {
    for (final project in preview.projects) {
      await projectRepository.saveProject(project);
    }
    for (final client in preview.clients) {
      await clientRepository.saveClient(client);
    }
    for (final location in preview.locations) {
      await locationRepository.saveLocation(location);
    }
    for (final device in preview.catalogDevices) {
      await catalogRepository.saveDevice(device);
    }
    for (final preset in preview.powerPresets) {
      await powerPresetRepository.savePreset(preset);
    }
  }
}
