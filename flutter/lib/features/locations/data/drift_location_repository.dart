import 'package:drift/drift.dart';

import '../../../infrastructure/local_database/app_database.dart' as db;
import '../../../shared/models/offline_sync_status.dart';
import '../domain/entities/location.dart';
import 'location_repository.dart';

class DriftLocationRepository implements LocationRepository {
  const DriftLocationRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<List<Location>> getLocations() async {
    final rows =
        await (_database.select(_database.locations)
              ..where((row) => row.deletedAt.isNull())
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .get();

    return rows.map(_mapLocation).toList();
  }

  @override
  Future<void> saveLocation(Location location) async {
    await _database
        .into(_database.locations)
        .insertOnConflictUpdate(
          db.LocationsCompanion(
            id: Value(location.id),
            name: Value(location.name),
            address: Value(location.address),
            capacity: Value(location.capacity),
            contactName: Value(location.contactName),
            contactPhone: Value(location.contactPhone),
            contactEmail: Value(location.contactEmail),
            notes: Value(location.notes),
            createdAt: Value(location.createdAt),
            updatedAt: Value(location.updatedAt),
            deletedAt: const Value(null),
            syncState: Value(location.syncStatus.toJson()),
          ),
        );
  }

  @override
  Future<void> deleteLocation(String id) async {
    final now = DateTime.now();
    await (_database.update(
      _database.locations,
    )..where((row) => row.id.equals(id))).write(
      db.LocationsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Location _mapLocation(db.Location row) {
    return Location(
      id: row.id,
      name: row.name,
      address: row.address,
      capacity: row.capacity,
      contactName: row.contactName,
      contactPhone: row.contactPhone,
      contactEmail: row.contactEmail,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      syncStatus: OfflineSyncStatusJson.fromJson(row.syncState),
    );
  }
}
