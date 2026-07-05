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

  test(
    'seeds, saves, loads, and soft deletes catalog devices from sqlite',
    () async {
      await repository.ensureSeedData();
      final seededDevices = await repository.getDevices();

      expect(seededDevices, isNotEmpty);
      expect(seededDevices.any((device) => device.name == 'BMFL Spot'), isTrue);

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

      await repository.deleteDevice(deviceId);
      final devicesAfterDelete = await repository.getDevices();

      expect(
        devicesAfterDelete.any((device) => device.id == deviceId),
        isFalse,
      );
    },
  );
}
