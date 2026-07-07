import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();
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
  TextColumn get connectorTypeId => text().nullable()();
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

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().withDefault(const Constant('local'))();
  TextColumn get remoteId => text().nullable()();
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

@DriftDatabase(
  tables: [
    Projects,
    ProjectGroups,
    ProjectItems,
    ProjectDistros,
    ProjectOutlets,
    PowerConnections,
    ProjectTrusses,
    CatalogDevices,
    Clients,
    Locations,
    LocationPowerConnectors,
    LocationContacts,
    PowerPresets,
    PowerOutletTemplates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 9;

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
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'stagecalc.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
