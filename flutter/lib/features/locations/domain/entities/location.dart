import 'dart:convert';

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

/// A "grupa zlaczy" (connector group) at a location - a named cluster of
/// power connectors (e.g. "Rozdzielnia sceny") that can mix several
/// different connector types at once (e.g. 2x CEE 32A 5P + 4x Schuko),
/// since a real venue distro rarely offers only one connector type.
class LocationPowerConnector {
  const LocationPowerConnector({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.entries = const [],
    this.notes,
  });

  final String id;
  final String name;
  final List<LocationConnectorEntry> entries;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get availablePowerKw {
    return entries.fold<double>(
      0,
      (sum, entry) => sum + entry.availablePowerKw,
    );
  }

  /// Human-readable summary of every entry, e.g. "2x 32 A CEE 5P + 4x 16 A
  /// Uni-Schuko" - used by every screen that lists this group instead of
  /// each duplicating the same join logic.
  String get entriesSummary {
    if (entries.isEmpty) {
      return 'Brak złącz';
    }
    return entries.map((entry) => entry.summaryLabel).join(' + ');
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static LocationPowerConnector fromJson(Map<String, Object?> json) {
    final entriesJson = json['entries'] as List<Object?>?;
    return LocationPowerConnector(
      id: json['id'] as String,
      name: json['name'] as String,
      entries: entriesJson != null
          ? entriesJson
                .whereType<Map>()
                .map(
                  (entry) => LocationConnectorEntry.fromJson(
                    Map<String, Object?>.from(entry),
                  ),
                )
                .toList()
          // Backup produced before connector groups supported multiple
          // entries (ADR-032) - carries the old single connectorTypeId
          // forward as a one-item list.
          : _legacyEntries(json),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static List<LocationConnectorEntry> _legacyEntries(
    Map<String, Object?> json,
  ) {
    final legacyType = json['connectorTypeId'] as String?;
    if (legacyType == null || legacyType.trim().isEmpty) {
      return const [];
    }
    return [
      LocationConnectorEntry(
        connectorTypeId: legacyType,
        quantity: json['quantity'] as int? ?? 1,
      ),
    ];
  }

  /// Decodes the raw string stored in the Drift/PocketBase text column: a
  /// JSON-encoded array of entries (current format), or - for a row/record
  /// not yet resynced since ADR-032, or a legacy remote record still on the
  /// single-connector `connector_type_id` text field - a bare connector-type
  /// id string, wrapped into a one-entry list using [legacyQuantity].
  static List<LocationConnectorEntry> decodeStoredList(
    String? raw, {
    int legacyQuantity = 1,
  }) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      decoded = null;
    }
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (entry) => LocationConnectorEntry.fromJson(
              Map<String, Object?>.from(entry),
            ),
          )
          .toList();
    }
    return [
      LocationConnectorEntry(connectorTypeId: raw, quantity: legacyQuantity),
    ];
  }

  static String encodeStoredList(List<LocationConnectorEntry> entries) {
    return jsonEncode(entries.map((entry) => entry.toJson()).toList());
  }
}

/// One connector type within a [LocationPowerConnector] group, e.g. "2x CEE
/// 32A 5P".
class LocationConnectorEntry {
  const LocationConnectorEntry({
    required this.connectorTypeId,
    required this.quantity,
  });

  final String connectorTypeId;
  final int quantity;

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

  String get summaryLabel {
    return '${quantity}x ${connectorType?.label ?? connectorTypeId}';
  }

  @override
  bool operator ==(Object other) {
    return other is LocationConnectorEntry &&
        other.connectorTypeId == connectorTypeId &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => Object.hash(connectorTypeId, quantity);

  Map<String, Object?> toJson() {
    return {'connectorTypeId': connectorTypeId, 'quantity': quantity};
  }

  static LocationConnectorEntry fromJson(Map<String, Object?> json) {
    return LocationConnectorEntry(
      connectorTypeId: json['connectorTypeId'] as String,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}
