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

class FakeProjectRepository implements ProjectRepository {
  FakeProjectRepository([List<Project>? projects]) : projects = projects ?? [];
  final List<Project> projects;

  @override
  Future<List<Project>> getProjects() async => projects;

  @override
  Future<void> saveProject(Project project) async {
    projects
      ..removeWhere((candidate) => candidate.id == project.id)
      ..add(project);
  }
}

class FakeClientRepository implements ClientRepository {
  FakeClientRepository([List<Client>? clients]) : clients = clients ?? [];
  final List<Client> clients;

  @override
  Future<List<Client>> getClients() async => clients;

  @override
  Future<void> saveClient(Client client) async {
    clients
      ..removeWhere((candidate) => candidate.id == client.id)
      ..add(client);
  }

  @override
  Future<void> deleteClient(String id) async {
    clients.removeWhere((candidate) => candidate.id == id);
  }
}

class FakeLocationRepository implements LocationRepository {
  FakeLocationRepository([List<Location>? locations])
    : locations = locations ?? [];
  final List<Location> locations;

  @override
  Future<List<Location>> getLocations() async => locations;

  @override
  Future<void> saveLocation(Location location) async {
    locations
      ..removeWhere((candidate) => candidate.id == location.id)
      ..add(location);
  }

  @override
  Future<void> deleteLocation(String id) async {
    locations.removeWhere((candidate) => candidate.id == id);
  }
}

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository([List<CatalogDevice>? devices])
    : devices = devices ?? [];
  final List<CatalogDevice> devices;

  @override
  Future<List<CatalogDevice>> getDevices() async => devices;

  @override
  Future<void> saveDevice(CatalogDevice device) async {
    devices
      ..removeWhere((candidate) => candidate.id == device.id)
      ..add(device);
  }

  @override
  Future<void> deleteDevice(String id) async {
    devices.removeWhere((candidate) => candidate.id == id);
  }

  @override
  Future<void> ensureSeedData() async {}
}

class FakePowerPresetRepository implements PowerPresetRepository {
  FakePowerPresetRepository([List<PowerPreset>? presets])
    : presets = presets ?? [];
  final List<PowerPreset> presets;

  @override
  Future<List<PowerPreset>> getPresets() async => presets;

  @override
  Future<void> savePreset(PowerPreset preset) async {
    presets
      ..removeWhere((candidate) => candidate.id == preset.id)
      ..add(preset);
  }

  @override
  Future<void> deletePreset(String id) async {
    presets.removeWhere((candidate) => candidate.id == id);
  }

  @override
  Future<void> ensureSeedData() async {}
}
