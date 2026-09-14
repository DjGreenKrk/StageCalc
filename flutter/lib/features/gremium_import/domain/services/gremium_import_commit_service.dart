import '../../../catalog/data/catalog_repository.dart';
import '../../../catalog/domain/entities/catalog_device.dart';
import '../../../projects/data/project_repository.dart';
import '../../../projects/domain/entities/project_models.dart';
import '../entities/gremium_pack_list.dart';

enum GremiumImportAction { useCatalogDevice, createNewDevice, ownItemOnly }

/// One user-confirmed decision from the review panel (ADR-034): what to do
/// with a single, already-selected [GremiumItem].
class GremiumImportDecision {
  const GremiumImportDecision({
    required this.item,
    required this.targetGroupName,
    required this.action,
    this.existingDeviceId,
    this.linkExistingDevice = false,
    this.category,
  });

  final GremiumItem item;
  final String targetGroupName;
  final GremiumImportAction action;

  /// Required for [GremiumImportAction.useCatalogDevice].
  final String? existingDeviceId;

  /// When true alongside [GremiumImportAction.useCatalogDevice], the
  /// existing device was picked manually in the panel (not already linked)
  /// and needs `gremiumInventoryItemId` stamped on it.
  final bool linkExistingDevice;

  /// Required for [GremiumImportAction.createNewDevice] - one of the
  /// existing `CatalogDeviceCategory` values, never a Gremium-specific
  /// category invented just for this import.
  final CatalogDeviceCategory? category;
}

class GremiumImportSummary {
  const GremiumImportSummary({
    required this.projectId,
    required this.createdNewProject,
    required this.importedItemCount,
    required this.createdDeviceCount,
    required this.linkedDeviceCount,
    required this.removedItemCount,
  });

  final String projectId;
  final bool createdNewProject;
  final int importedItemCount;
  final int createdDeviceCount;
  final int linkedDeviceCount;
  final int removedItemCount;
}

/// Applies confirmed import decisions: creates/links catalog devices, then
/// creates or updates the target project as one whole-tree save (ADR-034,
/// following the same reconciliation pattern as ADR-026). Runs "headless",
/// without an open `ProjectEditorController`, the same way
/// `AppBackupImportService.import()` writes through repositories directly.
class GremiumImportCommitService {
  const GremiumImportCommitService({
    required this.catalogRepository,
    required this.projectRepository,
  });

  final CatalogRepository catalogRepository;
  final ProjectRepository projectRepository;

  Future<GremiumImportSummary> commit({
    required GremiumProjectInfo gremiumProject,
    required List<GremiumImportDecision> decisions,
  }) async {
    final now = DateTime.now();

    final catalogDevices = await catalogRepository.getDevices();
    final deviceById = {for (final d in catalogDevices) d.id: d};

    var createdDeviceCount = 0;
    var linkedDeviceCount = 0;
    final resolvedDeviceByItem = <GremiumItem, CatalogDevice?>{};

    for (final (index, decision) in decisions.indexed) {
      switch (decision.action) {
        case GremiumImportAction.ownItemOnly:
          resolvedDeviceByItem[decision.item] = null;
        case GremiumImportAction.useCatalogDevice:
          var device = deviceById[decision.existingDeviceId];
          if (device == null) {
            throw StateError(
              'Nie znaleziono urządzenia katalogowego '
              '${decision.existingDeviceId} wskazanego dla '
              '"${decision.item.name}".',
            );
          }
          if (decision.linkExistingDevice) {
            device = device.copyWith(
              gremiumInventoryItemId: decision.item.inventoryItemId,
              updatedAt: now,
            );
            await catalogRepository.saveDevice(device);
            deviceById[device.id] = device;
            linkedDeviceCount++;
          }
          resolvedDeviceByItem[decision.item] = device;
        case GremiumImportAction.createNewDevice:
          final category = decision.category ?? CatalogDeviceCategory.other;
          final technical = decision.item.technical;
          final device = CatalogDevice(
            id: 'catalog_${now.microsecondsSinceEpoch}_$index',
            name: decision.item.name,
            manufacturer: decision.item.manufacturer,
            category: category,
            powerW: category.showsElectricalFields
                ? (technical.ratedPowerW ?? 0)
                : 0,
            currentA: category.showsElectricalFields
                ? (technical.ratedCurrentA ?? 0)
                : 0,
            weightKg: technical.unitWeightKg ?? 0,
            riggingPoints: category.showsRiggingPoints
                ? technical.riggingPoints
                : null,
            quantityUnit: CatalogQuantityUnit.pcs,
            createdAt: now,
            updatedAt: now,
            gremiumInventoryItemId: decision.item.inventoryItemId,
          );
          await catalogRepository.saveDevice(device);
          deviceById[device.id] = device;
          resolvedDeviceByItem[decision.item] = device;
          createdDeviceCount++;
      }
    }

    final projects = await projectRepository.getProjects();
    Project? existingProject;
    for (final candidate in projects) {
      if (candidate.gremiumProjectId == gremiumProject.id) {
        existingProject = candidate;
        break;
      }
    }
    final createdNewProject = existingProject == null;

    final project =
        existingProject ??
        Project(
          id: 'project_${now.microsecondsSinceEpoch}',
          name: gremiumProject.name,
          groups: const [],
          createdAt: now,
          updatedAt: now,
          gremiumProjectId: gremiumProject.id,
        );

    final existingItemsByLineId =
        <String, (String groupId, ProjectItem item)>{};
    for (final group in project.groups) {
      for (final item in group.items) {
        final lineId = item.gremiumLineId;
        if (lineId != null) {
          existingItemsByLineId[lineId] = (group.id, item);
        }
      }
    }

    final workingGroupItems = <String, List<ProjectItem>>{
      for (final group in project.groups) group.id: List.of(group.items),
    };
    final groupNameToId = <String, String>{
      for (final group in project.groups) group.name: group.id,
    };
    final groupIdToName = <String, String>{
      for (final group in project.groups) group.id: group.name,
    };

    String resolveGroupId(String name, int index) {
      final existingId = groupNameToId[name];
      if (existingId != null) {
        return existingId;
      }
      final newId = 'group_${now.microsecondsSinceEpoch}_$index';
      groupNameToId[name] = newId;
      groupIdToName[newId] = name;
      workingGroupItems[newId] = [];
      return newId;
    }

    final seenLineIds = <String>{};
    var importedItemCount = 0;

    for (final (index, decision) in decisions.indexed) {
      final device = resolvedDeviceByItem[decision.item];
      final targetGroupId = resolveGroupId(decision.targetGroupName, index);
      final lineId = decision.item.lineId;
      final existing = lineId == null ? null : existingItemsByLineId[lineId];

      if (existing != null) {
        seenLineIds.add(lineId!);
        final (oldGroupId, oldItem) = existing;
        workingGroupItems[oldGroupId]!.removeWhere(
          (item) => item.id == oldItem.id,
        );
        workingGroupItems[targetGroupId]!.add(
          oldItem.copyWith(
            quantity: decision.item.quantity,
            catalogDeviceId: device?.id,
          ),
        );
      } else {
        final newItem = device != null
            ? ProjectItem(
                id: 'item_${now.microsecondsSinceEpoch}_$index',
                catalogDeviceId: device.id,
                nameSnapshot: device.name,
                manufacturerSnapshot: device.manufacturer,
                quantity: decision.item.quantity,
                powerWSnapshot: device.powerW,
                currentASnapshot: device.currentA,
                weightKgSnapshot: device.weightKg,
                riggingPointsSnapshot: device.riggingPoints,
                unit: _mapCatalogUnit(device.quantityUnit),
                gremiumLineId: lineId,
              )
            : ProjectItem(
                id: 'item_${now.microsecondsSinceEpoch}_$index',
                nameSnapshot: decision.item.displayLabel,
                quantity: decision.item.quantity,
                weightKgSnapshot: decision.item.technical.unitWeightKg ?? 0,
                gremiumLineId: lineId,
              );
        workingGroupItems[targetGroupId]!.add(newItem);
      }
      importedItemCount++;
    }

    var removedItemCount = 0;
    if (!createdNewProject) {
      for (final entry in existingItemsByLineId.entries) {
        if (!seenLineIds.contains(entry.key)) {
          final (groupId, item) = entry.value;
          workingGroupItems[groupId]!.removeWhere((it) => it.id == item.id);
          removedItemCount++;
        }
      }
    }

    final existingGroupById = {
      for (final group in project.groups) group.id: group,
    };
    final finalGroups = groupIdToName.entries.map((entry) {
      final base =
          existingGroupById[entry.key] ??
          ProjectGroup(id: entry.key, name: entry.value, items: const []);
      return base.copyWith(items: workingGroupItems[entry.key] ?? const []);
    }).toList();

    final updatedProject = project.copyWith(
      groups: finalGroups,
      updatedAt: now,
    );
    await projectRepository.saveProject(updatedProject);

    return GremiumImportSummary(
      projectId: updatedProject.id,
      createdNewProject: createdNewProject,
      importedItemCount: importedItemCount,
      createdDeviceCount: createdDeviceCount,
      linkedDeviceCount: linkedDeviceCount,
      removedItemCount: removedItemCount,
    );
  }

  ProjectItemUnit _mapCatalogUnit(CatalogQuantityUnit unit) {
    return switch (unit) {
      CatalogQuantityUnit.pcs => ProjectItemUnit.pcs,
      CatalogQuantityUnit.meters => ProjectItemUnit.meters,
    };
  }
}
