import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/services/catalog_duplicate_merge_service.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;

void main() {
  late db.AppDatabase database;
  late CatalogDuplicateMergeService service;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    service = CatalogDuplicateMergeService(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertDevice(
    String id, {
    String? gdtfFixtureTypeId,
    String? gremiumInventoryItemId,
  }) async {
    final now = DateTime(2026, 1, 1);
    await database
        .into(database.catalogDevices)
        .insert(
          db.CatalogDevicesCompanion.insert(
            id: id,
            name: 'Device $id',
            createdAt: now,
            updatedAt: now,
            gdtfFixtureTypeId: Value(gdtfFixtureTypeId),
            gremiumInventoryItemId: Value(gremiumInventoryItemId),
          ),
        );
  }

  test(
    'repoints ProjectItem/ProjectDistro/ProjectGroupHookAssignment/'
    'ProjectTruss references from the discarded device to the kept one',
    () async {
      await insertDevice('keep');
      await insertDevice('discard');

      final now = DateTime(2026, 1, 1);
      await database
          .into(database.projectItems)
          .insert(
            db.ProjectItemsCompanion.insert(
              id: 'item1',
              projectId: 'project1',
              groupId: 'group1',
              catalogDeviceId: const Value('discard'),
              nameSnapshot: 'Device discard',
              quantity: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.projectDistros)
          .insert(
            db.ProjectDistrosCompanion.insert(
              id: 'distro1',
              projectId: 'project1',
              name: 'Distro',
              catalogDeviceId: const Value('discard'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.projectGroupHookAssignments)
          .insert(
            db.ProjectGroupHookAssignmentsCompanion.insert(
              id: 'hook1',
              projectId: 'project1',
              groupId: 'group1',
              hookCatalogDeviceId: const Value('discard'),
              hookNameSnapshot: 'Hook discard',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.projectTrusses)
          .insert(
            db.ProjectTrussesCompanion.insert(
              id: 'truss1',
              projectId: 'project1',
              name: 'Truss',
              trussCatalogDeviceId: const Value('discard'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await service.merge(keepDeviceId: 'keep', discardDeviceId: 'discard');

      final item = await (database.select(
        database.projectItems,
      )..where((row) => row.id.equals('item1'))).getSingle();
      expect(item.catalogDeviceId, 'keep');

      final distro = await (database.select(
        database.projectDistros,
      )..where((row) => row.id.equals('distro1'))).getSingle();
      expect(distro.catalogDeviceId, 'keep');

      final hook = await (database.select(
        database.projectGroupHookAssignments,
      )..where((row) => row.id.equals('hook1'))).getSingle();
      expect(hook.hookCatalogDeviceId, 'keep');

      final truss = await (database.select(
        database.projectTrusses,
      )..where((row) => row.id.equals('truss1'))).getSingle();
      expect(truss.trussCatalogDeviceId, 'keep');

      final discardedDevice = await (database.select(
        database.catalogDevices,
      )..where((row) => row.id.equals('discard'))).getSingle();
      expect(discardedDevice.deletedAt != null, isTrue);
    },
  );

  test(
    'bumps updatedAt on repointed rows so they push out on next sync',
    () async {
      await insertDevice('keep');
      await insertDevice('discard');

      final past = DateTime(2020, 1, 1);
      await database
          .into(database.projectItems)
          .insert(
            db.ProjectItemsCompanion.insert(
              id: 'item1',
              projectId: 'project1',
              groupId: 'group1',
              catalogDeviceId: const Value('discard'),
              nameSnapshot: 'Device discard',
              quantity: 1,
              createdAt: past,
              updatedAt: past,
            ),
          );

      await service.merge(keepDeviceId: 'keep', discardDeviceId: 'discard');

      final item = await (database.select(
        database.projectItems,
      )..where((row) => row.id.equals('item1'))).getSingle();
      expect(item.updatedAt.isAfter(past), isTrue);
    },
  );

  test('copies the discarded device\'s gdtf/gremium linkage onto the kept '
      'device when the kept device has none', () async {
    await insertDevice(
      'keep',
      gdtfFixtureTypeId: null,
      gremiumInventoryItemId: null,
    );
    await insertDevice(
      'discard',
      gdtfFixtureTypeId: 'gdtf-123',
      gremiumInventoryItemId: 'gremium-456',
    );

    await service.merge(keepDeviceId: 'keep', discardDeviceId: 'discard');

    final keptDevice = await (database.select(
      database.catalogDevices,
    )..where((row) => row.id.equals('keep'))).getSingle();
    expect(keptDevice.gdtfFixtureTypeId, 'gdtf-123');
    expect(keptDevice.gremiumInventoryItemId, 'gremium-456');
  });

  test(
    'does not overwrite the kept device\'s own gdtf/gremium linkage',
    () async {
      await insertDevice('keep', gdtfFixtureTypeId: 'gdtf-keep');
      await insertDevice('discard', gdtfFixtureTypeId: 'gdtf-discard');

      await service.merge(keepDeviceId: 'keep', discardDeviceId: 'discard');

      final keptDevice = await (database.select(
        database.catalogDevices,
      )..where((row) => row.id.equals('keep'))).getSingle();
      expect(keptDevice.gdtfFixtureTypeId, 'gdtf-keep');
    },
  );
}
