import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart';

import 'connection/connection.dart';

part 'app_database.g.dart';

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();

  /// PocketBase `users` record id of whoever owns this project (ADR-028) -
  /// see `Clients.ownerId` for why this is not a "local id".
  TextColumn get ownerId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get phaseId => text().withDefault(const Constant('default'))();
  TextColumn get clientId => text().nullable()();
  TextColumn get locationId => text().nullable()();

  /// `project.id` from a Gremium Panel pack-list export this project is
  /// linked to (ADR-034) - `null` for every project not imported from
  /// Gremium.
  TextColumn get gremiumProjectId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProjectGroups extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get phaseId => text().withDefault(const Constant('default'))();
  TextColumn get name => text()();
  TextColumn get powerProfile =>
      text().withDefault(const Constant('singlePhase'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProjectItems extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get groupId => text().references(ProjectGroups, #id)();
  TextColumn get phaseId => text().withDefault(const Constant('default'))();
  TextColumn get catalogDeviceId => text().nullable()();
  TextColumn get nameSnapshot => text()();
  TextColumn get manufacturerSnapshot => text().nullable()();
  RealColumn get quantity => real()();
  RealColumn get powerWSnapshot => real().withDefault(const Constant(0))();
  RealColumn get currentASnapshot => real().withDefault(const Constant(0))();
  RealColumn get weightKgSnapshot => real().withDefault(const Constant(0))();
  IntColumn get riggingPointsSnapshot => integer().nullable()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();

  /// `lineId` from a Gremium Panel pack-list export this item was created
  /// or last refreshed from (ADR-034) - `null` for every item added
  /// manually.
  TextColumn get gremiumLineId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProjectGroupHookAssignments extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get groupId => text().references(ProjectGroups, #id)();
  TextColumn get hookCatalogDeviceId => text().nullable()();
  TextColumn get hookNameSnapshot => text()();
  RealColumn get hookWeightKgSnapshot =>
      real().withDefault(const Constant(0))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProjectDistros extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get phaseId => text().withDefault(const Constant('default'))();
  TextColumn get name => text()();
  TextColumn get sourceType => text().withDefault(const Constant('preset'))();
  TextColumn get catalogDeviceId => text().nullable()();
  TextColumn get locationConnectorGroupId => text().nullable()();
  TextColumn get presetId => text().nullable()();
  TextColumn get inputConnectorTypeId => text().nullable()();
  BoolColumn get isRootPowerSource =>
      boolean().withDefault(const Constant(false))();
  RealColumn get manualInputMaxCurrentA => real().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProjectOutlets extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get distroId => text().references(ProjectDistros, #id)();
  TextColumn get phaseId => text().withDefault(const Constant('default'))();
  TextColumn get templateOutletId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get connectorTypeId => text()();
  TextColumn get phase => text().withDefault(const Constant('l1'))();
  RealColumn get maxCurrentA => real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PowerConnections extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get phaseId => text().withDefault(const Constant('default'))();
  TextColumn get sourceDistroId => text().references(ProjectDistros, #id)();
  TextColumn get sourceOutletId => text().references(ProjectOutlets, #id)();
  TextColumn get targetType => text().withDefault(const Constant('group'))();
  TextColumn get targetGroupId => text().nullable()();
  TextColumn get targetDistroId => text().nullable()();
  TextColumn get selectedPhasesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProjectTrusses extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get phaseId => text().withDefault(const Constant('default'))();
  TextColumn get name => text()();
  TextColumn get trussSystemId => text().nullable()();
  TextColumn get trussCatalogDeviceId => text().nullable()();
  RealColumn get lengthM => real().withDefault(const Constant(0))();
  RealColumn get maxTotalLoadKg => real().nullable()();
  RealColumn get maxDistributedLoadKgPerM => real().nullable()();
  RealColumn get manualLoadKg => real().withDefault(const Constant(0))();
  TextColumn get assignedGroupIdsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CatalogDevices extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('device'))();
  RealColumn get powerW => real().withDefault(const Constant(0))();
  RealColumn get currentA => real().withDefault(const Constant(0))();
  RealColumn get weightKg => real().withDefault(const Constant(0))();

  /// Superseded by [connectorTypeIdsJson] (multi-select connectors, see the
  /// "Wiele zlacz naraz" decision) - no longer written by the app, kept only
  /// so the schema-15 migration can read pre-existing values out of it.
  TextColumn get connectorTypeId => text().nullable()();

  /// JSON-encoded array of `CatalogConnectorType` ids, e.g. `["powerCon",
  /// "xlr5"]` - mirrors `PowerConnections.selectedPhasesJson`'s pattern of
  /// storing a Dart enum list as one text column.
  TextColumn get connectorTypeIdsJson =>
      text().withDefault(const Constant('[]'))();
  IntColumn get riggingPoints => integer().nullable()();
  TextColumn get quantityUnit => text().withDefault(const Constant('pcs'))();

  /// `inventoryItemId` from a Gremium Panel pack-list export this device is
  /// linked to (ADR-034) - `null` for every device added manually or not yet
  /// linked to a Gremium import item.
  TextColumn get gremiumInventoryItemId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TrussLoadChartEntries extends Table {
  TextColumn get id => text()();
  TextColumn get catalogDeviceId => text().references(CatalogDevices, #id)();
  RealColumn get lengthM => real()();
  RealColumn get pointLoadKg => real()();
  RealColumn get distributedLoadKgPerM => real()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();

  /// PocketBase `users` record id of whoever owns this client (ADR-028) -
  /// clients are private per-user, not shared like the catalog/locations.
  /// Not a "local id" needing translation like every other cross-reference
  /// in this schema: `users` records only ever exist remotely, so this is
  /// already the id to push straight into the `owner` relation.
  TextColumn get ownerId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get nip => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Locations extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  IntColumn get capacity => integer().nullable()();
  TextColumn get contactName => text().nullable()();
  TextColumn get contactPhone => text().nullable()();
  TextColumn get contactEmail => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocationPowerConnectors extends Table {
  TextColumn get id => text()();
  TextColumn get locationId => text().references(Locations, #id)();
  TextColumn get name => text()();

  /// Superseded by [entriesJson] (a group can now mix several connector
  /// types, see ADR-032) - the app always writes the group's first entry
  /// here too, purely so this still-`NOT NULL` column stays satisfied; reads
  /// go through [entriesJson] instead.
  TextColumn get connectorTypeId => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  /// JSON-encoded array of `{connectorTypeId, quantity}` objects - mirrors
  /// `CatalogDevices.connectorTypeIdsJson`'s pattern of storing a list in one
  /// text column instead of a child table.
  TextColumn get entriesJson => text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocationContacts extends Table {
  TextColumn get id => text()();
  TextColumn get locationId => text().references(Locations, #id)();
  TextColumn get role => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PowerPresets extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get inputConnectorTypeId => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PowerOutletTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get presetId => text().references(PowerPresets, #id)();
  TextColumn get name => text()();
  TextColumn get connectorTypeId => text()();
  TextColumn get phase => text().withDefault(const Constant('l1'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('localOnly'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A single settings row (`id = 'app'`), instead of a generic key-value
/// store - ADR-011 already rejected `shared_preferences` in favour of an
/// explicit relational schema, and this app only has one setting so far.
class AppSettings extends Table {
  TextColumn get id => text()();
  BoolColumn get autoSyncEnabled =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  /// Raw JSON blob `package:pocketbase`'s own `AsyncAuthStore` manages
  /// (ADR-028) - token plus the logged-in user's full record - so the user
  /// does not have to log in again every app start. Stored as one opaque
  /// column rather than separate token/id/email columns: `AsyncAuthStore`
  /// already owns the encoding, and the live `authStore` (not this column)
  /// is the source of truth for "who is logged in" while the app is running.
  TextColumn get authSessionData => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Projects,
    ProjectGroups,
    ProjectItems,
    ProjectGroupHookAssignments,
    ProjectDistros,
    ProjectOutlets,
    PowerConnections,
    ProjectTrusses,
    CatalogDevices,
    TrussLoadChartEntries,
    Clients,
    Locations,
    LocationPowerConnectors,
    LocationContacts,
    PowerPresets,
    PowerOutletTemplates,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(connect());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 17;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await _createTableIfMissing(migrator, clients);
        await _createTableIfMissing(migrator, locations);
      }
      if (from < 3) {
        await _addColumnIfMissing(migrator, projects, projects.clientId);
        await _addColumnIfMissing(migrator, projects, projects.locationId);
      }
      if (from < 4) {
        await _createTableIfMissing(migrator, powerPresets);
        await _createTableIfMissing(migrator, powerOutletTemplates);
      }
      if (from < 5) {
        await _createTableIfMissing(migrator, projectDistros);
        await _createTableIfMissing(migrator, projectOutlets);
      }
      if (from < 6) {
        await _createTableIfMissing(migrator, powerConnections);
      }
      if (from < 7) {
        await _createTableIfMissing(migrator, projectTrusses);
      }
      if (from < 8) {
        await _createTableIfMissing(migrator, locationPowerConnectors);
      }
      if (from < 9) {
        await _createTableIfMissing(migrator, locationContacts);
      }
      if (from < 10) {
        await _addColumnIfMissing(
          migrator,
          projectDistros,
          projectDistros.manualInputMaxCurrentA,
        );
      }
      if (from < 11) {
        await _addColumnIfMissing(
          migrator,
          catalogDevices,
          catalogDevices.riggingPoints,
        );
        await _addColumnIfMissing(
          migrator,
          projectItems,
          projectItems.riggingPointsSnapshot,
        );
        await _createTableIfMissing(migrator, projectGroupHookAssignments);
      }
      if (from < 12) {
        await _addColumnIfMissing(
          migrator,
          projectTrusses,
          projectTrusses.trussCatalogDeviceId,
        );
        await _createTableIfMissing(migrator, trussLoadChartEntries);
      }
      if (from < 13) {
        await _createTableIfMissing(migrator, appSettings);
      }
      if (from < 14) {
        await _addColumnIfMissing(migrator, clients, clients.ownerId);
        await _addColumnIfMissing(migrator, projects, projects.ownerId);
        await _addColumnIfMissing(
          migrator,
          appSettings,
          appSettings.authSessionData,
        );
      }
      if (from < 15) {
        await _addColumnIfMissing(
          migrator,
          catalogDevices,
          catalogDevices.connectorTypeIdsJson,
        );
        // Carries each device's old single free-text connector value
        // forward as a one-item JSON array, verbatim - `CatalogDevice`'s
        // `CatalogConnectorTypeJson.decodeStoredList` (not this
        // domain-agnostic schema file) is what turns that raw text into a
        // real `CatalogConnectorType`, dropping it if it does not match any
        // known id or alias.
        final rows = await select(catalogDevices).get();
        for (final row in rows) {
          final legacy = row.connectorTypeId;
          if (legacy == null || legacy.trim().isEmpty) {
            continue;
          }
          await (update(
            catalogDevices,
          )..where((table) => table.id.equals(row.id))).write(
            CatalogDevicesCompanion(
              connectorTypeIdsJson: Value(jsonEncode([legacy])),
            ),
          );
        }
      }
      if (from < 16) {
        await _addColumnIfMissing(
          migrator,
          locationPowerConnectors,
          locationPowerConnectors.entriesJson,
        );
        // Carries each existing group's single connector+quantity forward
        // as a one-entry JSON array - `LocationPowerConnector.fromJson`/the
        // repository mapper reads `entriesJson` as the source of truth, so
        // without this every group saved before ADR-032 would appear to
        // have lost its connector after the upgrade.
        final connectorRows = await select(locationPowerConnectors).get();
        for (final row in connectorRows) {
          final legacy = row.connectorTypeId;
          if (legacy.trim().isEmpty) {
            continue;
          }
          await (update(
            locationPowerConnectors,
          )..where((table) => table.id.equals(row.id))).write(
            LocationPowerConnectorsCompanion(
              entriesJson: Value(
                jsonEncode([
                  {'connectorTypeId': legacy, 'quantity': row.quantity},
                ]),
              ),
            ),
          );
        }
      }
      if (from < 17) {
        // Nullable columns for linking a native record to the Gremium Panel
        // item it was imported from or manually matched to (ADR-034) - no
        // backfill needed, every pre-existing row simply stays unlinked.
        await _addColumnIfMissing(
          migrator,
          catalogDevices,
          catalogDevices.gremiumInventoryItemId,
        );
        await _addColumnIfMissing(
          migrator,
          projects,
          projects.gremiumProjectId,
        );
        await _addColumnIfMissing(
          migrator,
          projectItems,
          projectItems.gremiumLineId,
        );
      }
    },
  );

  /// Makes `migrator.createTable` idempotent: swallows the "table already
  /// exists" failure instead of letting the whole migration (and every
  /// screen's data load that shares this one database) fail because some
  /// earlier run of this exact step already got applied to the actual file,
  /// without the tracked schema version (`PRAGMA user_version`) reflecting
  /// that - which is exactly what happened in practice (see the matching
  /// `_addColumnIfMissing` doc comment).
  Future<void> _createTableIfMissing(Migrator migrator, TableInfo table) async {
    try {
      await migrator.createTable(table);
    } catch (error) {
      if (!_isAlreadyAppliedError(error, 'already exists')) {
        rethrow;
      }
    }
  }

  /// Makes `migrator.addColumn` idempotent: swallows the "duplicate column
  /// name" failure instead of letting the whole migration fail.
  ///
  /// Without this, a user hit exactly this on a real device: `ADD COLUMN
  /// "rigging_points"` failed with `SqliteException: duplicate column name:
  /// rigging_points` even though `from < 11` (the guard around that step)
  /// was true - the column physically already existed in their database
  /// file, but its tracked schema version had not been bumped past 10. That
  /// single thrown exception, since every screen's initial data load reads
  /// from this same shared database, broke every "Dodaj" action app-wide
  /// (`_repository` never got set - see `ClientsScreen._ensureRepository`
  /// and its counterparts) with no clear error shown anywhere until this
  /// exact exception was captured and reported. The exact mechanism that
  /// desynced the version from the columns wasn't identified, but the fix
  /// does not depend on knowing it: a migration step that turns out to
  /// already be applied should just be skipped, not fail the whole
  /// migration outright.
  Future<void> _addColumnIfMissing(
    Migrator migrator,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    try {
      await migrator.addColumn(table, column);
    } catch (error) {
      if (!_isAlreadyAppliedError(error, 'duplicate column name')) {
        rethrow;
      }
    }
  }

  /// `NativeDatabase.createInBackground` (used on native platforms, see
  /// `connection_native.dart`) runs every query in a background isolate and
  /// wraps *any* error crossing that boundary in a [DriftRemoteException] -
  /// `catch (error) on SqliteException` never matches, because the object
  /// the future actually completes with is the wrapper, not the original
  /// [SqliteException]. This was found the hard way: the first version of
  /// this idempotency fix used `on SqliteException catch` and, verified live
  /// against a real build, did not actually catch anything - the exact same
  /// crash still happened. Matching on the message text of whatever was
  /// thrown (`error.toString()` already reliably contains it either way,
  /// wrapped or not - see [DriftRemoteException.toString]) sidesteps needing
  /// to know or match the exact wrapper type at all.
  bool _isAlreadyAppliedError(Object error, String needle) {
    return error.toString().contains(needle);
  }
}
