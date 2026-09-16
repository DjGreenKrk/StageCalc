import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/data/drift_catalog_repository.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;

void main() {
  late db.AppDatabase database;
  late DriftCatalogRepository repository;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftCatalogRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('saves, loads, and soft deletes catalog devices from sqlite', () async {
    expect(await repository.getDevices(), isEmpty);

    final now = DateTime(2026, 7, 5);
    const deviceId = 'sqlite_fixture';
    await repository.saveDevice(
      CatalogDevice(
        id: deviceId,
        name: 'SQLite fixture',
        manufacturer: 'GreenCrew',
        quantityUnit: CatalogQuantityUnit.pcs,
        powerW: 500,
        currentA: 2.2,
        weightKg: 12,
        riggingPoints: 2,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final savedDevices = await repository.getDevices();
    final savedDevice = savedDevices.singleWhere(
      (device) => device.id == deviceId,
    );

    expect(savedDevice.name, 'SQLite fixture');
    expect(savedDevice.powerW, 500);
    expect(savedDevice.riggingPoints, 2);

    await repository.deleteDevice(deviceId);
    final devicesAfterDelete = await repository.getDevices();

    expect(devicesAfterDelete.any((device) => device.id == deviceId), isFalse);
  });

  test(
    'saves and loads multiple connector types on one device (multi-select)',
    () async {
      final now = DateTime(2026, 9, 13);
      const deviceId = 'multi_connector_fixture';
      await repository.saveDevice(
        CatalogDevice(
          id: deviceId,
          name: 'Multi-connector fixture',
          quantityUnit: CatalogQuantityUnit.pcs,
          connectorTypeIds: const [
            CatalogConnectorType.powerConTrue1,
            CatalogConnectorType.xlr5,
          ],
          createdAt: now,
          updatedAt: now,
        ),
      );

      final loaded = await repository.getDevices();
      final loadedDevice = loaded.singleWhere((d) => d.id == deviceId);

      expect(loadedDevice.connectorTypeIds, [
        CatalogConnectorType.powerConTrue1,
        CatalogConnectorType.xlr5,
      ]);

      await repository.saveDevice(
        loadedDevice.copyWith(connectorTypeIds: const []),
      );
      final afterClearing = (await repository.getDevices()).singleWhere(
        (d) => d.id == deviceId,
      );
      expect(afterClearing.connectorTypeIds, isEmpty);
    },
  );

  test(
    'saves, loads, and soft deletes a truss load chart with its device',
    () async {
      final now = DateTime(2026, 7, 5);
      const deviceId = 'prolyte_h30v';
      final device = CatalogDevice(
        id: deviceId,
        name: 'Prolyte H30V',
        category: CatalogDeviceCategory.rigging,
        quantityUnit: CatalogQuantityUnit.pcs,
        createdAt: now,
        updatedAt: now,
        loadChart: const [
          TrussLoadChartEntry(
            id: 'chart_1',
            lengthM: 4,
            pointLoadKg: 800,
            distributedLoadKgPerM: 200,
          ),
          TrussLoadChartEntry(
            id: 'chart_2',
            lengthM: 8,
            pointLoadKg: 400,
            distributedLoadKgPerM: 100,
          ),
        ],
      );

      await repository.saveDevice(device);
      final loaded = await repository.getDevices();
      final loadedDevice = loaded.singleWhere((d) => d.id == deviceId);

      expect(loadedDevice.loadChart, hasLength(2));
      expect(loadedDevice.loadChart.first.lengthM, 4);
      expect(loadedDevice.loadChart.first.pointLoadKg, 800);
      expect(loadedDevice.loadChart.last.distributedLoadKgPerM, 100);

      await repository.saveDevice(
        device.copyWith(loadChart: [device.loadChart.first]),
      );
      final afterRemoval = await repository.getDevices();
      expect(
        afterRemoval.singleWhere((d) => d.id == deviceId).loadChart,
        hasLength(1),
      );

      await repository.deleteDevice(deviceId);
      final afterDelete = await repository.getDevices();
      expect(afterDelete.any((d) => d.id == deviceId), isFalse);
    },
  );
}
