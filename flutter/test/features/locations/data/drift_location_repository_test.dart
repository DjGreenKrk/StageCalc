import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/locations/data/drift_location_repository.dart';
import 'package:stagecalc/features/locations/domain/entities/location.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;

void main() {
  late db.AppDatabase database;
  late DriftLocationRepository repository;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftLocationRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('saves, loads, and soft deletes locations from sqlite', () async {
    final now = DateTime(2026, 7, 5);
    const locationId = 'location_sqlite';

    await repository.saveLocation(
      Location(
        id: locationId,
        name: 'Hala Testowa',
        address: 'Warszawa',
        capacity: 1200,
        contactName: 'Technik obiektu',
        contactPhone: '+48 111 111 111',
        contacts: [
          LocationContact(
            id: 'contact_manager',
            role: 'Manager',
            name: 'Anna Manager',
            phone: '+48 222 222 222',
            email: 'manager@example.com',
            createdAt: now,
            updatedAt: now,
          ),
          LocationContact(
            id: 'contact_tech',
            role: 'Techniczny',
            name: 'Technik obiektu',
            phone: '+48 111 111 111',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        powerConnectors: [
          LocationPowerConnector(
            id: 'connector_sqlite',
            name: 'Scena',
            entries: const [
              LocationConnectorEntry(
                connectorTypeId: 'cee_32a_5p',
                quantity: 2,
              ),
              LocationConnectorEntry(
                connectorTypeId: 'schuko_16a',
                quantity: 4,
              ),
            ],
            createdAt: now,
            updatedAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
    );

    final locations = await repository.getLocations();
    final location = locations.singleWhere((item) => item.id == locationId);

    expect(location.name, 'Hala Testowa');
    expect(location.capacity, 1200);
    expect(location.contacts, hasLength(2));
    expect(location.contacts.first.role, 'Manager');
    expect(location.contacts.last.name, 'Technik obiektu');
    expect(location.powerConnectors.single.name, 'Scena');
    expect(location.powerConnectors.single.entries, hasLength(2));
    expect(
      location.powerConnectors.single.entries.first.connectorTypeId,
      'cee_32a_5p',
    );
    expect(
      location.powerConnectors.single.entries.last.connectorTypeId,
      'schuko_16a',
    );
    expect(location.totalAvailablePowerKw, closeTo(59.1, 0.1));

    await repository.deleteLocation(locationId);
    final locationsAfterDelete = await repository.getLocations();

    expect(locationsAfterDelete.any((item) => item.id == locationId), isFalse);
  });
}
