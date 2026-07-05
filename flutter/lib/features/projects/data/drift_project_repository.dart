import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../infrastructure/local_database/app_database.dart' as db;
import '../../../shared/models/offline_sync_status.dart';
import '../domain/entities/power_models.dart';
import '../domain/entities/project_models.dart';
import 'project_repository.dart';

class DriftProjectRepository implements ProjectRepository {
  const DriftProjectRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<List<Project>> getProjects() async {
    final projectRows =
        await (_database.select(_database.projects)
              ..where((row) => row.deletedAt.isNull())
              ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
            .get();

    final result = <Project>[];
    for (final projectRow in projectRows) {
      final groupRows =
          await (_database.select(_database.projectGroups)
                ..where(
                  (row) =>
                      row.projectId.equals(projectRow.id) &
                      row.deletedAt.isNull(),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
              .get();

      final groups = <ProjectGroup>[];
      for (final groupRow in groupRows) {
        final itemRows =
            await (_database.select(_database.projectItems)
                  ..where(
                    (row) =>
                        row.groupId.equals(groupRow.id) &
                        row.deletedAt.isNull(),
                  )
                  ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
                .get();

        groups.add(_mapGroup(groupRow, itemRows));
      }

      final distroRows =
          await (_database.select(_database.projectDistros)
                ..where(
                  (row) =>
                      row.projectId.equals(projectRow.id) &
                      row.deletedAt.isNull(),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
              .get();

      final distros = <ProjectDistro>[];
      for (final distroRow in distroRows) {
        final outletRows =
            await (_database.select(_database.projectOutlets)
                  ..where(
                    (row) =>
                        row.distroId.equals(distroRow.id) &
                        row.deletedAt.isNull(),
                  )
                  ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
                .get();

        distros.add(_mapDistro(distroRow, outletRows));
      }

      final connectionRows =
          await (_database.select(_database.powerConnections)
                ..where(
                  (row) =>
                      row.projectId.equals(projectRow.id) &
                      row.deletedAt.isNull(),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
              .get();

      final trussRows =
          await (_database.select(_database.projectTrusses)
                ..where(
                  (row) =>
                      row.projectId.equals(projectRow.id) &
                      row.deletedAt.isNull(),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
              .get();

      result.add(
        _mapProject(
          projectRow,
          groups,
          distros,
          connectionRows.map(_mapConnection).toList(),
          trussRows.map(_mapTruss).toList(),
        ),
      );
    }

    return result;
  }

  @override
  Future<void> saveProject(Project project) async {
    await _database.transaction(() async {
      await _database
          .into(_database.projects)
          .insertOnConflictUpdate(
            db.ProjectsCompanion(
              id: Value(project.id),
              name: Value(project.name),
              phaseId: Value(project.phaseId),
              clientId: Value(project.clientId),
              locationId: Value(project.locationId),
              createdAt: Value(project.createdAt),
              updatedAt: Value(project.updatedAt),
              syncState: Value(project.syncStatus.toJson()),
              revision: const Value(1),
            ),
          );

      final existingGroups = await (_database.select(
        _database.projectGroups,
      )..where((row) => row.projectId.equals(project.id))).get();
      final projectGroupIds = project.groups.map((group) => group.id).toSet();

      for (final existingGroup in existingGroups) {
        if (!projectGroupIds.contains(existingGroup.id)) {
          await (_database.update(
            _database.projectGroups,
          )..where((row) => row.id.equals(existingGroup.id))).write(
            db.ProjectGroupsCompanion(
              deletedAt: Value(project.updatedAt),
              updatedAt: Value(project.updatedAt),
            ),
          );
        }
      }

      for (final (groupIndex, group) in project.groups.indexed) {
        await _database
            .into(_database.projectGroups)
            .insertOnConflictUpdate(
              db.ProjectGroupsCompanion(
                id: Value(group.id),
                projectId: Value(project.id),
                phaseId: Value(project.phaseId),
                name: Value(group.name),
                powerProfile: Value(group.powerProfile.toJson()),
                sortOrder: Value(groupIndex),
                createdAt: Value(project.createdAt),
                updatedAt: Value(project.updatedAt),
                deletedAt: const Value(null),
              ),
            );

        final existingItems = await (_database.select(
          _database.projectItems,
        )..where((row) => row.groupId.equals(group.id))).get();
        final projectItemIds = group.items.map((item) => item.id).toSet();

        for (final existingItem in existingItems) {
          if (!projectItemIds.contains(existingItem.id)) {
            await (_database.update(
              _database.projectItems,
            )..where((row) => row.id.equals(existingItem.id))).write(
              db.ProjectItemsCompanion(
                deletedAt: Value(project.updatedAt),
                updatedAt: Value(project.updatedAt),
              ),
            );
          }
        }

        for (final (itemIndex, item) in group.items.indexed) {
          await _database
              .into(_database.projectItems)
              .insertOnConflictUpdate(
                db.ProjectItemsCompanion(
                  id: Value(item.id),
                  projectId: Value(project.id),
                  groupId: Value(group.id),
                  phaseId: Value(project.phaseId),
                  catalogDeviceId: Value(item.catalogDeviceId),
                  nameSnapshot: Value(item.nameSnapshot),
                  manufacturerSnapshot: Value(item.manufacturerSnapshot),
                  quantity: Value(item.quantity),
                  powerWSnapshot: Value(item.powerWSnapshot),
                  currentASnapshot: Value(item.currentASnapshot),
                  weightKgSnapshot: Value(item.weightKgSnapshot),
                  unit: Value(item.unit.toJson()),
                  sortOrder: Value(itemIndex),
                  createdAt: Value(project.createdAt),
                  updatedAt: Value(project.updatedAt),
                  deletedAt: const Value(null),
                ),
              );
        }
      }

      final existingDistros = await (_database.select(
        _database.projectDistros,
      )..where((row) => row.projectId.equals(project.id))).get();
      final projectDistroIds = project.distros
          .map((distro) => distro.id)
          .toSet();

      for (final existingDistro in existingDistros) {
        if (!projectDistroIds.contains(existingDistro.id)) {
          await (_database.update(
            _database.projectDistros,
          )..where((row) => row.id.equals(existingDistro.id))).write(
            db.ProjectDistrosCompanion(
              deletedAt: Value(project.updatedAt),
              updatedAt: Value(project.updatedAt),
            ),
          );
          await (_database.update(
            _database.projectOutlets,
          )..where((row) => row.distroId.equals(existingDistro.id))).write(
            db.ProjectOutletsCompanion(
              deletedAt: Value(project.updatedAt),
              updatedAt: Value(project.updatedAt),
            ),
          );
        }
      }

      for (final (distroIndex, distro) in project.distros.indexed) {
        await _database
            .into(_database.projectDistros)
            .insertOnConflictUpdate(
              db.ProjectDistrosCompanion(
                id: Value(distro.id),
                projectId: Value(project.id),
                phaseId: Value(distro.phaseId),
                name: Value(distro.name),
                sourceType: Value(distro.sourceType.toJson()),
                catalogDeviceId: Value(distro.catalogDeviceId),
                locationConnectorGroupId: Value(
                  distro.locationConnectorGroupId,
                ),
                presetId: Value(distro.presetId),
                inputConnectorTypeId: Value(distro.inputConnectorTypeId),
                isRootPowerSource: Value(distro.isRootPowerSource),
                sortOrder: Value(distroIndex),
                createdAt: Value(project.createdAt),
                updatedAt: Value(project.updatedAt),
                deletedAt: const Value(null),
              ),
            );

        final existingOutlets = await (_database.select(
          _database.projectOutlets,
        )..where((row) => row.distroId.equals(distro.id))).get();
        final projectOutletIds = distro.outlets
            .map((outlet) => outlet.id)
            .toSet();

        for (final existingOutlet in existingOutlets) {
          if (!projectOutletIds.contains(existingOutlet.id)) {
            await (_database.update(
              _database.projectOutlets,
            )..where((row) => row.id.equals(existingOutlet.id))).write(
              db.ProjectOutletsCompanion(
                deletedAt: Value(project.updatedAt),
                updatedAt: Value(project.updatedAt),
              ),
            );
          }
        }

        for (final (outletIndex, outlet) in distro.outlets.indexed) {
          await _database
              .into(_database.projectOutlets)
              .insertOnConflictUpdate(
                db.ProjectOutletsCompanion(
                  id: Value(outlet.id),
                  projectId: Value(project.id),
                  distroId: Value(distro.id),
                  phaseId: Value(distro.phaseId),
                  templateOutletId: Value(outlet.templateOutletId),
                  name: Value(outlet.name),
                  connectorTypeId: Value(outlet.connectorTypeId),
                  phase: Value(outlet.phase.toJson()),
                  maxCurrentA: Value(outlet.maxCurrentA),
                  sortOrder: Value(outletIndex),
                  createdAt: Value(project.createdAt),
                  updatedAt: Value(project.updatedAt),
                  deletedAt: const Value(null),
                ),
              );
        }
      }

      final existingConnections = await (_database.select(
        _database.powerConnections,
      )..where((row) => row.projectId.equals(project.id))).get();
      final projectConnectionIds = project.connections
          .map((connection) => connection.id)
          .toSet();

      for (final existingConnection in existingConnections) {
        if (!projectConnectionIds.contains(existingConnection.id)) {
          await (_database.update(
            _database.powerConnections,
          )..where((row) => row.id.equals(existingConnection.id))).write(
            db.PowerConnectionsCompanion(
              deletedAt: Value(project.updatedAt),
              updatedAt: Value(project.updatedAt),
            ),
          );
        }
      }

      for (final (connectionIndex, connection) in project.connections.indexed) {
        await _database
            .into(_database.powerConnections)
            .insertOnConflictUpdate(
              db.PowerConnectionsCompanion(
                id: Value(connection.id),
                projectId: Value(project.id),
                phaseId: Value(connection.phaseId),
                sourceDistroId: Value(connection.sourceDistroId),
                sourceOutletId: Value(connection.sourceOutletId),
                targetType: Value(connection.targetType.toJson()),
                targetGroupId: Value(connection.targetGroupId),
                targetDistroId: Value(connection.targetDistroId),
                selectedPhasesJson: Value(
                  jsonEncode(
                    connection.selectedPhases
                        .map((phase) => phase.toJson())
                        .toList(),
                  ),
                ),
                notes: Value(connection.notes),
                sortOrder: Value(connectionIndex),
                createdAt: Value(project.createdAt),
                updatedAt: Value(project.updatedAt),
                deletedAt: const Value(null),
              ),
            );
      }

      final existingTrusses = await (_database.select(
        _database.projectTrusses,
      )..where((row) => row.projectId.equals(project.id))).get();
      final projectTrussIds = project.trusses.map((truss) => truss.id).toSet();

      for (final existingTruss in existingTrusses) {
        if (!projectTrussIds.contains(existingTruss.id)) {
          await (_database.update(
            _database.projectTrusses,
          )..where((row) => row.id.equals(existingTruss.id))).write(
            db.ProjectTrussesCompanion(
              deletedAt: Value(project.updatedAt),
              updatedAt: Value(project.updatedAt),
            ),
          );
        }
      }

      for (final (trussIndex, truss) in project.trusses.indexed) {
        await _database
            .into(_database.projectTrusses)
            .insertOnConflictUpdate(
              db.ProjectTrussesCompanion(
                id: Value(truss.id),
                projectId: Value(project.id),
                phaseId: Value(truss.phaseId),
                name: Value(truss.name),
                trussSystemId: Value(truss.trussSystemId),
                lengthM: Value(truss.lengthM),
                maxTotalLoadKg: Value(truss.maxTotalLoadKg),
                maxDistributedLoadKgPerM: Value(truss.maxDistributedLoadKgPerM),
                manualLoadKg: Value(truss.manualLoadKg),
                assignedGroupIdsJson: Value(jsonEncode(truss.assignedGroupIds)),
                notes: Value(truss.notes),
                sortOrder: Value(trussIndex),
                createdAt: Value(project.createdAt),
                updatedAt: Value(project.updatedAt),
                deletedAt: const Value(null),
              ),
            );
      }
    });
  }

  Project _mapProject(
    db.Project row,
    List<ProjectGroup> groups,
    List<ProjectDistro> distros,
    List<PowerConnection> connections,
    List<ProjectTruss> trusses,
  ) {
    return Project(
      id: row.id,
      name: row.name,
      phaseId: row.phaseId,
      clientId: row.clientId,
      locationId: row.locationId,
      groups: groups,
      distros: distros,
      connections: connections,
      trusses: trusses,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      syncStatus: OfflineSyncStatusJson.fromJson(row.syncState),
    );
  }

  ProjectGroup _mapGroup(db.ProjectGroup row, List<db.ProjectItem> itemRows) {
    return ProjectGroup(
      id: row.id,
      name: row.name,
      powerProfile: ProjectGroupPowerProfileJson.fromJson(row.powerProfile),
      items: itemRows.map(_mapItem).toList(),
    );
  }

  ProjectItem _mapItem(db.ProjectItem row) {
    return ProjectItem(
      id: row.id,
      catalogDeviceId: row.catalogDeviceId,
      nameSnapshot: row.nameSnapshot,
      manufacturerSnapshot: row.manufacturerSnapshot,
      quantity: row.quantity,
      powerWSnapshot: row.powerWSnapshot,
      currentASnapshot: row.currentASnapshot,
      weightKgSnapshot: row.weightKgSnapshot,
      unit: ProjectItemUnitJson.fromJson(row.unit),
    );
  }

  ProjectDistro _mapDistro(
    db.ProjectDistro row,
    List<db.ProjectOutlet> outletRows,
  ) {
    return ProjectDistro(
      id: row.id,
      phaseId: row.phaseId,
      name: row.name,
      sourceType: ProjectDistroSourceTypeJson.fromJson(row.sourceType),
      catalogDeviceId: row.catalogDeviceId,
      locationConnectorGroupId: row.locationConnectorGroupId,
      presetId: row.presetId,
      inputConnectorTypeId: row.inputConnectorTypeId,
      isRootPowerSource: row.isRootPowerSource,
      outlets: outletRows.map(_mapOutlet).toList(),
    );
  }

  ProjectOutlet _mapOutlet(db.ProjectOutlet row) {
    return ProjectOutlet(
      id: row.id,
      templateOutletId: row.templateOutletId,
      name: row.name,
      connectorTypeId: row.connectorTypeId,
      phase: PowerPhaseJson.fromJson(row.phase),
      maxCurrentA: row.maxCurrentA,
    );
  }

  PowerConnection _mapConnection(db.PowerConnection row) {
    final decoded = jsonDecode(row.selectedPhasesJson);
    final selectedPhases = decoded is List
        ? decoded.whereType<String>().map(PowerPhaseJson.fromJson).toList()
        : <PowerPhase>[];

    return PowerConnection(
      id: row.id,
      phaseId: row.phaseId,
      sourceDistroId: row.sourceDistroId,
      sourceOutletId: row.sourceOutletId,
      targetType: PowerConnectionTargetTypeJson.fromJson(row.targetType),
      targetGroupId: row.targetGroupId,
      targetDistroId: row.targetDistroId,
      selectedPhases: selectedPhases,
      notes: row.notes,
    );
  }

  ProjectTruss _mapTruss(db.ProjectTrussesData row) {
    final decoded = jsonDecode(row.assignedGroupIdsJson);
    final assignedGroupIds = decoded is List
        ? decoded.whereType<String>().toList()
        : <String>[];

    return ProjectTruss(
      id: row.id,
      phaseId: row.phaseId,
      name: row.name,
      trussSystemId: row.trussSystemId,
      lengthM: row.lengthM,
      maxTotalLoadKg: row.maxTotalLoadKg,
      maxDistributedLoadKgPerM: row.maxDistributedLoadKgPerM,
      manualLoadKg: row.manualLoadKg,
      assignedGroupIds: assignedGroupIds,
      notes: row.notes,
    );
  }
}
