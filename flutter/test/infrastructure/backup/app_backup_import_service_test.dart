import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/clients/domain/entities/client.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/infrastructure/backup/app_backup_import_service.dart';
import 'package:stagecalc/infrastructure/backup/app_backup_service.dart';

import 'fake_repositories.dart';

void main() {
  late FakeProjectRepository projectRepository;
  late FakeClientRepository clientRepository;
  late FakeLocationRepository locationRepository;
  late FakeCatalogRepository catalogRepository;
  late FakePowerPresetRepository powerPresetRepository;
  late AppBackupService exportService;
  late AppBackupImportService importService;

  setUp(() {
    projectRepository = FakeProjectRepository();
    clientRepository = FakeClientRepository();
    locationRepository = FakeLocationRepository();
    catalogRepository = FakeCatalogRepository();
    powerPresetRepository = FakePowerPresetRepository();
    exportService = AppBackupService(
      projectRepository: projectRepository,
      clientRepository: clientRepository,
      locationRepository: locationRepository,
      catalogRepository: catalogRepository,
      powerPresetRepository: powerPresetRepository,
    );
    importService = AppBackupImportService(
      projectRepository: projectRepository,
      clientRepository: clientRepository,
      locationRepository: locationRepository,
      catalogRepository: catalogRepository,
      powerPresetRepository: powerPresetRepository,
    );
  });

  test('round-trips a backup produced by AppBackupService', () async {
    final date = DateTime(2026, 7, 5);
    projectRepository.projects.add(
      Project(
        id: 'p1',
        name: 'Project 1',
        groups: const [],
        createdAt: date,
        updatedAt: date,
      ),
    );
    clientRepository.clients.add(
      Client(id: 'c1', name: 'Client 1', createdAt: date, updatedAt: date),
    );

    final backupJson = jsonEncode(await exportService.buildBackup());

    // Simulate a fresh install: the target repositories are empty.
    final targetProjects = FakeProjectRepository();
    final targetClients = FakeClientRepository();
    final restoreService = AppBackupImportService(
      projectRepository: targetProjects,
      clientRepository: targetClients,
      locationRepository: FakeLocationRepository(),
      catalogRepository: FakeCatalogRepository(),
      powerPresetRepository: FakePowerPresetRepository(),
    );

    final preview = restoreService.validate(backupJson);
    expect(preview.totalRecords, 2);

    await restoreService.import(preview);

    expect(targetProjects.projects.single.id, 'p1');
    expect(targetClients.clients.single.name, 'Client 1');
  });

  test(
    're-importing the same backup overwrites by id instead of duplicating',
    () async {
      final date = DateTime(2026, 7, 5);
      projectRepository.projects.add(
        Project(
          id: 'p1',
          name: 'Original name',
          groups: const [],
          createdAt: date,
          updatedAt: date,
        ),
      );
      final backupJson = jsonEncode(await exportService.buildBackup());

      // The local project changes after the backup was taken...
      projectRepository.projects.first = Project(
        id: 'p1',
        name: 'Changed locally',
        groups: const [],
        createdAt: date,
        updatedAt: date,
      );

      // ...then the old backup is restored on top of it.
      final preview = importService.validate(backupJson);
      await importService.import(preview);

      expect(projectRepository.projects.length, 1);
      expect(projectRepository.projects.single.name, 'Original name');
    },
  );

  test('rejects content that is not valid JSON', () {
    expect(
      () => importService.validate('not json'),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('rejects a backup missing the manifest section', () {
    expect(
      () => importService.validate(jsonEncode({'data': {}})),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('rejects a backup from a newer, unsupported format version', () {
    final json = jsonEncode({
      'manifest': {
        'schemaVersion': appBackupFormatVersion + 1,
        'appVersion': '9.9.9',
      },
      'data': {},
    });

    expect(
      () => importService.validate(json),
      throwsA(
        isA<BackupValidationException>().having(
          (e) => e.message,
          'message',
          contains('nowszej wersji formatu'),
        ),
      ),
    );
  });

  test('rejects a malformed record inside a data section', () {
    final json = jsonEncode({
      'manifest': {
        'schemaVersion': appBackupFormatVersion,
        'appVersion': '1.0.0',
      },
      'data': {
        'clients': [
          {'id': 'c1'}, // missing required fields like "name"
        ],
      },
    });

    expect(
      () => importService.validate(json),
      throwsA(
        isA<BackupValidationException>().having(
          (e) => e.message,
          'message',
          contains('klienci'),
        ),
      ),
    );
  });
}
