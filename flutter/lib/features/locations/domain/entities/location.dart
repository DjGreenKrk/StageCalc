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

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'capacity': capacity,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'notes': notes,
      'powerConnectors': powerConnectors
          .map((connector) => connector.toJson())
          .toList(),
      'contacts': contacts.map((contact) => contact.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.toJson(),
    };
  }

  static Location fromJson(Map<String, Object?> json) {
    final powerConnectorsJson =
        json['powerConnectors'] as List<Object?>? ?? const [];
    final contactsJson = json['contacts'] as List<Object?>? ?? const [];

    return Location(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      capacity: json['capacity'] as int?,
      contactName: json['contactName'] as String?,
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
      notes: json['notes'] as String?,
      powerConnectors: powerConnectorsJson
          .whereType<Map>()
          .map(
            (connector) => LocationPowerConnector.fromJson(
              Map<String, Object?>.from(connector),
            ),
          )
          .toList(),
      contacts: contactsJson
          .whereType<Map>()
          .map(
            (contact) =>
                LocationContact.fromJson(Map<String, Object?>.from(contact)),
          )
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncStatus: OfflineSyncStatusJson.fromJson(json['syncStatus'] as String?),
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

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'role': role,
      'name': name,
      'phone': phone,
      'email': email,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static LocationContact fromJson(Map<String, Object?> json) {
    return LocationContact(
      id: json['id'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
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

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'connectorTypeId': connectorTypeId,
      'quantity': quantity,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static LocationPowerConnector fromJson(Map<String, Object?> json) {
    return LocationPowerConnector(
      id: json['id'] as String,
      name: json['name'] as String,
      connectorTypeId: json['connectorTypeId'] as String,
      quantity: json['quantity'] as int,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
