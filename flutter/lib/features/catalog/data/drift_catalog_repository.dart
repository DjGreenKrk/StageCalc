import 'package:drift/drift.dart';

import '../../../infrastructure/local_database/app_database.dart' as db;
import '../../../shared/models/offline_sync_status.dart';
import '../domain/entities/catalog_device.dart';
import 'catalog_repository.dart';
import 'demo_catalog_factory.dart';

class DriftCatalogRepository implements CatalogRepository {
  const DriftCatalogRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<List<CatalogDevice>> getDevices() async {
    final rows =
        await (_database.select(_database.catalogDevices)
              ..where((row) => row.deletedAt.isNull())
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .get();

    return rows.map(_mapDevice).toList();
  }

  @override
  Future<void> saveDevice(CatalogDevice device) async {
    await _database
        .into(_database.catalogDevices)
        .insertOnConflictUpdate(
          db.CatalogDevicesCompanion(
            id: Value(device.id),
            name: Value(device.name),
            manufacturer: Value(device.manufacturer),
            category: Value(device.category.toJson()),
            powerW: Value(device.powerW),
            currentA: Value(device.currentA),
            weightKg: Value(device.weightKg),
            connectorTypeId: Value(device.connectorTypeId),
            quantityUnit: Value(device.quantityUnit.toJson()),
            createdAt: Value(device.createdAt),
            updatedAt: Value(device.updatedAt),
            deletedAt: const Value(null),
            syncState: Value(device.syncStatus.toJson()),
          ),
        );
  }

  @override
  Future<void> deleteDevice(String id) async {
    final now = DateTime.now();
    await (_database.update(
      _database.catalogDevices,
    )..where((row) => row.id.equals(id))).write(
      db.CatalogDevicesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> ensureSeedData() async {
    final devices = await getDevices();
    if (devices.isNotEmpty) {
      return;
    }

    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.catalogDevices,
        DemoCatalogFactory.createSeedDevices().map(_deviceToCompanion).toList(),
      );
    });
  }

  CatalogDevice _mapDevice(db.CatalogDevice row) {
    return CatalogDevice(
      id: row.id,
      name: row.name,
      manufacturer: row.manufacturer,
      category: CatalogDeviceCategoryJson.fromJson(row.category),
      powerW: row.powerW,
      currentA: row.currentA,
      weightKg: row.weightKg,
      connectorTypeId: row.connectorTypeId,
      quantityUnit: CatalogQuantityUnitJson.fromJson(row.quantityUnit),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      syncStatus: OfflineSyncStatusJson.fromJson(row.syncState),
    );
  }

  db.CatalogDevicesCompanion _deviceToCompanion(CatalogDevice device) {
    return db.CatalogDevicesCompanion(
      id: Value(device.id),
      name: Value(device.name),
      manufacturer: Value(device.manufacturer),
      category: Value(device.category.toJson()),
      powerW: Value(device.powerW),
      currentA: Value(device.currentA),
      weightKg: Value(device.weightKg),
      connectorTypeId: Value(device.connectorTypeId),
      quantityUnit: Value(device.quantityUnit.toJson()),
      createdAt: Value(device.createdAt),
      updatedAt: Value(device.updatedAt),
      syncState: Value(device.syncStatus.toJson()),
    );
  }
}
