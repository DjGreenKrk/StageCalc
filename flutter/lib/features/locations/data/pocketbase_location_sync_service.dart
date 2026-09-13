import 'package:drift/drift.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../infrastructure/local_database/app_database.dart' as db;
import '../../../infrastructure/sync/pocketbase_child_sync.dart';
import '../../../infrastructure/sync/pocketbase_datetime.dart';
import '../../../infrastructure/sync/sync_direction.dart';
import '../../../infrastructure/sync/sync_summary.dart';

/// Two-way sync of `locations` plus its `location_power_connectors` and
/// `location_contacts` children (ADR-026). Reconciliation happens at the
/// location level: whichever side's location `updated_at` is newer wins, and
/// that side's full set of connectors/contacts is upserted onto the other -
/// individual child rows are not diffed or merged independently, since they
/// only ever change together with their parent (every save stamps children
/// with the location's own `updatedAt`, see `DriftLocationRepository`).
class PocketBaseLocationSyncService {
  const PocketBaseLocationSyncService(this._pb, this._database);

  final PocketBase _pb;
  final db.AppDatabase _database;

  static const _collection = 'locations';
  static const _connectorsCollection = 'location_power_connectors';
  static const _contactsCollection = 'location_contacts';

  Future<SyncSummary> sync() async {
    final localRows = await _database.select(_database.locations).get();
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
        errors.add('location $id: $error');
      }
    }

    return SyncSummary(
      pushed: pushed,
      pulled: pulled,
      unchanged: unchanged,
      errors: errors,
    );
  }

  Future<void> _push(db.Location local, RecordModel? remote) async {
    final body = <String, Object?>{
      'local_id': local.id,
      'workspace_id': local.workspaceId,
      'name': local.name,
      'address': local.address,
      'capacity': local.capacity,
      'contact_name': local.contactName,
      'contact_phone': local.contactPhone,
      'contact_email': local.contactEmail,
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
      _database.locations,
    )..where((row) => row.id.equals(local.id))).write(
      db.LocationsCompanion(
        remoteId: Value(record.id),
        syncState: const Value('synced'),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );

    final connectors = await (_database.select(
      _database.locationPowerConnectors,
    )..where((row) => row.locationId.equals(local.id))).get();
    await upsertRemoteChildren(
      _pb,
      collection: _connectorsCollection,
      parentField: 'location',
      remoteParentId: record.id,
      bodies: [
        for (final connector in connectors)
          {
            'local_id': connector.id,
            'location': record.id,
            'name': connector.name,
            'connector_type_id': connector.connectorTypeId,
            'quantity': connector.quantity,
            'notes': connector.notes,
            'created_at': toRemoteIso(connector.createdAt),
            'updated_at': toRemoteIso(connector.updatedAt),
            'deleted_at': connector.deletedAt == null
                ? null
                : toRemoteIso(connector.deletedAt!),
            'deleted': connector.deletedAt != null,
          },
      ],
    );

    final contacts = await (_database.select(
      _database.locationContacts,
    )..where((row) => row.locationId.equals(local.id))).get();
    await upsertRemoteChildren(
      _pb,
      collection: _contactsCollection,
      parentField: 'location',
      remoteParentId: record.id,
      bodies: [
        for (final contact in contacts)
          {
            'local_id': contact.id,
            'location': record.id,
            'role': contact.role,
            'name': contact.name,
            'phone': contact.phone,
            'email': contact.email,
            'notes': contact.notes,
            'created_at': toRemoteIso(contact.createdAt),
            'updated_at': toRemoteIso(contact.updatedAt),
            'deleted_at': contact.deletedAt == null
                ? null
                : toRemoteIso(contact.deletedAt!),
            'deleted': contact.deletedAt != null,
          },
      ],
    );
  }

  Future<void> _pull(String localId, RecordModel remote) async {
    await _database.transaction(() async {
      await _database
          .into(_database.locations)
          .insertOnConflictUpdate(
            db.LocationsCompanion(
              id: Value(localId),
              remoteId: Value(remote.id),
              workspaceId: Value(
                remote.getStringValue('workspace_id', 'local'),
              ),
              name: Value(remote.getStringValue('name')),
              address: Value(_nullable(remote, 'address')),
              capacity: Value(
                remote.data['capacity'] == null
                    ? null
                    : remote.getIntValue('capacity'),
              ),
              contactName: Value(_nullable(remote, 'contact_name')),
              contactPhone: Value(_nullable(remote, 'contact_phone')),
              contactEmail: Value(_nullable(remote, 'contact_email')),
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

      final remoteConnectors = await _pb
          .collection(_connectorsCollection)
          .getFullList(
            filter: _pb.filter('location = {:id}', {'id': remote.id}),
          );
      for (final record in remoteConnectors) {
        await _database
            .into(_database.locationPowerConnectors)
            .insertOnConflictUpdate(
              db.LocationPowerConnectorsCompanion(
                id: Value(record.getStringValue('local_id')),
                locationId: Value(localId),
                name: Value(record.getStringValue('name')),
                connectorTypeId: Value(
                  record.getStringValue('connector_type_id'),
                ),
                quantity: Value(record.getIntValue('quantity', 1)),
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

      final remoteContacts = await _pb
          .collection(_contactsCollection)
          .getFullList(
            filter: _pb.filter('location = {:id}', {'id': remote.id}),
          );
      for (final record in remoteContacts) {
        await _database
            .into(_database.locationContacts)
            .insertOnConflictUpdate(
              db.LocationContactsCompanion(
                id: Value(record.getStringValue('local_id')),
                locationId: Value(localId),
                role: Value(record.getStringValue('role')),
                name: Value(record.getStringValue('name')),
                phone: Value(_nullable(record, 'phone')),
                email: Value(_nullable(record, 'email')),
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
    });
  }

  String? _nullable(RecordModel record, String field) {
    final value = record.getStringValue(field);
    return value.isEmpty ? null : value;
  }
}
