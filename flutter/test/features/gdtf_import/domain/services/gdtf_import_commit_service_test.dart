import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/data/drift_catalog_repository.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/gdtf_import/domain/entities/gdtf_fixture_type.dart';
import 'package:stagecalc/features/gdtf_import/domain/services/gdtf_import_commit_service.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;

void main() {
  late db.AppDatabase database;
  late DriftCatalogRepository catalogRepository;
  late GdtfImportCommitService service;

  const fixture = GdtfFixtureType(
    fixtureTypeId: 'EE88FCC8-6A9A-4523-BFD7-31115B703264',
    name: 'Robin Painte',
    sourceFileName: 'robe@robin-painte.gdtf',
    manufacturer: 'Robe Lighting',
    weightKg: 19.6,
    powerW: 440,
    rawConnectorTypes: ['PowerconTRUE1', 'XLR5', 'RJ45'],
  );

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    catalogRepository = DriftCatalogRepository(database);
    service = GdtfImportCommitService(catalogRepository: catalogRepository);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'createNewDevice persists mapped fields, including derived current',
    () async {
      final summary = await service.commit([
        const GdtfImportDecision(
          fixture: fixture,
          action: GdtfImportAction.createNewDevice,
          category: CatalogDeviceCategory.lighting,
        ),
      ]);

      expect(summary.createdDeviceCount, 1);
      expect(summary.linkedDeviceCount, 0);
      expect(summary.alreadyLinkedCount, 0);

      final devices = await catalogRepository.getDevices();
      final device = devices.single;
      expect(device.name, 'Robin Painte');
      expect(device.manufacturer, 'Robe Lighting');
      expect(device.weightKg, 19.6);
      expect(device.powerW, 440);
      expect(device.currentA, closeTo(440 / 230, 0.0001));
      expect(device.gdtfFixtureTypeId, fixture.fixtureTypeId);
      expect(
        device.connectorTypeIds,
        containsAll([
          CatalogConnectorType.powerConTrue1,
          CatalogConnectorType.xlr5,
          CatalogConnectorType.etherCon,
        ]),
      );
    },
  );

  test(
    'createNewDevice for a category that hides electrical fields zeroes them out',
    () async {
      const cableFixture = GdtfFixtureType(
        fixtureTypeId: 'cable-guid',
        name: 'Extension cable',
        sourceFileName: 'cable.gdtf',
        powerW: 100,
      );

      await service.commit([
        const GdtfImportDecision(
          fixture: cableFixture,
          action: GdtfImportAction.createNewDevice,
          category: CatalogDeviceCategory.cable,
        ),
      ]);

      final device = (await catalogRepository.getDevices()).single;
      expect(device.powerW, 0);
      expect(device.currentA, 0);
    },
  );

  test(
    'manually linking to an existing device stamps its gdtfFixtureTypeId without overwriting other fields',
    () async {
      final now = DateTime.now();
      final existingDevice = CatalogDevice(
        id: 'device_preexisting',
        name: 'Robin Painte dodany ręcznie',
        weightKg: 20,
        quantityUnit: CatalogQuantityUnit.pcs,
        createdAt: now,
        updatedAt: now,
      );
      await catalogRepository.saveDevice(existingDevice);

      final summary = await service.commit([
        GdtfImportDecision(
          fixture: fixture,
          action: GdtfImportAction.useCatalogDevice,
          existingDeviceId: existingDevice.id,
          linkExistingDevice: true,
        ),
      ]);

      expect(summary.createdDeviceCount, 0);
      expect(summary.linkedDeviceCount, 1);

      final devices = await catalogRepository.getDevices();
      expect(devices, hasLength(1));
      expect(devices.single.id, existingDevice.id);
      expect(devices.single.gdtfFixtureTypeId, fixture.fixtureTypeId);
      // Existing fields (weight) were not overwritten by the GDTF file.
      expect(devices.single.weightKg, 20);
    },
  );

  test(
    'a row already linked before the panel opened is a true no-op on re-import',
    () async {
      final now = DateTime.now();
      final linkedDevice = CatalogDevice(
        id: 'device_linked',
        name: 'Robin Painte',
        weightKg: 25, // hand-edited by the user after the first import
        powerW: 500, // hand-edited too
        quantityUnit: CatalogQuantityUnit.pcs,
        createdAt: now,
        updatedAt: now,
        gdtfFixtureTypeId: fixture.fixtureTypeId,
      );
      await catalogRepository.saveDevice(linkedDevice);

      final summary = await service.commit([
        GdtfImportDecision(
          fixture: fixture,
          action: GdtfImportAction.useCatalogDevice,
          existingDeviceId: linkedDevice.id,
        ),
      ]);

      expect(summary.createdDeviceCount, 0);
      expect(summary.linkedDeviceCount, 0);
      expect(summary.alreadyLinkedCount, 1);

      final devices = await catalogRepository.getDevices();
      expect(devices, hasLength(1));
      expect(devices.single.weightKg, 25);
      expect(devices.single.powerW, 500);
      // Drift/SQLite round-trips DateTime at second precision, so compare
      // truncated rather than requiring byte-for-byte equality - the point
      // is that the record was never re-saved, not sub-second precision.
      expect(
        devices.single.updatedAt.difference(linkedDevice.updatedAt).inSeconds,
        0,
      );
    },
  );
}
