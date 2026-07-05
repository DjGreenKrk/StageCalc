import '../../../../shared/models/offline_sync_status.dart';

class Client {
  const Client({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.nip,
    this.notes,
    this.syncStatus = OfflineSyncStatus.localOnly,
  });

  final String id;
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? nip;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OfflineSyncStatus syncStatus;
}
