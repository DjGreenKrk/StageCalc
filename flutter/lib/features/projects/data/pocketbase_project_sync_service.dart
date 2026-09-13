import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../infrastructure/local_database/app_database.dart' as db;
import '../../../infrastructure/sync/pocketbase_child_sync.dart';
import '../../../infrastructure/sync/pocketbase_datetime.dart';
import '../../../infrastructure/sync/sync_direction.dart';
import '../../../infrastructure/sync/sync_summary.dart';

/// Two-way sync of `projects` and its full nested tree (groups, items, hook
/// assignments, distros, outlets, connections, trusses) - ADR-026. Same
/// whole-tree reconciliation as the other sync services: whichever side's
/// project `updated_at` is newer wins and its entire tree is upserted onto
/// the other side (see `pocketbase_child_sync.dart` for why nothing is ever
/// hard-deleted remotely or locally).
///
/// Replaces the one-way, no-conflict-handling `pushProject` from ADR-017.
class PocketBaseProjectSyncService {
  const PocketBaseProjectSyncService(this._pb, this._database);

  final PocketBase _pb;
  final db.AppDatabase _database;

  static const _collection = 'projects';
  static const _groupsCollection = 'project_groups';
  static const _itemsCollection = 'project_items';
  static const _hookAssignmentsCollection = 'project_group_hook_assignments';
  static const _distrosCollection = 'project_distros';
  static const _outletsCollection = 'project_outlets';
  static const _connectionsCollection = 'power_connections';
  static const _trussesCollection = 'project_trusses';

  Future<SyncSummary> sync() async {
    final localRows = await _database.select(_database.projects).get();
    final remoteRecords = await _pb.collection(_collection).getFullList();

    final localById = {for (final row in localRows) row.id: row};
    final remoteByLocalId = {
      for (final record in remoteRecords)
        record.getStringValue('local_id'): record,
    };

    var pushed = 0;
    var pulled = 0;
    var unchanged = 0;
    final errors = <String>[];

    for (final id in {...localById.keys, ...remoteByLocalId.keys}) {
      final local = localById[id];
      final remote = remoteByLocalId[id];

      try {
        final direction = decideSyncDirection(
          localUpdatedAt: local?.updatedAt,
          remoteUpdatedAt: remote == null
              ? null
              : fromRemoteIso(remote.getStringValue('updated_at')),
        );

        switch (direction) {
          case SyncDirection.push:
            await _push(local!, remote);
            pushed++;
          case SyncDirection.pull:
            await _pull(id, remote!);
            pulled++;
          case SyncDirection.none:
            unchanged++;
        }
      } catch (error) {
        errors.add('project $id: $error');
      }
    }

    return SyncSummary(
      pushed: pushed,
      pulled: pulled,
      unchanged: unchanged,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------
  // Push (local wins)
  // ---------------------------------------------------------------------

  Future<void> _push(db.Project local, RecordModel? remote) async {
    final clientRemoteId = local.clientId == null
        ? null
        : await _findRemoteId('clients', local.clientId!);
    final locationRemoteId = local.locationId == null
        ? null
        : await _findRemoteId('locations', local.locationId!);

    final body = <String, Object?>{
      'local_id': local.id,
      'workspace_id': local.workspaceId,
      'name': local.name,
      'phase_id': local.phaseId,
      'client': clientRemoteId,
      'location': locationRemoteId,
      'created_at': toRemoteIso(local.createdAt),
      'updated_at': toRemoteIso(local.updatedAt),
      'deleted_at': local.deletedAt == null
          ? null
          : toRemoteIso(local.deletedAt!),
      'deleted': local.deletedAt != null,
    };

    final record = remote == null
        ? await _pb.collection(_collection).create(body: body)
        : await _pb.collection(_collection).update(remote.id, body: body);

    await (_database.update(
      _database.projects,
    )..where((row) => row.id.equals(local.id))).write(
      db.ProjectsCompanion(
        remoteId: Value(record.id),
        syncState: const Value('synced'),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );

    final groupRemoteIds = await _pushGroups(local.id, record.id);
    final (distroRemoteIds, outletRemoteIds) = await _pushDistros(
      local.id,
      record.id,
    );
    await _pushConnections(
      local.id,
      record.id,
      groupRemoteIds: groupRemoteIds,
      distroRemoteIds: distroRemoteIds,
      outletRemoteIds: outletRemoteIds,
    );
    await _pushTrusses(local.id, record.id);
  }

  Future<Map<String, String>> _pushGroups(
    String localProjectId,
    String remoteProjectId,
  ) async {
    final groups = await (_database.select(
      _database.projectGroups,
    )..where((row) => row.projectId.equals(localProjectId))).get();
    final existingRemote = await _pb
        .collection(_groupsCollection)
        .getFullList(
          filter: _pb.filter('project = {:id}', {'id': remoteProjectId}),
        );
    final existingByLocalId = {
      for (final record in existingRemote)
        record.getStringValue('local_id'): record,
    };

    final groupRemoteIds = <String, String>{};
    for (final group in groups) {
      final body = <String, Object?>{
        'local_id': group.id,
        'project': remoteProjectId,
        'name': group.name,
        'power_profile': group.powerProfile,
        'created_at': toRemoteIso(group.createdAt),
        'updated_at': toRemoteIso(group.updatedAt),
        'deleted_at': group.deletedAt == null
            ? null
            : toRemoteIso(group.deletedAt!),
        'deleted': group.deletedAt != null,
      };
      final existing = existingByLocalId[group.id];
      final record = existing == null
          ? await _pb.collection(_groupsCollection).create(body: body)
          : await _pb
                .collection(_groupsCollection)
                .update(existing.id, body: body);
      groupRemoteIds[group.id] = record.id;

      final items = await (_database.select(
        _database.projectItems,
      )..where((row) => row.groupId.equals(group.id))).get();
      await upsertRemoteChildren(
        _pb,
        collection: _itemsCollection,
        parentField: 'group',
        remoteParentId: record.id,
        bodies: [
          for (final item in items)
            {
              'local_id': item.id,
              'project': remoteProjectId,
              'group': record.id,
              'phase_id': item.phaseId,
              'name_snapshot': item.nameSnapshot,
              'manufacturer_snapshot': item.manufacturerSnapshot,
              'quantity': item.quantity,
              'power_w_snapshot': item.powerWSnapshot,
              'current_a_snapshot': item.currentASnapshot,
              'weight_kg_snapshot': item.weightKgSnapshot,
              'rigging_points_snapshot': item.riggingPointsSnapshot,
              'unit': item.unit,
              'created_at': toRemoteIso(item.createdAt),
              'updated_at': toRemoteIso(item.updatedAt),
              'deleted_at': item.deletedAt == null
                  ? null
                  : toRemoteIso(item.deletedAt!),
              'deleted': item.deletedAt != null,
            },
        ],
      );

      final hookAssignments = await (_database.select(
        _database.projectGroupHookAssignments,
      )..where((row) => row.groupId.equals(group.id))).get();
      await upsertRemoteChildren(
        _pb,
        collection: _hookAssignmentsCollection,
        parentField: 'group',
        remoteParentId: record.id,
        bodies: [
          for (final hook in hookAssignments)
            {
              'local_id': hook.id,
              'project': remoteProjectId,
              'group': record.id,
              'hook_catalog_device_id': hook.hookCatalogDeviceId,
              'hook_name_snapshot': hook.hookNameSnapshot,
              'hook_weight_kg_snapshot': hook.hookWeightKgSnapshot,
              'quantity': hook.quantity,
              'created_at': toRemoteIso(hook.createdAt),
              'updated_at': toRemoteIso(hook.updatedAt),
              'deleted_at': hook.deletedAt == null
                  ? null
                  : toRemoteIso(hook.deletedAt!),
              'deleted': hook.deletedAt != null,
            },
        ],
      );
    }

    return groupRemoteIds;
  }

  Future<(Map<String, String>, Map<String, String>)> _pushDistros(
    String localProjectId,
    String remoteProjectId,
  ) async {
    final distros = await (_database.select(
      _database.projectDistros,
    )..where((row) => row.projectId.equals(localProjectId))).get();
    final existingRemote = await _pb
        .collection(_distrosCollection)
        .getFullList(
          filter: _pb.filter('project = {:id}', {'id': remoteProjectId}),
        );
    final existingByLocalId = {
      for (final record in existingRemote)
        record.getStringValue('local_id'): record,
    };

    final distroRemoteIds = <String, String>{};
    final outletRemoteIds = <String, String>{};

    for (final distro in distros) {
      final body = <String, Object?>{
        'local_id': distro.id,
        'project': remoteProjectId,
        'phase_id': distro.phaseId,
        'name': distro.name,
        'source_type': distro.sourceType,
        'location_connector_group_id': distro.locationConnectorGroupId,
        'input_connector_type_id': distro.inputConnectorTypeId,
        'is_root_power_source': distro.isRootPowerSource,
        'manual_input_max_current_a': distro.manualInputMaxCurrentA,
        'created_at': toRemoteIso(distro.createdAt),
        'updated_at': toRemoteIso(distro.updatedAt),
        'deleted_at': distro.deletedAt == null
            ? null
            : toRemoteIso(distro.deletedAt!),
        'deleted': distro.deletedAt != null,
      };
      final existing = existingByLocalId[distro.id];
      final record = existing == null
          ? await _pb.collection(_distrosCollection).create(body: body)
          : await _pb
                .collection(_distrosCollection)
                .update(existing.id, body: body);
      distroRemoteIds[distro.id] = record.id;

      final outlets = await (_database.select(
        _database.projectOutlets,
      )..where((row) => row.distroId.equals(distro.id))).get();
      final existingRemoteOutlets = await _pb
          .collection(_outletsCollection)
          .getFullList(filter: _pb.filter('distro = {:id}', {'id': record.id}));
      final existingOutletsByLocalId = {
        for (final outletRecord in existingRemoteOutlets)
          outletRecord.getStringValue('local_id'): outletRecord,
      };

      for (final outlet in outlets) {
        final outletBody = <String, Object?>{
          'local_id': outlet.id,
          'project': remoteProjectId,
          'distro': record.id,
          'phase_id': outlet.phaseId,
          'template_outlet_id': outlet.templateOutletId,
          'name': outlet.name,
          'connector_type_id': outlet.connectorTypeId,
          'phase': outlet.phase,
          'max_current_a': outlet.maxCurrentA,
          'created_at': toRemoteIso(outlet.createdAt),
          'updated_at': toRemoteIso(outlet.updatedAt),
          'deleted_at': outlet.deletedAt == null
              ? null
              : toRemoteIso(outlet.deletedAt!),
          'deleted': outlet.deletedAt != null,
        };
        final existingOutlet = existingOutletsByLocalId[outlet.id];
        final outletRecord = existingOutlet == null
            ? await _pb.collection(_outletsCollection).create(body: outletBody)
            : await _pb
                  .collection(_outletsCollection)
                  .update(existingOutlet.id, body: outletBody);
        outletRemoteIds[outlet.id] = outletRecord.id;
      }
    }

    return (distroRemoteIds, outletRemoteIds);
  }

  Future<void> _pushConnections(
    String localProjectId,
    String remoteProjectId, {
    required Map<String, String> groupRemoteIds,
    required Map<String, String> distroRemoteIds,
    required Map<String, String> outletRemoteIds,
  }) async {
    final connections = await (_database.select(
      _database.powerConnections,
    )..where((row) => row.projectId.equals(localProjectId))).get();

    await upsertRemoteChildren(
      _pb,
      collection: _connectionsCollection,
      parentField: 'project',
      remoteParentId: remoteProjectId,
      bodies: [
        for (final connection in connections)
          {
            'local_id': connection.id,
            'project': remoteProjectId,
            'phase_id': connection.phaseId,
            'source_distro': distroRemoteIds[connection.sourceDistroId],
            'source_outlet': outletRemoteIds[connection.sourceOutletId],
            'target_type': connection.targetType,
            'target_group': connection.targetGroupId == null
                ? null
                : groupRemoteIds[connection.targetGroupId],
            'target_distro': connection.targetDistroId == null
                ? null
                : distroRemoteIds[connection.targetDistroId],
            'selected_phases': jsonDecode(connection.selectedPhasesJson),
            'notes': connection.notes,
            'created_at': toRemoteIso(connection.createdAt),
            'updated_at': toRemoteIso(connection.updatedAt),
            'deleted_at': connection.deletedAt == null
                ? null
                : toRemoteIso(connection.deletedAt!),
            'deleted': connection.deletedAt != null,
          },
      ],
    );
  }

  Future<void> _pushTrusses(
    String localProjectId,
    String remoteProjectId,
  ) async {
    final trusses = await (_database.select(
      _database.projectTrusses,
    )..where((row) => row.projectId.equals(localProjectId))).get();

    await upsertRemoteChildren(
      _pb,
      collection: _trussesCollection,
      parentField: 'project',
      remoteParentId: remoteProjectId,
      bodies: [
        for (final truss in trusses)
          {
            'local_id': truss.id,
            'project': remoteProjectId,
            'phase_id': truss.phaseId,
            'name': truss.name,
            'truss_system_id': truss.trussSystemId,
            'truss_catalog_device_id': truss.trussCatalogDeviceId,
            'length_m': truss.lengthM,
            'max_total_load_kg': truss.maxTotalLoadKg,
            'max_distributed_load_kg_per_m': truss.maxDistributedLoadKgPerM,
            'manual_load_kg': truss.manualLoadKg,
            'assigned_group_ids': jsonDecode(truss.assignedGroupIdsJson),
            'notes': truss.notes,
            'created_at': toRemoteIso(truss.createdAt),
            'updated_at': toRemoteIso(truss.updatedAt),
            'deleted_at': truss.deletedAt == null
                ? null
                : toRemoteIso(truss.deletedAt!),
            'deleted': truss.deletedAt != null,
          },
      ],
    );
  }

  Future<String?> _findRemoteId(String collection, String localId) async {
    final matches = await _pb
        .collection(collection)
        .getList(
          perPage: 1,
          filter: _pb.filter('local_id = {:id}', {'id': localId}),
        );
    return matches.items.firstOrNull?.id;
  }

  // ---------------------------------------------------------------------
  // Pull (remote wins)
  // ---------------------------------------------------------------------

  Future<void> _pull(String localId, RecordModel remote) async {
    await _database.transaction(() async {
      final clientLocalId = _nullable(remote, 'client') == null
          ? null
          : await _findLocalId('clients', remote.getStringValue('client'));
      final locationLocalId = _nullable(remote, 'location') == null
          ? null
          : await _findLocalId('locations', remote.getStringValue('location'));

      await _database
          .into(_database.projects)
          .insertOnConflictUpdate(
            db.ProjectsCompanion(
              id: Value(localId),
              remoteId: Value(remote.id),
              workspaceId: Value(
                remote.getStringValue('workspace_id', 'local'),
              ),
              name: Value(remote.getStringValue('name')),
              phaseId: Value(remote.getStringValue('phase_id', 'default')),
              clientId: Value(clientLocalId),
              locationId: Value(locationLocalId),
              createdAt: Value(
                fromRemoteIso(remote.getStringValue('created_at')) ??
                    DateTime.now(),
              ),
              updatedAt: Value(
                fromRemoteIso(remote.getStringValue('updated_at')) ??
                    DateTime.now(),
              ),
              deletedAt: Value(
                fromRemoteIso(remote.getStringValue('deleted_at')),
              ),
              syncState: const Value('synced'),
              lastSyncedAt: Value(DateTime.now()),
            ),
          );

      final groupIdMap = await _pullGroups(localId, remote.id);
      final (distroIdMap, outletIdMap) = await _pullDistros(localId, remote.id);
      await _pullConnections(
        localId,
        remote.id,
        groupIdMap: groupIdMap,
        distroIdMap: distroIdMap,
        outletIdMap: outletIdMap,
      );
      await _pullTrusses(localId, remote.id);
    });
  }

  Future<Map<String, String>> _pullGroups(
    String localProjectId,
    String remoteProjectId,
  ) async {
    final remoteGroups = await _pb
        .collection(_groupsCollection)
        .getFullList(
          filter: _pb.filter('project = {:id}', {'id': remoteProjectId}),
        );

    final groupIdMap = <String, String>{};
    for (final record in remoteGroups) {
      final groupLocalId = record.getStringValue('local_id');
      groupIdMap[record.id] = groupLocalId;

      await _database
          .into(_database.projectGroups)
          .insertOnConflictUpdate(
            db.ProjectGroupsCompanion(
              id: Value(groupLocalId),
              projectId: Value(localProjectId),
              name: Value(record.getStringValue('name')),
              powerProfile: Value(
                record.getStringValue('power_profile', 'singlePhase'),
              ),
              createdAt: Value(
                fromRemoteIso(record.getStringValue('created_at')) ??
                    DateTime.now(),
              ),
              updatedAt: Value(
                fromRemoteIso(record.getStringValue('updated_at')) ??
                    DateTime.now(),
              ),
              deletedAt: Value(
                fromRemoteIso(record.getStringValue('deleted_at')),
              ),
              syncState: const Value('synced'),
              lastSyncedAt: Value(DateTime.now()),
            ),
          );

      final remoteItems = await _pb
          .collection(_itemsCollection)
          .getFullList(filter: _pb.filter('group = {:id}', {'id': record.id}));
      for (final itemRecord in remoteItems) {
        await _database
            .into(_database.projectItems)
            .insertOnConflictUpdate(
              db.ProjectItemsCompanion(
                id: Value(itemRecord.getStringValue('local_id')),
                projectId: Value(localProjectId),
                groupId: Value(groupLocalId),
                phaseId: Value(
                  itemRecord.getStringValue('phase_id', 'default'),
                ),
                nameSnapshot: Value(itemRecord.getStringValue('name_snapshot')),
                manufacturerSnapshot: Value(
                  _nullable(itemRecord, 'manufacturer_snapshot'),
                ),
                quantity: Value(itemRecord.getDoubleValue('quantity')),
                powerWSnapshot: Value(
                  itemRecord.getDoubleValue('power_w_snapshot'),
                ),
                currentASnapshot: Value(
                  itemRecord.getDoubleValue('current_a_snapshot'),
                ),
                weightKgSnapshot: Value(
                  itemRecord.getDoubleValue('weight_kg_snapshot'),
                ),
                riggingPointsSnapshot: Value(
                  itemRecord.data['rigging_points_snapshot'] == null
                      ? null
                      : itemRecord.getIntValue('rigging_points_snapshot'),
                ),
                unit: Value(itemRecord.getStringValue('unit', 'pcs')),
                createdAt: Value(
                  fromRemoteIso(itemRecord.getStringValue('created_at')) ??
                      DateTime.now(),
                ),
                updatedAt: Value(
                  fromRemoteIso(itemRecord.getStringValue('updated_at')) ??
                      DateTime.now(),
                ),
                deletedAt: Value(
                  fromRemoteIso(itemRecord.getStringValue('deleted_at')),
                ),
                syncState: const Value('synced'),
                lastSyncedAt: Value(DateTime.now()),
              ),
            );
      }

      final remoteHooks = await _pb
          .collection(_hookAssignmentsCollection)
          .getFullList(filter: _pb.filter('group = {:id}', {'id': record.id}));
      for (final hookRecord in remoteHooks) {
        await _database
            .into(_database.projectGroupHookAssignments)
            .insertOnConflictUpdate(
              db.ProjectGroupHookAssignmentsCompanion(
                id: Value(hookRecord.getStringValue('local_id')),
                projectId: Value(localProjectId),
                groupId: Value(groupLocalId),
                hookCatalogDeviceId: Value(
                  _nullable(hookRecord, 'hook_catalog_device_id'),
                ),
                hookNameSnapshot: Value(
                  hookRecord.getStringValue('hook_name_snapshot'),
                ),
                hookWeightKgSnapshot: Value(
                  hookRecord.getDoubleValue('hook_weight_kg_snapshot'),
                ),
                quantity: Value(hookRecord.getIntValue('quantity', 1)),
                createdAt: Value(
                  fromRemoteIso(hookRecord.getStringValue('created_at')) ??
                      DateTime.now(),
                ),
                updatedAt: Value(
                  fromRemoteIso(hookRecord.getStringValue('updated_at')) ??
                      DateTime.now(),
                ),
                deletedAt: Value(
                  fromRemoteIso(hookRecord.getStringValue('deleted_at')),
                ),
                syncState: const Value('synced'),
                lastSyncedAt: Value(DateTime.now()),
              ),
            );
      }
    }

    return groupIdMap;
  }

  Future<(Map<String, String>, Map<String, String>)> _pullDistros(
    String localProjectId,
    String remoteProjectId,
  ) async {
    final remoteDistros = await _pb
        .collection(_distrosCollection)
        .getFullList(
          filter: _pb.filter('project = {:id}', {'id': remoteProjectId}),
        );

    final distroIdMap = <String, String>{};
    final outletIdMap = <String, String>{};

    for (final record in remoteDistros) {
      final distroLocalId = record.getStringValue('local_id');
      distroIdMap[record.id] = distroLocalId;

      await _database
          .into(_database.projectDistros)
          .insertOnConflictUpdate(
            db.ProjectDistrosCompanion(
              id: Value(distroLocalId),
              projectId: Value(localProjectId),
              phaseId: Value(record.getStringValue('phase_id', 'default')),
              name: Value(record.getStringValue('name')),
              sourceType: Value(record.getStringValue('source_type', 'preset')),
              locationConnectorGroupId: Value(
                _nullable(record, 'location_connector_group_id'),
              ),
              inputConnectorTypeId: Value(
                _nullable(record, 'input_connector_type_id'),
              ),
              isRootPowerSource: Value(
                record.getBoolValue('is_root_power_source'),
              ),
              manualInputMaxCurrentA: Value(
                record.data['manual_input_max_current_a'] == null
                    ? null
                    : record.getDoubleValue('manual_input_max_current_a'),
              ),
              createdAt: Value(
                fromRemoteIso(record.getStringValue('created_at')) ??
                    DateTime.now(),
              ),
              updatedAt: Value(
                fromRemoteIso(record.getStringValue('updated_at')) ??
                    DateTime.now(),
              ),
              deletedAt: Value(
                fromRemoteIso(record.getStringValue('deleted_at')),
              ),
              syncState: const Value('synced'),
              lastSyncedAt: Value(DateTime.now()),
            ),
          );

      final remoteOutlets = await _pb
          .collection(_outletsCollection)
          .getFullList(filter: _pb.filter('distro = {:id}', {'id': record.id}));
      for (final outletRecord in remoteOutlets) {
        final outletLocalId = outletRecord.getStringValue('local_id');
        outletIdMap[outletRecord.id] = outletLocalId;

        await _database
            .into(_database.projectOutlets)
            .insertOnConflictUpdate(
              db.ProjectOutletsCompanion(
                id: Value(outletLocalId),
                projectId: Value(localProjectId),
                distroId: Value(distroLocalId),
                phaseId: Value(
                  outletRecord.getStringValue('phase_id', 'default'),
                ),
                templateOutletId: Value(
                  _nullable(outletRecord, 'template_outlet_id'),
                ),
                name: Value(outletRecord.getStringValue('name')),
                connectorTypeId: Value(
                  outletRecord.getStringValue('connector_type_id'),
                ),
                phase: Value(outletRecord.getStringValue('phase', 'l1')),
                maxCurrentA: Value(
                  outletRecord.getDoubleValue('max_current_a'),
                ),
                createdAt: Value(
                  fromRemoteIso(outletRecord.getStringValue('created_at')) ??
                      DateTime.now(),
                ),
                updatedAt: Value(
                  fromRemoteIso(outletRecord.getStringValue('updated_at')) ??
                      DateTime.now(),
                ),
                deletedAt: Value(
                  fromRemoteIso(outletRecord.getStringValue('deleted_at')),
                ),
                syncState: const Value('synced'),
                lastSyncedAt: Value(DateTime.now()),
              ),
            );
      }
    }

    return (distroIdMap, outletIdMap);
  }

  Future<void> _pullConnections(
    String localProjectId,
    String remoteProjectId, {
    required Map<String, String> groupIdMap,
    required Map<String, String> distroIdMap,
    required Map<String, String> outletIdMap,
  }) async {
    final remoteConnections = await _pb
        .collection(_connectionsCollection)
        .getFullList(
          filter: _pb.filter('project = {:id}', {'id': remoteProjectId}),
        );

    for (final record in remoteConnections) {
      final sourceDistroRemoteId = record.getStringValue('source_distro');
      final sourceOutletRemoteId = record.getStringValue('source_outlet');
      final targetGroupRemoteId = _nullable(record, 'target_group');
      final targetDistroRemoteId = _nullable(record, 'target_distro');

      final sourceDistroLocalId = distroIdMap[sourceDistroRemoteId];
      final sourceOutletLocalId = outletIdMap[sourceOutletRemoteId];
      if (sourceDistroLocalId == null || sourceOutletLocalId == null) {
        // Source distro/outlet was not part of this sync pass (e.g. a
        // dangling reference from a partially-synced project) - skip rather
        // than write a connection with a broken foreign key.
        continue;
      }

      await _database
          .into(_database.powerConnections)
          .insertOnConflictUpdate(
            db.PowerConnectionsCompanion(
              id: Value(record.getStringValue('local_id')),
              projectId: Value(localProjectId),
              phaseId: Value(record.getStringValue('phase_id', 'default')),
              sourceDistroId: Value(sourceDistroLocalId),
              sourceOutletId: Value(sourceOutletLocalId),
              targetType: Value(record.getStringValue('target_type', 'group')),
              targetGroupId: Value(
                targetGroupRemoteId == null
                    ? null
                    : groupIdMap[targetGroupRemoteId],
              ),
              targetDistroId: Value(
                targetDistroRemoteId == null
                    ? null
                    : distroIdMap[targetDistroRemoteId],
              ),
              selectedPhasesJson: Value(
                _jsonEncodeOrDefault(record.data['selected_phases']),
              ),
              notes: Value(_nullable(record, 'notes')),
              createdAt: Value(
                fromRemoteIso(record.getStringValue('created_at')) ??
                    DateTime.now(),
              ),
              updatedAt: Value(
                fromRemoteIso(record.getStringValue('updated_at')) ??
                    DateTime.now(),
              ),
              deletedAt: Value(
                fromRemoteIso(record.getStringValue('deleted_at')),
              ),
              syncState: const Value('synced'),
              lastSyncedAt: Value(DateTime.now()),
            ),
          );
    }
  }

  Future<void> _pullTrusses(
    String localProjectId,
    String remoteProjectId,
  ) async {
    final remoteTrusses = await _pb
        .collection(_trussesCollection)
        .getFullList(
          filter: _pb.filter('project = {:id}', {'id': remoteProjectId}),
        );

    for (final record in remoteTrusses) {
      await _database
          .into(_database.projectTrusses)
          .insertOnConflictUpdate(
            db.ProjectTrussesCompanion(
              id: Value(record.getStringValue('local_id')),
              projectId: Value(localProjectId),
              phaseId: Value(record.getStringValue('phase_id', 'default')),
              name: Value(record.getStringValue('name')),
              trussSystemId: Value(_nullable(record, 'truss_system_id')),
              trussCatalogDeviceId: Value(
                _nullable(record, 'truss_catalog_device_id'),
              ),
              lengthM: Value(record.getDoubleValue('length_m')),
              maxTotalLoadKg: Value(
                record.data['max_total_load_kg'] == null
                    ? null
                    : record.getDoubleValue('max_total_load_kg'),
              ),
              maxDistributedLoadKgPerM: Value(
                record.data['max_distributed_load_kg_per_m'] == null
                    ? null
                    : record.getDoubleValue('max_distributed_load_kg_per_m'),
              ),
              manualLoadKg: Value(record.getDoubleValue('manual_load_kg')),
              assignedGroupIdsJson: Value(
                _jsonEncodeOrDefault(record.data['assigned_group_ids']),
              ),
              notes: Value(_nullable(record, 'notes')),
              createdAt: Value(
                fromRemoteIso(record.getStringValue('created_at')) ??
                    DateTime.now(),
              ),
              updatedAt: Value(
                fromRemoteIso(record.getStringValue('updated_at')) ??
                    DateTime.now(),
              ),
              deletedAt: Value(
                fromRemoteIso(record.getStringValue('deleted_at')),
              ),
              syncState: const Value('synced'),
              lastSyncedAt: Value(DateTime.now()),
            ),
          );
    }
  }

  Future<String?> _findLocalId(String collection, String remoteId) async {
    if (remoteId.isEmpty) {
      return null;
    }
    try {
      final record = await _pb.collection(collection).getOne(remoteId);
      final localId = record.getStringValue('local_id');
      return localId.isEmpty ? null : localId;
    } catch (_) {
      return null;
    }
  }

  String? _nullable(RecordModel record, String field) {
    final value = record.getStringValue(field);
    return value.isEmpty ? null : value;
  }

  String _jsonEncodeOrDefault(Object? value) {
    if (value == null) {
      return '[]';
    }
    return jsonEncode(value);
  }
}
