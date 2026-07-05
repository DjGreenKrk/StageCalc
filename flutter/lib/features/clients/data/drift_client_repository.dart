import 'package:drift/drift.dart';

import '../../../infrastructure/local_database/app_database.dart' as db;
import '../../../shared/models/offline_sync_status.dart';
import '../domain/entities/client.dart';
import 'client_repository.dart';

class DriftClientRepository implements ClientRepository {
  const DriftClientRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<List<Client>> getClients() async {
    final rows =
        await (_database.select(_database.clients)
              ..where((row) => row.deletedAt.isNull())
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .get();

    return rows.map(_mapClient).toList();
  }

  @override
  Future<void> saveClient(Client client) async {
    await _database
        .into(_database.clients)
        .insertOnConflictUpdate(
          db.ClientsCompanion(
            id: Value(client.id),
            name: Value(client.name),
            contactPerson: Value(client.contactPerson),
            email: Value(client.email),
            phone: Value(client.phone),
            address: Value(client.address),
            nip: Value(client.nip),
            notes: Value(client.notes),
            createdAt: Value(client.createdAt),
            updatedAt: Value(client.updatedAt),
            deletedAt: const Value(null),
            syncState: Value(client.syncStatus.toJson()),
          ),
        );
  }

  @override
  Future<void> deleteClient(String id) async {
    final now = DateTime.now();
    await (_database.update(
      _database.clients,
    )..where((row) => row.id.equals(id))).write(
      db.ClientsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Client _mapClient(db.Client row) {
    return Client(
      id: row.id,
      name: row.name,
      contactPerson: row.contactPerson,
      email: row.email,
      phone: row.phone,
      address: row.address,
      nip: row.nip,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      syncStatus: OfflineSyncStatusJson.fromJson(row.syncState),
    );
  }
}
