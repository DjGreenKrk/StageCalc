import 'package:drift/drift.dart';

import '../../../../infrastructure/local_database/app_database.dart' as db;
import '../../data/drift_catalog_repository.dart';

/// Repoints every project reference away from a duplicate catalog device
/// before deleting it, so merging two accidentally-duplicated devices
/// (ADR-038) never silently orphans a project.
///
/// Deliberately takes `AppDatabase` directly instead of going through
/// `CatalogRepository`/a project repository - the repoint-then-delete has to
/// happen in one transaction across tables that belong to two different
/// features (`catalog` and `projects`), the same kind of cross-feature reach
/// the sync services under `infrastructure/sync/` already do when an
/// operation genuinely needs it.
class CatalogDuplicateMergeService {
  const CatalogDuplicateMergeService(this._database);

  final db.AppDatabase _database;

  Future<void> merge({
    required String keepDeviceId,
    required String discardDeviceId,
  }) async {
    await _database.transaction(() async {
      final now = DateTime.now();

      await (_database.update(
        _database.projectItems,
      )..where((row) => row.catalogDeviceId.equals(discardDeviceId))).write(
        db.ProjectItemsCompanion(
          catalogDeviceId: Value(keepDeviceId),
          updatedAt: Value(now),
        ),
      );

      await (_database.update(
        _database.projectDistros,
      )..where((row) => row.catalogDeviceId.equals(discardDeviceId))).write(
        db.ProjectDistrosCompanion(
          catalogDeviceId: Value(keepDeviceId),
          updatedAt: Value(now),
        ),
      );

      await (_database.update(
        _database.projectGroupHookAssignments,
      )..where((row) => row.hookCatalogDeviceId.equals(discardDeviceId))).write(
        db.ProjectGroupHookAssignmentsCompanion(
          hookCatalogDeviceId: Value(keepDeviceId),
          updatedAt: Value(now),
        ),
      );

      await (_database.update(_database.projectTrusses)
            ..where((row) => row.trussCatalogDeviceId.equals(discardDeviceId)))
          .write(
            db.ProjectTrussesCompanion(
              trussCatalogDeviceId: Value(keepDeviceId),
              updatedAt: Value(now),
            ),
          );

      await _copyImportLinkageIfMissing(
        keepDeviceId: keepDeviceId,
        discardDeviceId: discardDeviceId,
        now: now,
      );

      await DriftCatalogRepository(_database).deleteDevice(discardDeviceId);
    });
  }

  /// If the kept device has no `gdtfFixtureTypeId`/`gremiumInventoryItemId`
  /// but the discarded one does, carries it over before the discarded row
  /// disappears. Without this, a discarded duplicate that happened to come
  /// from a GDTF/Gremium import would take its import linkage down with it -
  /// a future re-import of the same file would then fail to recognize the
  /// kept device (`GdtfCatalogMatcher`/`GremiumCatalogMatcher` match by that
  /// id) and create a brand-new device instead, regenerating the exact kind
  /// of duplicate this feature exists to fix.
  Future<void> _copyImportLinkageIfMissing({
    required String keepDeviceId,
    required String discardDeviceId,
    required DateTime now,
  }) async {
    final keepRow = await (_database.select(
      _database.catalogDevices,
    )..where((row) => row.id.equals(keepDeviceId))).getSingle();
    final discardRow = await (_database.select(
      _database.catalogDevices,
    )..where((row) => row.id.equals(discardDeviceId))).getSingle();

    final gdtfFixtureTypeId =
        keepRow.gdtfFixtureTypeId ?? discardRow.gdtfFixtureTypeId;
    final gremiumInventoryItemId =
        keepRow.gremiumInventoryItemId ?? discardRow.gremiumInventoryItemId;

    if (gdtfFixtureTypeId == keepRow.gdtfFixtureTypeId &&
        gremiumInventoryItemId == keepRow.gremiumInventoryItemId) {
      return;
    }

    await (_database.update(
      _database.catalogDevices,
    )..where((row) => row.id.equals(keepDeviceId))).write(
      db.CatalogDevicesCompanion(
        gdtfFixtureTypeId: Value(gdtfFixtureTypeId),
        gremiumInventoryItemId: Value(gremiumInventoryItemId),
        updatedAt: Value(now),
      ),
    );
  }
}
