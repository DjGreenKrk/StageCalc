import 'package:drift/drift.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../infrastructure/local_database/app_database.dart' as db;
import '../../../infrastructure/sync/pocketbase_child_sync.dart';
import '../../../infrastructure/sync/pocketbase_datetime.dart';
import '../../../infrastructure/sync/sync_direction.dart';
import '../../../infrastructure/sync/sync_summary.dart';

/// Two-way sync of `power_presets` and its `power_outlet_templates` children
/// (ADR-026) - same whole-tree reconciliation as
/// [PocketBaseLocationSyncService] for locations.
class PocketBasePowerPresetSyncService {
  const PocketBasePowerPresetSyncService(this._pb, this._database);

  final PocketBase _pb;
  final db.AppDatabase _database;

  static const _collection = 'power_presets';
  static const _outletsCollection = 'power_outlet_templates';

  Future<SyncSummary> sync() async {
    final localRows = await _database.select(_database.powerPresets).get();
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
        errors.add('power preset $id: $error');
      }
    }

    return SyncSummary(
      pushed: pushed,
      pulled: pulled,
      unchanged: unchanged,
      errors: errors,
    );
  }

  Future<void> _push(db.PowerPreset local, RecordModel? remote) async {
    final body = <String, Object?>{
      'local_id': local.id,
      'workspace_id': local.workspaceId,
      'name': local.name,
      'input_connector_type_id': local.inputConnectorTypeId,
      'notes': local.notes,
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
      _database.powerPresets,
    )..where((row) => row.id.equals(local.id))).write(
      db.PowerPresetsCompanion(
        remoteId: Value(record.id),
        syncState: const Value('synced'),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );

    final outlets = await (_database.select(
      _database.powerOutletTemplates,
    )..where((row) => row.presetId.equals(local.id))).get();

    await upsertRemoteChildren(
      _pb,
      collection: _outletsCollection,
      parentField: 'preset',
      remoteParentId: record.id,
      bodies: [
        for (final outlet in outlets)
          {
            'local_id': outlet.id,
            'preset': record.id,
            'name': outlet.name,
            'connector_type_id': outlet.connectorTypeId,
            'phase': outlet.phase,
            'created_at': toRemoteIso(outlet.createdAt),
            'updated_at': toRemoteIso(outlet.updatedAt),
            'deleted_at': outlet.deletedAt == null
                ? null
                : toRemoteIso(outlet.deletedAt!),
            'deleted': outlet.deletedAt != null,
          },
      ],
    );
  }

  Future<void> _pull(String localId, RecordModel remote) async {
    await _database.transaction(() async {
      await _database
          .into(_database.powerPresets)
          .insertOnConflictUpdate(
            db.PowerPresetsCompanion(
              id: Value(localId),
              remoteId: Value(remote.id),
              workspaceId: Value(
                remote.getStringValue('workspace_id', 'local'),
              ),
              name: Value(remote.getStringValue('name')),
              inputConnectorTypeId: Value(
                _nullable(remote, 'input_connector_type_id'),
              ),
              notes: Value(_nullable(remote, 'notes')),
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

      final remoteOutlets = await _pb
          .collection(_outletsCollection)
          .getFullList(filter: _pb.filter('preset = {:id}', {'id': remote.id}));

      for (final record in remoteOutlets) {
        await _database
            .into(_database.powerOutletTemplates)
            .insertOnConflictUpdate(
              db.PowerOutletTemplatesCompanion(
                id: Value(record.getStringValue('local_id')),
                presetId: Value(localId),
                name: Value(record.getStringValue('name')),
                connectorTypeId: Value(
                  record.getStringValue('connector_type_id'),
                ),
                phase: Value(record.getStringValue('phase', 'l1')),
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
