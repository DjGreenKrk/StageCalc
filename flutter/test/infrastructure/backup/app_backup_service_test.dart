import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/data/catalog_repository.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/clients/data/client_repository.dart';
import 'package:stagecalc/features/clients/domain/entities/client.dart';
import 'package:stagecalc/features/locations/data/location_repository.dart';
import 'package:stagecalc/features/locations/domain/entities/location.dart';
import 'package:stagecalc/features/power_presets/data/power_preset_repository.dart';
import 'package:stagecalc/features/power_presets/domain/entities/power_preset.dart';
import 'package:stagecalc/features/projects/data/project_repository.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/infrastructure/backup/app_backup_service.dart';

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository(this.projects);
  final List<Project> projects;

  @override
  Future<List<Project>> getProjects() async => projects;

  @override
  Future<void> saveProject(Project project) async {}
}

class _FakeClientRepository implements ClientRepository {
  _FakeClientRepository(this.clients);
  final List<Client> clients;

  @override
  Future<List<Client>> getClients() async => clients;

  @override
  Future<void> saveClient(Client client) async {}

  @override
  Future<void> deleteClient(String id) async {}
}

class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository(this.locations);
  final List<Location> locations;

  @override
  Future<List<Location>> getLocations() async => locations;

  @override
  Future<void> saveLocation(Location location) async {}

  @override
  Future<void> deleteLocation(String id) async {}
}

class _FakeCatalogRepository implements CatalogRepository {
  _FakeCatalogRepository(this.devices);
  final List<CatalogDevice> devices;

  @override
  Future<List<CatalogDevice>> getDevices() async => devices;

  @override
  Future<void> saveDevice(CatalogDevice device) async {}

  @override
  Future<void> deleteDevice(String id) async {}

  @override
  Future<void> ensureSeedData() async {}
}

class _FakePowerPresetRepository implements PowerPresetRepository {
  _FakePowerPresetRepository(this.presets);
  final List<PowerPreset> presets;

  @override
  Future<List<PowerPreset>> getPresets() async => presets;

  @override
  Future<void> savePreset(PowerPreset preset) async {}

  @override
  Future<void> deletePreset(String id) async {}

  @override
  Future<void> ensureSeedData() async {}
}

void main() {
  test(
    'builds a backup with a manifest and full data for every repository',
    () async {
      final date = DateTime(2026, 7, 5);
      final service = AppBackupService(
        projectRepository: _FakeProjectRepository([
          Project(
            id: 'p1',
            name: 'Project 1',
            groups: const [],
            createdAt: date,
            updatedAt: date,
          ),
        ]),
        clientRepository: _FakeClientRepository([
          Client(id: 'c1', name: 'Client 1', createdAt: date, updatedAt: date),
        ]),
        locationRepository: _FakeLocationRepository([
          Location(
            id: 'l1',
            name: 'Location 1',
            createdAt: date,
            updatedAt: date,
          ),
        ]),
        catalogRepository: _FakeCatalogRepository([
          CatalogDevice(
            id: 'd1',
            name: 'Device 1',
            quantityUnit: CatalogQuantityUnit.pcs,
            createdAt: date,
            updatedAt: date,
          ),
        ]),
        powerPresetRepository: _FakePowerPresetRepository([]),
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
