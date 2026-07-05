import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/clients/data/drift_client_repository.dart';
import 'package:stagecalc/features/clients/domain/entities/client.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;

void main() {
  late db.AppDatabase database;
  late DriftClientRepository repository;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftClientRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('saves, loads, and soft deletes clients from sqlite', () async {
    final now = DateTime(2026, 7, 5);
    const clientId = 'client_sqlite';

    await repository.saveClient(
      Client(
        id: clientId,
        name: 'GreenCrew Event',
        contactPerson: 'Julian',
        email: 'event@example.com',
        phone: '+48 000 000 000',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final clients = await repository.getClients();
    final client = clients.singleWhere((item) => item.id == clientId);

    expect(client.name, 'GreenCrew Event');
    expect(client.contactPerson, 'Julian');

    await repository.deleteClient(clientId);
    final clientsAfterDelete = await repository.getClients();

    expect(clientsAfterDelete.any((item) => item.id == clientId), isFalse);
  });
}
