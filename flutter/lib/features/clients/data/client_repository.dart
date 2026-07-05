import '../domain/entities/client.dart';

abstract interface class ClientRepository {
  Future<List<Client>> getClients();

  Future<void> saveClient(Client client);

  Future<void> deleteClient(String id);
}
