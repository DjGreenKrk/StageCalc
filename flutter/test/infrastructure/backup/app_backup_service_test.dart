import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/clients/domain/entities/client.dart';
import 'package:stagecalc/features/locations/domain/entities/location.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/infrastructure/backup/app_backup_service.dart';

import 'fake_repositories.dart';

void main() {
  test(
    'builds a backup with a manifest and full data for every repository',
    () async {
      final date = DateTime(2026, 7, 5);
      final service = AppBackupService(
        projectRepository: FakeProjectRepository([
          Project(
            id: 'p1',
            name: 'Project 1',
            groups: const [],
            createdAt: date,
            updatedAt: date,
          ),
        ]),
        clientRepository: FakeClientRepository([
          Client(id: 'c1', name: 'Client 1', createdAt: date, updatedAt: date),
        ]),
        locationRepository: FakeLocationRepository([
          Location(
            id: 'l1',
            name: 'Location 1',
            createdAt: date,
            updatedAt: date,
          ),
        ]),
        catalogRepository: FakeCatalogRepository([
          CatalogDevice(
            id: 'd1',
            name: 'Device 1',
            quantityUnit: CatalogQuantityUnit.pcs,
            createdAt: date,
            updatedAt: date,
          ),
        ]),
        powerPresetRepository: FakePowerPresetRepository([]),
      );

      final backup = await service.buildBackup();
      final manifest = backup['manifest'] as Map<String, Object?>;
      final recordCounts = manifest['recordCounts'] as Map<String, Object?>;
      final data = backup['data'] as Map<String, Object?>;

      expect(manifest['schemaVersion'], appBackupFormatVersion);
      expect(manifest['appName'], 'StageCalc');
      expect(recordCounts['projects'], 1);
      expect(recordCounts['clients'], 1);
      expect(recordCounts['locations'], 1);
      expect(recordCounts['catalogDevices'], 1);
      expect(recordCounts['powerPresets'], 0);

      final projectsJson = data['projects'] as List<Object?>;
      expect((projectsJson.single as Map)['id'], 'p1');
      final clientsJson = data['clients'] as List<Object?>;
      expect((clientsJson.single as Map)['name'], 'Client 1');
    },
  );
}
