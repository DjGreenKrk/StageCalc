import 'package:drift/drift.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../infrastructure/local_database/app_database.dart' as db;
import '../../../infrastructure/sync/pocketbase_child_sync.dart';
import '../../../infrastructure/sync/pocketbase_datetime.dart';
import '../../../infrastructure/sync/sync_direction.dart';
import '../../../infrastructure/sync/sync_summary.dart';

/// Two-way sync of `catalog_devices` and its `truss_load_chart_entries`
/// children (ADR-025's manufacturer load chart) - same whole-tree
/// reconciliation as the other sync services (ADR-026).
class PocketBaseCatalogSyncService {
  const PocketBaseCatalogSyncService(this._pb, this._database);

  final PocketBase _pb;
  final db.AppDatabase _database;

  static const _collection = 'catalog_devices';
  static const _loadChartCollection = 'truss_load_chart_entries';

  Future<SyncSummary> sync() async {
    final localRows = await _database.select(_database.catalogDevices).get();
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
        errors.add('catalog device $id: $error');
      }
    }

    return SyncSummary(
      pushed: pushed,
      pulled: pulled,
      unchanged: unchanged,
      errors: errors,
    );
  }

  Future<void> _push(db.CatalogDevice local, RecordModel? remote) async {
    final body = <String, Object?>{
      'local_id': local.id,
      'workspace_id': local.workspaceId,
      'name': local.name,
      'manufacturer': local.manufacturer,
      'category': local.category,
      'power_w': local.powerW,
      'current_a': local.currentA,
      'weight_kg': local.weightKg,
      'connector_type_id': local.connectorTypeIdsJson,
      'rigging_points': local.riggingPoints,
      'quantity_unit': local.quantityUnit,
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
      _database.catalogDevices,
    )..where((row) => row.id.equals(local.id))).write(
      db.CatalogDevicesCompanion(
        remoteId: Value(record.id),
        syncState: const Value('synced'),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );

    final chartEntries = await (_database.select(
      _database.trussLoadChartEntries,
    )..where((row) => row.catalogDeviceId.equals(local.id))).get();

    await upsertRemoteChildren(
      _pb,
      collection: _loadChartCollection,
      parentField: 'catalog_device',
      remoteParentId: record.id,
      bodies: [
        for (final entry in chartEntries)
          {
            'local_id': entry.id,
            'catalog_device': record.id,
            'length_m': entry.lengthM,
            'point_load_kg': entry.pointLoadKg,
            'distributed_load_kg_per_m': entry.distributedLoadKgPerM,
            'created_at': toRemoteIso(entry.createdAt),
            'updated_at': toRemoteIso(entry.updatedAt),
            'deleted_at': entry.deletedAt == null
                ? null
                : toRemoteIso(entry.deletedAt!),
            'deleted': entry.deletedAt != null,
          },
      ],
    );
  }

  Future<void> _pull(String localId, RecordModel remote) async {
    await _database.transaction(() async {
      await _database
          .into(_database.catalogDevices)
          .insertOnConflictUpdate(
            db.CatalogDevicesCompanion(
              id: Value(localId),
              remoteId: Value(remote.id),
              workspaceId: Value(
                remote.getStringValue('workspace_id', 'local'),
              ),
              name: Value(remote.getStringValue('name')),
              manufacturer: Value(_nullable(remote, 'manufacturer')),
              category: Value(remote.getStringValue('category', 'device')),
              powerW: Value(remote.getDoubleValue('power_w')),
              currentA: Value(remote.getDoubleValue('current_a')),
              weightKg: Value(remote.getDoubleValue('weight_kg')),
              connectorTypeIdsJson: Value(
                remote.getStringValue('connector_type_id', '[]'),
              ),
              riggingPoints: Value(
                remote.data['rigging_points'] == null
                    ? null
                    : remote.getIntValue('rigging_points'),
              ),
              quantityUnit: Value(
                remote.getStringValue('quantity_unit', 'pcs'),
              ),
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

      final remoteChartEntries = await _pb
          .collection(_loadChartCollection)
          .getFullList(
            filter: _pb.filter('catalog_device = {:id}', {'id': remote.id}),
          );
      for (final record in remoteChartEntries) {
        await _database
            .into(_database.trussLoadChartEntries)
            .insertOnConflictUpdate(
              db.TrussLoadChartEntriesCompanion(
                id: Value(record.getStringValue('local_id')),
                catalogDeviceId: Value(localId),
                lengthM: Value(record.getDoubleValue('length_m')),
                pointLoadKg: Value(record.getDoubleValue('point_load_kg')),
                distributedLoadKgPerM: Value(
                  record.getDoubleValue('distributed_load_kg_per_m'),
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
      }
    });
  }

  String? _nullable(RecordModel record, String field) {
    final value = record.getStringValue(field);
    return value.isEmpty ? null : value;
  }
}
