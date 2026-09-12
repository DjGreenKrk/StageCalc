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

    final devices = <CatalogDevice>[];
    for (final row in rows) {
      final loadChartRows =
          await (_database.select(_database.trussLoadChartEntries)
                ..where(
                  (chartRow) =>
                      chartRow.catalogDeviceId.equals(row.id) &
                      chartRow.deletedAt.isNull(),
                )
                ..orderBy([(chartRow) => OrderingTerm.asc(chartRow.lengthM)]))
              .get();

      devices.add(_mapDevice(row, loadChartRows));
    }

    return devices;
  }

  @override
  Future<void> saveDevice(CatalogDevice device) async {
    await _database.transaction(() async {
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
              riggingPoints: Value(device.riggingPoints),
              quantityUnit: Value(device.quantityUnit.toJson()),
              createdAt: Value(device.createdAt),
              updatedAt: Value(device.updatedAt),
              deletedAt: const Value(null),
              syncState: Value(device.syncStatus.toJson()),
            ),
          );

      final existingChartEntries = await (_database.select(
        _database.trussLoadChartEntries,
      )..where((row) => row.catalogDeviceId.equals(device.id))).get();
      final chartEntryIds = device.loadChart.map((entry) => entry.id).toSet();

      for (final existingEntry in existingChartEntries) {
        if (!chartEntryIds.contains(existingEntry.id)) {
          await (_database.update(
            _database.trussLoadChartEntries,
          )..where((row) => row.id.equals(existingEntry.id))).write(
            db.TrussLoadChartEntriesCompanion(
              deletedAt: Value(device.updatedAt),
              updatedAt: Value(device.updatedAt),
            ),
          );
        }
      }

      for (final (index, entry) in device.loadChart.indexed) {
        await _database
            .into(_database.trussLoadChartEntries)
            .insertOnConflictUpdate(
              db.TrussLoadChartEntriesCompanion(
                id: Value(entry.id),
                catalogDeviceId: Value(device.id),
                lengthM: Value(entry.lengthM),
                pointLoadKg: Value(entry.pointLoadKg),
                distributedLoadKgPerM: Value(entry.distributedLoadKgPerM),
                sortOrder: Value(index),
                createdAt: Value(device.createdAt),
                updatedAt: Value(device.updatedAt),
                deletedAt: const Value(null),
              ),
            );
      }
    });
  }

  @override
  Future<void> deleteDevice(String id) async {
    final now = DateTime.now();
    await _database.transaction(() async {
      await (_database.update(
        _database.catalogDevices,
      )..where((row) => row.id.equals(id))).write(
        db.CatalogDevicesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await (_database.update(
        _database.trussLoadChartEntries,
      )..where((row) => row.catalogDeviceId.equals(id))).write(
        db.TrussLoadChartEntriesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
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

  CatalogDevice _mapDevice(
    db.CatalogDevice row,
    List<db.TrussLoadChartEntry> loadChartRows,
  ) {
    return CatalogDevice(
      id: row.id,
      name: row.name,
      manufacturer: row.manufacturer,
      category: CatalogDeviceCategoryJson.fromJson(row.category),
      powerW: row.powerW,
      currentA: row.currentA,
      weightKg: row.weightKg,
      connectorTypeId: row.connectorTypeId,
      riggingPoints: row.riggingPoints,
      loadChart: loadChartRows.map(_mapLoadChartEntry).toList(),
      quantityUnit: CatalogQuantityUnitJson.fromJson(row.quantityUnit),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      syncStatus: OfflineSyncStatusJson.fromJson(row.syncState),
    );
  }

  TrussLoadChartEntry _mapLoadChartEntry(db.TrussLoadChartEntry row) {
    return TrussLoadChartEntry(
      id: row.id,
      lengthM: row.lengthM,
      pointLoadKg: row.pointLoadKg,
      distributedLoadKgPerM: row.distributedLoadKgPerM,
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
      riggingPoints: Value(device.riggingPoints),
      quantityUnit: Value(device.quantityUnit.toJson()),
      createdAt: Value(device.createdAt),
      updatedAt: Value(device.updatedAt),
      syncState: Value(device.syncStatus.toJson()),
    );
  }
}
