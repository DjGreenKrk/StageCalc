import 'package:flutter/foundation.dart';

import '../../../infrastructure/local_database/app_database_provider.dart';
import '../../catalog/data/drift_catalog_repository.dart';
import '../../catalog/domain/entities/catalog_device.dart';
import '../../clients/data/drift_client_repository.dart';
import '../../clients/domain/entities/client.dart';
import '../../locations/data/drift_location_repository.dart';
import '../../locations/domain/entities/location.dart';
import '../../power_presets/data/drift_power_preset_repository.dart';
import '../../power_presets/domain/entities/power_preset.dart';
import '../data/project_repository.dart';
import '../domain/entities/power_models.dart';
import '../domain/entities/project_models.dart';
import '../domain/services/patch_validation_service.dart';
import '../domain/services/power_calculation_service.dart';
import '../domain/services/project_totals_service.dart';
import '../domain/services/truss_load_service.dart';

enum ProjectEditorView { equipment, patcher, trusses }

/// A source outlet feeding a new [PowerConnection].
class ProjectConnectionSource {
  const ProjectConnectionSource({
    required this.sourceDistroId,
    required this.sourceOutletId,
  });

  final String sourceDistroId;
  final String sourceOutletId;
}

/// Holds the [Project] being edited, its reference data (clients, locations,
/// power presets) and every mutation the project editor screen can trigger.
///
/// Kept free of [BuildContext] and dialog widgets so project mutations are
/// testable on their own and cannot silently diverge between similar
/// operations (see ADR-015 / the group-delete "orphaned connections" bug this
/// split was meant to make impossible to repeat). Dialogs still live in the
/// screen, which reads their result and calls the matching method here.
class ProjectEditorController extends ChangeNotifier {
  ProjectEditorController({
    required Project project,
    required this.repository,
    // ignore: prefer_initializing_formals
  }) : _project = project;

  final ProjectRepository repository;

  static const _totalsService = ProjectTotalsService();
  static const _powerService = PowerCalculationService();
  static const _validationService = PatchValidationService();
  static const _trussLoadService = TrussLoadService();

  Project _project;
  Project get project => _project;

  List<Client> _clients = const [];
  List<Client> get clients => _clients;

  List<Location> _locations = const [];
  List<Location> get locations => _locations;

  List<PowerPreset> _powerPresets = const [];
  List<PowerPreset> get powerPresets => _powerPresets;

  bool hasChanges = false;

  ProjectEditorView view = ProjectEditorView.equipment;

  void setView(ProjectEditorView value) {
    if (view == value) {
      return;
    }
    view = value;
    notifyListeners();
  }

  ProjectTotals get totals => _totalsService.calculate(_project);

  ProjectPowerLoad get powerLoads =>
      _powerService.calculateProjectLoads(_project);

  PatchValidationResult get patchValidation =>
      _validationService.validate(_project, powerLoads);

  TrussLoad trussLoad(ProjectTruss truss) =>
      _trussLoadService.calculateLoad(truss, _project);

  bool get canCreateConnection {
    return (_project.groups.isNotEmpty || _project.distros.length > 1) &&
        _project.distros.any((distro) => distro.outlets.isNotEmpty);
  }

  Future<void> loadReferences() async {
    final database = AppDatabaseProvider.instance;
    final clients = await DriftClientRepository(database).getClients();
    final locations = await DriftLocationRepository(database).getLocations();
    final powerPresetRepository = DriftPowerPresetRepository(database);
    await powerPresetRepository.ensureSeedData();
    final powerPresets = await powerPresetRepository.getPresets();

    _clients = clients;
    _locations = locations;
    _powerPresets = powerPresets;
    notifyListeners();
  }

  Future<List<CatalogDevice>> loadCatalogDevices() async {
    final repository = DriftCatalogRepository(AppDatabaseProvider.instance);
    await repository.ensureSeedData();
    return repository.getDevices();
  }

  Future<void> updateMetadata({
    required String name,
    String? clientId,
    String? locationId,
  }) {
    return _persist(
      _project.copyWith(
        name: name,
        clientId: clientId,
        locationId: locationId,
        clearClientId: clientId == null,
        clearLocationId: locationId == null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> addDistro({
    required String name,
    required ProjectDistroSourceType sourceType,
    required String? inputConnectorTypeId,
    required List<PowerOutletTemplate> outletTemplates,
    String? presetId,
    String? locationConnectorGroupId,
  }) {
    final now = DateTime.now();
    final outlets = <ProjectOutlet>[
      for (final (index, outletTemplate) in outletTemplates.indexed)
        ProjectOutlet(
          id: 'outlet_${now.microsecondsSinceEpoch}_$index',
          templateOutletId: outletTemplate.id,
          name: outletTemplate.name,
          connectorTypeId: outletTemplate.connectorTypeId,
          phase: outletTemplate.phase,
          maxCurrentA:
              ConnectorTypes.findById(
                outletTemplate.connectorTypeId,
              )?.maxCurrentA ??
              0,
        ),
    ];

    final distro = ProjectDistro(
      id: 'distro_${now.microsecondsSinceEpoch}',
      phaseId: _project.phaseId,
      name: name,
      sourceType: sourceType,
      presetId: presetId,
      locationConnectorGroupId: locationConnectorGroupId,
      inputConnectorTypeId: inputConnectorTypeId,
      isRootPowerSource: _project.distros.isEmpty,
      outlets: outlets,
    );

    return _persist(
      _project.copyWith(distros: [..._project.distros, distro], updatedAt: now),
    );
  }

  Future<void> editDistro(
    ProjectDistro distro, {
    required String name,
    required String? inputConnectorTypeId,
    required List<ProjectOutlet> outlets,
    double? manualInputMaxCurrentA,
  }) {
    final now = DateTime.now();
    final distros = _project.distros.map((candidate) {
      if (candidate.id != distro.id) {
        return candidate;
      }

      return ProjectDistro(
        id: candidate.id,
        phaseId: candidate.phaseId,
        name: name,
        sourceType: ProjectDistroSourceType.manual,
        catalogDeviceId: candidate.catalogDeviceId,
        locationConnectorGroupId: candidate.locationConnectorGroupId,
        presetId: candidate.presetId,
        inputConnectorTypeId: inputConnectorTypeId,
        isRootPowerSource: candidate.isRootPowerSource,
        manualInputMaxCurrentA: manualInputMaxCurrentA,
        outlets: outlets,
      );
    }).toList();
    final outletIds = outlets.map((outlet) => outlet.id).toSet();

    return _persist(
      _project.copyWith(
        distros: distros,
        connections: _project.connections
            .where(
              (connection) =>
                  connection.sourceDistroId != distro.id ||
                  outletIds.contains(connection.sourceOutletId),
            )
            .toList(),
        updatedAt: now,
      ),
    );
  }

  /// Removes [distro] and every [PowerConnection] that used it as a source
  /// or as a cascade target, so nothing is left pointing at a distro that no
  /// longer exists.
  Future<void> deleteDistro(ProjectDistro distro) {
    final now = DateTime.now();
    return _persist(
      _project.copyWith(
        distros: _project.distros
            .where((candidate) => candidate.id != distro.id)
            .toList(),
        connections: _project.connections
            .where(
              (connection) =>
                  connection.sourceDistroId != distro.id &&
                  connection.targetDistroId != distro.id,
            )
            .toList(),
        updatedAt: now,
      ),
    );
  }

  Future<void> addConnections({
    required PowerConnectionTargetType targetType,
    String? targetGroupId,
    String? targetDistroId,
    required List<ProjectConnectionSource> sources,
    List<PowerPhase> selectedPhases = const [],
  }) {
    final now = DateTime.now();
    final connections = [
      for (final (index, source) in sources.indexed)
        PowerConnection(
          id: 'connection_${now.microsecondsSinceEpoch}_$index',
          phaseId: _project.phaseId,
          sourceDistroId: source.sourceDistroId,
          sourceOutletId: source.sourceOutletId,
          targetType: targetType,
          targetGroupId: targetGroupId,
          targetDistroId: targetDistroId,
          selectedPhases: selectedPhases,
        ),
    ];

    return _persist(
      _project.copyWith(
        distros: targetType == PowerConnectionTargetType.distro
            ? _project.distros
                  .map(
                    (distro) => distro.id == targetDistroId
                        ? _asNonRootDistro(distro)
                        : distro,
                  )
                  .toList()
            : _project.distros,
        connections: [..._project.connections, ...connections],
        updatedAt: now,
      ),
    );
  }

  Future<void> deleteConnection(PowerConnection connection) {
    final now = DateTime.now();
    return _persist(
      _project.copyWith(
        connections: _project.connections
            .where((candidate) => candidate.id != connection.id)
            .toList(),
        updatedAt: now,
      ),
    );
  }

  Future<void> addGroup(String name) {
    final now = DateTime.now();
    final group = ProjectGroup(
      id: 'group_${now.microsecondsSinceEpoch}',
      name: name,
      items: const [],
    );

    return _persist(
      _project.copyWith(groups: [..._project.groups, group], updatedAt: now),
    );
  }

  Future<void> editGroup(ProjectGroup group, String name) {
    final now = DateTime.now();
    final groups = _project.groups.map((candidate) {
      if (candidate.id != group.id) {
        return candidate;
      }
      return candidate.copyWith(name: name);
    }).toList();

    return _persist(_project.copyWith(groups: groups, updatedAt: now));
  }

  /// Removes [group] and every [PowerConnection] targeting it. Without the
  /// connection cleanup a deleted group leaves a dangling connection behind
  /// (the exact "orphaned connections" bug from legacy StageCalc, see
  /// `docs/legacy_stagecalc_debug_context.md` and ADR-015) that permanently
  /// blocks the outlet it used to occupy.
  /// Removes [group], every [PowerConnection] targeting it, and its ID from
  /// every truss's `assignedGroupIds` - the same "don't leave a dangling
  /// reference behind" rule as [deleteDistro], applied here too so this
  /// group-deletion path doesn't grow a second copy of the orphaned-
  /// reference bug ADR-015 already fixed once for connections.
  Future<void> deleteGroup(ProjectGroup group) {
    final now = DateTime.now();
    final groups = _project.groups
        .where((candidate) => candidate.id != group.id)
        .toList();
    final trusses = _project.trusses
        .map(
          (truss) => truss.assignedGroupIds.contains(group.id)
              ? _withoutAssignedGroup(truss, group.id)
              : truss,
        )
        .toList();

    return _persist(
      _project.copyWith(
        groups: groups,
        connections: _project.connections
            .where((connection) => connection.targetGroupId != group.id)
            .toList(),
        trusses: trusses,
        updatedAt: now,
      ),
    );
  }

  ProjectTruss _withoutAssignedGroup(ProjectTruss truss, String groupId) {
    return ProjectTruss(
      id: truss.id,
      phaseId: truss.phaseId,
      name: truss.name,
      trussSystemId: truss.trussSystemId,
      lengthM: truss.lengthM,
      maxTotalLoadKg: truss.maxTotalLoadKg,
      maxDistributedLoadKgPerM: truss.maxDistributedLoadKgPerM,
      manualLoadKg: truss.manualLoadKg,
      assignedGroupIds: truss.assignedGroupIds
          .where((id) => id != groupId)
          .toList(),
      notes: truss.notes,
    );
  }

  Future<void> addItem(
    ProjectGroup group, {
    required String name,
    required double quantity,
    required double powerW,
    required double currentA,
    required double weightKg,
  }) {
    final now = DateTime.now();
    final item = ProjectItem(
      id: 'item_${now.microsecondsSinceEpoch}',
      nameSnapshot: name,
      quantity: quantity,
      powerWSnapshot: powerW,
      currentASnapshot: currentA,
      weightKgSnapshot: weightKg,
    );

    return _addItemToGroup(group, item, now);
  }

  Future<void> addCatalogItem(
    ProjectGroup group,
    CatalogDevice device,
    double quantity,
  ) {
    final now = DateTime.now();
    final item = ProjectItem(
      id: 'item_${now.microsecondsSinceEpoch}',
      catalogDeviceId: device.id,
      nameSnapshot: device.name,
      manufacturerSnapshot: device.manufacturer,
      quantity: quantity,
      powerWSnapshot: device.powerW,
      currentASnapshot: device.currentA,
      weightKgSnapshot: device.weightKg,
      unit: _mapCatalogUnit(device.quantityUnit),
    );

    return _addItemToGroup(group, item, now);
  }

  Future<void> _addItemToGroup(
    ProjectGroup group,
    ProjectItem item,
    DateTime now,
  ) {
    final groups = _project.groups.map((candidate) {
      if (candidate.id != group.id) {
        return candidate;
      }
      return candidate.copyWith(items: [...candidate.items, item]);
    }).toList();

    return _persist(_project.copyWith(groups: groups, updatedAt: now));
  }

  Future<void> editItem(
    ProjectGroup group,
    ProjectItem item, {
    required String name,
    required double quantity,
    required double powerW,
    required double currentA,
    required double weightKg,
  }) {
    final now = DateTime.now();
    final updatedItem = item.copyWith(
      nameSnapshot: name,
      quantity: quantity,
      powerWSnapshot: powerW,
      currentASnapshot: currentA,
      weightKgSnapshot: weightKg,
    );

    final groups = _project.groups.map((candidate) {
      if (candidate.id != group.id) {
        return candidate;
      }

      final items = candidate.items.map((candidateItem) {
        if (candidateItem.id != item.id) {
          return candidateItem;
        }
        return updatedItem;
      }).toList();

      return candidate.copyWith(items: items);
    }).toList();

    return _persist(_project.copyWith(groups: groups, updatedAt: now));
  }

  Future<void> deleteItem(ProjectGroup group, ProjectItem item) {
    final now = DateTime.now();
    final groups = _project.groups.map((candidate) {
      if (candidate.id != group.id) {
        return candidate;
      }

      return candidate.copyWith(
        items: candidate.items
            .where((candidateItem) => candidateItem.id != item.id)
            .toList(),
      );
    }).toList();

    return _persist(_project.copyWith(groups: groups, updatedAt: now));
  }

  Future<void> addTruss({
    required String name,
    required double lengthM,
    double manualLoadKg = 0,
    double? maxTotalLoadKg,
    double? maxDistributedLoadKgPerM,
    List<String> assignedGroupIds = const [],
    String? notes,
  }) {
    final now = DateTime.now();
    final truss = ProjectTruss(
      id: 'truss_${now.microsecondsSinceEpoch}',
      phaseId: _project.phaseId,
      name: name,
      lengthM: lengthM,
      manualLoadKg: manualLoadKg,
      maxTotalLoadKg: maxTotalLoadKg,
      maxDistributedLoadKgPerM: maxDistributedLoadKgPerM,
      assignedGroupIds: assignedGroupIds,
      notes: notes,
    );

    return _persist(
      _project.copyWith(trusses: [..._project.trusses, truss], updatedAt: now),
    );
  }

  Future<void> editTruss(
    ProjectTruss truss, {
    required String name,
    required double lengthM,
    required double manualLoadKg,
    double? maxTotalLoadKg,
    double? maxDistributedLoadKgPerM,
    required List<String> assignedGroupIds,
    String? notes,
  }) {
    final now = DateTime.now();
    final trusses = _project.trusses.map((candidate) {
      if (candidate.id != truss.id) {
        return candidate;
      }

      return ProjectTruss(
        id: candidate.id,
        phaseId: candidate.phaseId,
        name: name,
        trussSystemId: candidate.trussSystemId,
        lengthM: lengthM,
        manualLoadKg: manualLoadKg,
        maxTotalLoadKg: maxTotalLoadKg,
        maxDistributedLoadKgPerM: maxDistributedLoadKgPerM,
        assignedGroupIds: assignedGroupIds,
        notes: notes,
      );
    }).toList();

    return _persist(_project.copyWith(trusses: trusses, updatedAt: now));
  }

  Future<void> deleteTruss(ProjectTruss truss) {
    final now = DateTime.now();
    final trusses = _project.trusses
        .where((candidate) => candidate.id != truss.id)
        .toList();

    return _persist(_project.copyWith(trusses: trusses, updatedAt: now));
  }

  Future<void> _persist(Project project) async {
    await repository.saveProject(project);
    _project = project;
    hasChanges = true;
    notifyListeners();
  }

  ProjectDistro _asNonRootDistro(ProjectDistro distro) {
    return ProjectDistro(
      id: distro.id,
      phaseId: distro.phaseId,
      name: distro.name,
      sourceType: distro.sourceType,
      catalogDeviceId: distro.catalogDeviceId,
      locationConnectorGroupId: distro.locationConnectorGroupId,
      presetId: distro.presetId,
      inputConnectorTypeId: distro.inputConnectorTypeId,
      isRootPowerSource: false,
      manualInputMaxCurrentA: distro.manualInputMaxCurrentA,
      outlets: distro.outlets,
    );
  }

  ProjectItemUnit _mapCatalogUnit(CatalogQuantityUnit unit) {
    return switch (unit) {
      CatalogQuantityUnit.pcs => ProjectItemUnit.pcs,
      CatalogQuantityUnit.meters => ProjectItemUnit.meters,
    };
  }
}
