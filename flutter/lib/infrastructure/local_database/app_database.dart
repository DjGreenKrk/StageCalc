import 'dart:convert';

import 'package:drift/drift.dart';

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
  TextColumn get connectorTypeId => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
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
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(clients);
        await migrator.createTable(locations);
      }
      if (from < 3) {
        await migrator.addColumn(projects, projects.clientId);
        await migrator.addColumn(projects, projects.locationId);
      }
      if (from < 4) {
        await migrator.createTable(powerPresets);
        await migrator.createTable(powerOutletTemplates);
      }
      if (from < 5) {
        await migrator.createTable(projectDistros);
        await migrator.createTable(projectOutlets);
      }
      if (from < 6) {
        await migrator.createTable(powerConnections);
      }
      if (from < 7) {
        await migrator.createTable(projectTrusses);
      }
      if (from < 8) {
        await migrator.createTable(locationPowerConnectors);
      }
      if (from < 9) {
        await migrator.createTable(locationContacts);
      }
      if (from < 10) {
        await migrator.addColumn(
          projectDistros,
          projectDistros.manualInputMaxCurrentA,
        );
      }
      if (from < 11) {
        await migrator.addColumn(catalogDevices, catalogDevices.riggingPoints);
        await migrator.addColumn(
          projectItems,
          projectItems.riggingPointsSnapshot,
        );
        await migrator.createTable(projectGroupHookAssignments);
      }
      if (from < 12) {
        await migrator.addColumn(
          projectTrusses,
          projectTrusses.trussCatalogDeviceId,
        );
        await migrator.createTable(trussLoadChartEntries);
      }
      if (from < 13) {
        await migrator.createTable(appSettings);
      }
      if (from < 14) {
        await migrator.addColumn(clients, clients.ownerId);
        await migrator.addColumn(projects, projects.ownerId);
        await migrator.addColumn(appSettings, appSettings.authSessionData);
      }
      if (from < 15) {
        await migrator.addColumn(
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
    },
  );
}
