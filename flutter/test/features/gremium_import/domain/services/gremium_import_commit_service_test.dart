import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/data/drift_catalog_repository.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/gremium_import/domain/entities/gremium_device_type.dart';
import 'package:stagecalc/features/gremium_import/domain/entities/gremium_pack_list.dart';
import 'package:stagecalc/features/gremium_import/domain/services/gremium_import_commit_service.dart';
import 'package:stagecalc/features/projects/data/drift_project_repository.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;

void main() {
  late db.AppDatabase database;
  late DriftCatalogRepository catalogRepository;
  late DriftProjectRepository projectRepository;
  late GremiumImportCommitService service;

  const gremiumProject = GremiumProjectInfo(
    id: 'event-1',
    name: 'Konferencja medyczna',
  );

  const lampItem = GremiumItem(
    lineId: 'line-1',
    inventoryItemId: 'inv-1',
    name: 'DNA Pole One',
    quantity: 2,
    technical: GremiumTechnical(unitWeightKg: 16.6),
  );

  const ownItem = GremiumItem(
    lineId: 'line-2',
    name: 'Rozdzielnia podwykonawcy',
    quantity: 1,
  );

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    catalogRepository = DriftCatalogRepository(database);
    projectRepository = DriftProjectRepository(database);
    service = GremiumImportCommitService(
      catalogRepository: catalogRepository,
      projectRepository: projectRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('first import creates a new device, project, and items', () async {
    final summary = await service.commit(
      gremiumProject: gremiumProject,
      decisions: [
        const GremiumImportDecision(
          item: lampItem,
          targetGroupName: 'Import z Gremium',
          action: GremiumImportAction.createNewDevice,
          deviceType: GremiumDeviceType.singlePhase,
        ),
        const GremiumImportDecision(
          item: ownItem,
          targetGroupName: 'Import z Gremium',
          action: GremiumImportAction.ownItemOnly,
        ),
      ],
    );

    expect(summary.createdNewProject, isTrue);
    expect(summary.createdDeviceCount, 1);
    expect(summary.importedItemCount, 2);

    final devices = await catalogRepository.getDevices();
    expect(devices.single.gremiumInventoryItemId, 'inv-1');
    expect(devices.single.weightKg, 16.6);

    final projects = await projectRepository.getProjects();
    expect(projects.single.gremiumProjectId, 'event-1');
    final items = projects.single.groups.single.items;
    expect(items, hasLength(2));
    expect(
      items
          .firstWhere((item) => item.gremiumLineId == 'line-1')
          .catalogDeviceId,
      devices.single.id,
    );
    expect(
      items
          .firstWhere((item) => item.gremiumLineId == 'line-2')
          .catalogDeviceId,
      isNull,
    );
  });

  test(
    're-importing the same file updates the same project without duplicating',
    () async {
      await service.commit(
        gremiumProject: gremiumProject,
        decisions: [
          const GremiumImportDecision(
            item: lampItem,
            targetGroupName: 'Import z Gremium',
            action: GremiumImportAction.createNewDevice,
            deviceType: GremiumDeviceType.singlePhase,
          ),
        ],
      );

      // Simulate a re-export of the same item, now matched (linked) and
      // with an updated quantity.
      final devices = await catalogRepository.getDevices();
      final linkedDevice = devices.single;
      const updatedLampItem = GremiumItem(
        lineId: 'line-1',
        inventoryItemId: 'inv-1',
        name: 'DNA Pole One',
        quantity: 5,
        technical: GremiumTechnical(unitWeightKg: 16.6),
      );

      final summary = await service.commit(
        gremiumProject: gremiumProject,
        decisions: [
          GremiumImportDecision(
            item: updatedLampItem,
            targetGroupName: 'Import z Gremium',
            action: GremiumImportAction.useCatalogDevice,
            existingDeviceId: linkedDevice.id,
          ),
        ],
      );

      expect(summary.createdNewProject, isFalse);
      expect(summary.createdDeviceCount, 0);

      final projects = await projectRepository.getProjects();
      expect(projects, hasLength(1));
      final items = projects.single.groups.single.items;
      expect(items, hasLength(1));
      expect(items.single.quantity, 5);
    },
  );

  test(
    'a line missing from the new file is removed from the project on re-import',
    () async {
      await service.commit(
        gremiumProject: gremiumProject,
        decisions: [
          const GremiumImportDecision(
            item: lampItem,
            targetGroupName: 'Import z Gremium',
            action: GremiumImportAction.createNewDevice,
            deviceType: GremiumDeviceType.singlePhase,
          ),
          const GremiumImportDecision(
            item: ownItem,
            targetGroupName: 'Import z Gremium',
            action: GremiumImportAction.ownItemOnly,
          ),
        ],
      );

      // Re-import without ownItem (it was removed from the Gremium list).
      final devices = await catalogRepository.getDevices();
      final summary = await service.commit(
        gremiumProject: gremiumProject,
        decisions: [
          GremiumImportDecision(
            item: lampItem,
            targetGroupName: 'Import z Gremium',
            action: GremiumImportAction.useCatalogDevice,
            existingDeviceId: devices.single.id,
          ),
        ],
      );

      expect(summary.removedItemCount, 1);
      final projects = await projectRepository.getProjects();
      expect(projects.single.groups.single.items, hasLength(1));
      expect(
        projects.single.groups.single.items.single.gremiumLineId,
        'line-1',
      );
    },
  );

  test(
    'linking to an existing device stamps its gremiumInventoryItemId without creating a duplicate',
    () async {
      final now = DateTime.now();
      final existingDevice = CatalogDevice(
        id: 'device_preexisting',
        name: 'Lampa dodana ręcznie',
        weightKg: 5,
        quantityUnit: CatalogQuantityUnit.pcs,
        createdAt: now,
        updatedAt: now,
      );
      await catalogRepository.saveDevice(existingDevice);

      final summary = await service.commit(
        gremiumProject: gremiumProject,
        decisions: [
          GremiumImportDecision(
            item: lampItem,
            targetGroupName: 'Import z Gremium',
            action: GremiumImportAction.useCatalogDevice,
            existingDeviceId: existingDevice.id,
            linkExistingDevice: true,
          ),
        ],
      );

      expect(summary.createdDeviceCount, 0);
      expect(summary.linkedDeviceCount, 1);

      final devices = await catalogRepository.getDevices();
      expect(devices, hasLength(1));
      expect(devices.single.id, existingDevice.id);
      expect(devices.single.gremiumInventoryItemId, 'inv-1');
      // Existing fields (weight) were not overwritten by Gremium's data.
      expect(devices.single.weightKg, 5);
    },
  );
}
