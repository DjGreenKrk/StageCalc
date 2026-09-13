import 'package:drift/drift.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../infrastructure/local_database/app_database.dart' as db;
import '../../../infrastructure/sync/pocketbase_datetime.dart';
import '../../../infrastructure/sync/sync_direction.dart';
import '../../../infrastructure/sync/sync_summary.dart';

/// Two-way sync of the `clients` collection against PocketBase (ADR-026):
/// for every client that exists locally, remotely, or both, the side with
/// the older `updated_at` is overwritten by the newer one ("last write
/// wins"). Clients have no nested children, so this is the simplest of the
/// five sync services and the reference implementation the others copy.
class PocketBaseClientSyncService {
  const PocketBaseClientSyncService(this._pb, this._database);

  final PocketBase _pb;
  final db.AppDatabase _database;

  static const _collection = 'clients';

  Future<SyncSummary> sync() async {
    final localRows = await _database.select(_database.clients).get();
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
        errors.add('client $id: $error');
      }
    }

    return SyncSummary(
      pushed: pushed,
      pulled: pulled,
      unchanged: unchanged,
      errors: errors,
    );
  }

  Future<void> _push(db.Client local, RecordModel? remote) async {
    final body = <String, Object?>{
      'local_id': local.id,
      'workspace_id': local.workspaceId,
      'name': local.name,
      'contact_person': local.contactPerson,
      'email': local.email,
      'phone': local.phone,
      'address': local.address,
      'nip': local.nip,
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
      _database.clients,
    )..where((row) => row.id.equals(local.id))).write(
      db.ClientsCompanion(
        remoteId: Value(record.id),
        syncState: const Value('synced'),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _pull(String localId, RecordModel remote) async {
    await _database
        .into(_database.clients)
        .insertOnConflictUpdate(
          db.ClientsCompanion(
            id: Value(localId),
            remoteId: Value(remote.id),
            workspaceId: Value(remote.getStringValue('workspace_id', 'local')),
            name: Value(remote.getStringValue('name')),
            contactPerson: Value(_nullable(remote, 'contact_person')),
            email: Value(_nullable(remote, 'email')),
            phone: Value(_nullable(remote, 'phone')),
            address: Value(_nullable(remote, 'address')),
            nip: Value(_nullable(remote, 'nip')),
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
  }

  String? _nullable(RecordModel record, String field) {
    final value = record.getStringValue(field);
    return value.isEmpty ? null : value;
  }
}
