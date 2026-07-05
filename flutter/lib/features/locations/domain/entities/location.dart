import '../../../../shared/models/offline_sync_status.dart';

class Location {
  const Location({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.capacity,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.notes,
    this.syncStatus = OfflineSyncStatus.localOnly,
  });

  final String id;
  final String name;
  final String? address;
  final int? capacity;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OfflineSyncStatus syncStatus;
}
