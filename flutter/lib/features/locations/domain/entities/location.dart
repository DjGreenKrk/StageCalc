import '../../../../shared/models/offline_sync_status.dart';
import '../../../projects/domain/entities/power_models.dart';

class Location {
  const Location({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.powerConnectors = const [],
    this.contacts = const [],
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
  final List<LocationPowerConnector> powerConnectors;
  final List<LocationContact> contacts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OfflineSyncStatus syncStatus;

  List<LocationContact> get effectiveContacts {
    if (contacts.isNotEmpty) {
      return contacts;
    }

    if ((contactName ?? '').trim().isEmpty &&
        (contactPhone ?? '').trim().isEmpty &&
        (contactEmail ?? '').trim().isEmpty) {
      return const [];
    }

    return [
      LocationContact(
        id: 'legacy_contact_$id',
        role: 'Kontakt',
        name: contactName ?? 'Kontakt',
        phone: contactPhone,
        email: contactEmail,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    ];
  }

  double get totalAvailablePowerKw {
    return powerConnectors.fold<double>(
      0,
      (sum, connector) => sum + connector.availablePowerKw,
    );
  }
}

class LocationContact {
  const LocationContact({
    required this.id,
    required this.role,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.email,
    this.notes,
  });

  final String id;
  final String role;
  final String name;
  final String? phone;
  final String? email;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class LocationPowerConnector {
  const LocationPowerConnector({
    required this.id,
    required this.name,
    required this.connectorTypeId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  final String id;
  final String name;
  final String connectorTypeId;
  final int quantity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PowerConnectorTypeDefinition? get connectorType {
    return ConnectorTypes.findById(connectorTypeId);
  }

  double get availablePowerKw {
    final type = connectorType;
    if (type == null) {
      return 0;
    }

    final wattsPerConnector = type.phaseCount == 3
        ? 400 * type.maxCurrentA * 1.732
        : 230 * type.maxCurrentA;
    return wattsPerConnector * quantity / 1000;
  }
}
