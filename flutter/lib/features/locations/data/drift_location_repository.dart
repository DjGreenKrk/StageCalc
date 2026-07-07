import 'package:drift/drift.dart';

import '../../../infrastructure/local_database/app_database.dart' as db;
import '../../../shared/models/offline_sync_status.dart';
import '../domain/entities/location.dart';
import 'location_repository.dart';

class DriftLocationRepository implements LocationRepository {
  const DriftLocationRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<List<Location>> getLocations() async {
    final rows =
        await (_database.select(_database.locations)
              ..where((row) => row.deletedAt.isNull())
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .get();

    final result = <Location>[];
    for (final row in rows) {
      final connectorRows = await _loadConnectorRows(row.id);
      final contactRows = await _loadContactRows(row.id);
      result.add(_mapLocation(row, connectorRows, contactRows));
    }

    return result;
  }

  @override
  Future<void> saveLocation(Location location) async {
    await _database.transaction(() async {
      await _database
          .into(_database.locations)
          .insertOnConflictUpdate(
            db.LocationsCompanion(
              id: Value(location.id),
              name: Value(location.name),
              address: Value(location.address),
              capacity: Value(location.capacity),
              contactName: Value(location.effectiveContacts.firstOrNull?.name),
              contactPhone: Value(
                location.effectiveContacts.firstOrNull?.phone,
              ),
              contactEmail: Value(
                location.effectiveContacts.firstOrNull?.email,
              ),
              notes: Value(location.notes),
              createdAt: Value(location.createdAt),
              updatedAt: Value(location.updatedAt),
              deletedAt: const Value(null),
              syncState: Value(location.syncStatus.toJson()),
            ),
          );

      final existingConnectors = await (_database.select(
        _database.locationPowerConnectors,
      )..where((row) => row.locationId.equals(location.id))).get();
      final connectorIds = location.powerConnectors
          .map((connector) => connector.id)
          .toSet();

      for (final existingConnector in existingConnectors) {
        if (!connectorIds.contains(existingConnector.id)) {
          await (_database.update(
            _database.locationPowerConnectors,
          )..where((row) => row.id.equals(existingConnector.id))).write(
            db.LocationPowerConnectorsCompanion(
              deletedAt: Value(location.updatedAt),
              updatedAt: Value(location.updatedAt),
            ),
          );
        }
      }

      for (final (index, connector) in location.powerConnectors.indexed) {
        await _database
            .into(_database.locationPowerConnectors)
            .insertOnConflictUpdate(
              db.LocationPowerConnectorsCompanion(
                id: Value(connector.id),
                locationId: Value(location.id),
                name: Value(connector.name),
                connectorTypeId: Value(connector.connectorTypeId),
                quantity: Value(connector.quantity),
                notes: Value(connector.notes),
                sortOrder: Value(index),
                createdAt: Value(connector.createdAt),
                updatedAt: Value(connector.updatedAt),
                deletedAt: const Value(null),
              ),
            );
      }

      final existingContacts = await (_database.select(
        _database.locationContacts,
      )..where((row) => row.locationId.equals(location.id))).get();
      final contactIds = location.contacts.map((contact) => contact.id).toSet();

      for (final existingContact in existingContacts) {
        if (!contactIds.contains(existingContact.id)) {
          await (_database.update(
            _database.locationContacts,
          )..where((row) => row.id.equals(existingContact.id))).write(
            db.LocationContactsCompanion(
              deletedAt: Value(location.updatedAt),
              updatedAt: Value(location.updatedAt),
            ),
          );
        }
      }

      for (final (index, contact) in location.contacts.indexed) {
        await _database
            .into(_database.locationContacts)
            .insertOnConflictUpdate(
              db.LocationContactsCompanion(
                id: Value(contact.id),
                locationId: Value(location.id),
                role: Value(contact.role),
                name: Value(contact.name),
                phone: Value(contact.phone),
                email: Value(contact.email),
                notes: Value(contact.notes),
                sortOrder: Value(index),
                createdAt: Value(contact.createdAt),
                updatedAt: Value(contact.updatedAt),
                deletedAt: const Value(null),
              ),
            );
      }
    });
  }

  @override
  Future<void> deleteLocation(String id) async {
    final now = DateTime.now();
    await (_database.update(
      _database.locations,
    )..where((row) => row.id.equals(id))).write(
      db.LocationsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Location _mapLocation(
    db.Location row,
    List<db.LocationPowerConnector> connectorRows,
    List<db.LocationContact> contactRows,
  ) {
    final contacts = contactRows.map(_mapContact).toList();
    return Location(
      id: row.id,
      name: row.name,
      address: row.address,
      capacity: row.capacity,
      contactName: row.contactName,
      contactPhone: row.contactPhone,
      contactEmail: row.contactEmail,
      notes: row.notes,
      powerConnectors: connectorRows.map(_mapConnector).toList(),
      contacts: contacts.isEmpty ? _legacyContacts(row) : contacts,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      syncStatus: OfflineSyncStatusJson.fromJson(row.syncState),
    );
  }

  Future<List<db.LocationPowerConnector>> _loadConnectorRows(
    String locationId,
  ) {
    return (_database.select(_database.locationPowerConnectors)
          ..where(
            (connector) =>
                connector.locationId.equals(locationId) &
                connector.deletedAt.isNull(),
          )
          ..orderBy([(connector) => OrderingTerm.asc(connector.sortOrder)]))
        .get();
  }

  Future<List<db.LocationContact>> _loadContactRows(String locationId) {
    return (_database.select(_database.locationContacts)
          ..where(
            (contact) =>
                contact.locationId.equals(locationId) &
                contact.deletedAt.isNull(),
          )
          ..orderBy([(contact) => OrderingTerm.asc(contact.sortOrder)]))
        .get();
  }

  LocationPowerConnector _mapConnector(db.LocationPowerConnector row) {
    return LocationPowerConnector(
      id: row.id,
      name: row.name,
      connectorTypeId: row.connectorTypeId,
      quantity: row.quantity,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  LocationContact _mapContact(db.LocationContact row) {
    return LocationContact(
      id: row.id,
      role: row.role,
      name: row.name,
      phone: row.phone,
      email: row.email,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  List<LocationContact> _legacyContacts(db.Location row) {
    if ((row.contactName ?? '').trim().isEmpty &&
        (row.contactPhone ?? '').trim().isEmpty &&
        (row.contactEmail ?? '').trim().isEmpty) {
      return const [];
    }

    return [
      LocationContact(
        id: 'legacy_contact_${row.id}',
        role: 'Kontakt',
        name: row.contactName ?? 'Kontakt',
        phone: row.contactPhone,
        email: row.contactEmail,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      ),
    ];
  }
}
