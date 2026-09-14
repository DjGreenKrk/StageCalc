import 'dart:convert';

import '../../../../shared/models/offline_sync_status.dart';

class CatalogDevice {
  const CatalogDevice({
    required this.id,
    required this.name,
    required this.quantityUnit,
    required this.createdAt,
    required this.updatedAt,
    this.manufacturer,
    this.category = CatalogDeviceCategory.lighting,
    this.powerW = 0,
    this.currentA = 0,
    this.weightKg = 0,
    this.connectorTypeIds = const [],
    this.riggingPoints,
    this.loadChart = const [],
    this.syncStatus = OfflineSyncStatus.localOnly,
    this.gremiumInventoryItemId,
  });

  final String id;
  final String name;
  final String? manufacturer;
  final CatalogDeviceCategory category;
  final double powerW;
  final double currentA;
  final double weightKg;

  /// The connector(s) this device itself is fitted with (e.g. a fixture with
  /// a powerCON input and a 5-pin XLR DMX input) - a multi-select list from
  /// the fixed [CatalogConnectorType] set. Purely informational/inventory
  /// metadata today: nothing in the app's calculations reads this. Not to be
  /// confused with the separate, AC-mains-only `ConnectorTypes` registry
  /// used for project distro outlets.
  final List<CatalogConnectorType> connectorTypeIds;

  /// Number of rigging points (hook attachment points) this device needs
  /// when it hangs from a truss, e.g. a moving head with two eyebolts. Null
  /// means unknown/not applicable - most devices never need this.
  final int? riggingPoints;

  /// Manufacturer load capacity by span length, for a device that represents
  /// a truss model. Used by `TrussLoadService` to interpolate a length-aware
  /// point/distributed load limit instead of a flat, manually-entered one.
  /// Empty for every device that is not itself a truss.
  final List<TrussLoadChartEntry> loadChart;
  final CatalogQuantityUnit quantityUnit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OfflineSyncStatus syncStatus;

  /// `inventoryItemId` from a Gremium Panel pack-list export this device is
  /// linked to (see ADR-034) - `null` for every device added manually or not
  /// yet linked. Set either when the import creates a brand-new device, or
  /// when the user manually links an already-existing device to a Gremium
  /// import item instead of creating a duplicate.
  final String? gremiumInventoryItemId;

  CatalogDevice copyWith({
    String? id,
    String? name,
    String? manufacturer,
    CatalogDeviceCategory? category,
    double? powerW,
    double? currentA,
    double? weightKg,
    List<CatalogConnectorType>? connectorTypeIds,
    int? riggingPoints,
    List<TrussLoadChartEntry>? loadChart,
    CatalogQuantityUnit? quantityUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
    OfflineSyncStatus? syncStatus,
    String? gremiumInventoryItemId,
  }) {
    return CatalogDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      powerW: powerW ?? this.powerW,
      currentA: currentA ?? this.currentA,
      weightKg: weightKg ?? this.weightKg,
      connectorTypeIds: connectorTypeIds ?? this.connectorTypeIds,
      riggingPoints: riggingPoints ?? this.riggingPoints,
      loadChart: loadChart ?? this.loadChart,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      gremiumInventoryItemId:
          gremiumInventoryItemId ?? this.gremiumInventoryItemId,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'category': category.toJson(),
      'powerW': powerW,
      'currentA': currentA,
      'weightKg': weightKg,
      'connectorTypeIds': connectorTypeIds
          .map((type) => type.toJson())
          .toList(),
      'riggingPoints': riggingPoints,
      'loadChart': loadChart.map((entry) => entry.toJson()).toList(),
      'quantityUnit': quantityUnit.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.toJson(),
      'gremiumInventoryItemId': gremiumInventoryItemId,
    };
  }

  static CatalogDevice fromJson(Map<String, Object?> json) {
    final loadChartJson = json['loadChart'] as List<Object?>? ?? const [];

    return CatalogDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      manufacturer: json['manufacturer'] as String?,
      category: CatalogDeviceCategoryJson.fromJson(json['category'] as String?),
      powerW: (json['powerW'] as num? ?? 0).toDouble(),
      currentA: (json['currentA'] as num? ?? 0).toDouble(),
      weightKg: (json['weightKg'] as num? ?? 0).toDouble(),
      connectorTypeIds: CatalogConnectorTypeJson.fromJsonField(json),
      riggingPoints: (json['riggingPoints'] as num?)?.toInt(),
      loadChart: loadChartJson
          .whereType<Map>()
          .map(
            (entry) =>
                TrussLoadChartEntry.fromJson(Map<String, Object?>.from(entry)),
          )
          .toList(),
      quantityUnit: CatalogQuantityUnitJson.fromJson(
        json['quantityUnit'] as String?,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncStatus: OfflineSyncStatusJson.fromJson(json['syncStatus'] as String?),
      gremiumInventoryItemId: json['gremiumInventoryItemId'] as String?,
    );
  }
}

/// One manufacturer-published data point of a truss's load capacity at a
/// given span length - see `CatalogDevice.loadChart`.
class TrussLoadChartEntry {
  const TrussLoadChartEntry({
    required this.id,
    required this.lengthM,
    required this.pointLoadKg,
    required this.distributedLoadKgPerM,
  });

  final String id;
  final double lengthM;
  final double pointLoadKg;
  final double distributedLoadKgPerM;

  TrussLoadChartEntry copyWith({
    String? id,
    double? lengthM,
    double? pointLoadKg,
    double? distributedLoadKgPerM,
  }) {
    return TrussLoadChartEntry(
      id: id ?? this.id,
      lengthM: lengthM ?? this.lengthM,
      pointLoadKg: pointLoadKg ?? this.pointLoadKg,
      distributedLoadKgPerM:
          distributedLoadKgPerM ?? this.distributedLoadKgPerM,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'lengthM': lengthM,
      'pointLoadKg': pointLoadKg,
      'distributedLoadKgPerM': distributedLoadKgPerM,
    };
  }

  static TrussLoadChartEntry fromJson(Map<String, Object?> json) {
    return TrussLoadChartEntry(
      id: json['id'] as String,
      lengthM: (json['lengthM'] as num).toDouble(),
      pointLoadKg: (json['pointLoadKg'] as num).toDouble(),
      distributedLoadKgPerM: (json['distributedLoadKgPerM'] as num).toDouble(),
    );
  }
}

enum CatalogDeviceCategory {
  lighting,
  sound,
  multimedia,
  distribution,
  cable,
  rigging,
  other,
}

extension CatalogDeviceCategoryJson on CatalogDeviceCategory {
  String toJson() => name;

  /// Falls back to [CatalogDeviceCategory.other] for anything unrecognized,
  /// including the pre-this-decision `device` value (a general "device"
  /// bucket, replaced by the finer `lighting`/`sound`/`multimedia` split -
  /// existing devices saved with it still load fine, just re-bucketed as
  /// "Inne" until someone re-categorizes them).
  static CatalogDeviceCategory fromJson(String? value) {
    return CatalogDeviceCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => CatalogDeviceCategory.other,
    );
  }
}

enum CatalogQuantityUnit { pcs, meters }

extension CatalogQuantityUnitJson on CatalogQuantityUnit {
  String toJson() => name;

  static CatalogQuantityUnit fromJson(String? value) {
    return CatalogQuantityUnit.values.firstWhere(
      (unit) => unit.name == value,
      orElse: () => CatalogQuantityUnit.pcs,
    );
  }
}

/// Fixed, multi-select list of connectors a catalog device can be fitted
/// with (power AND signal connectors, since the catalog spans lighting,
/// sound, multimedia, cabling and rigging - not just power distribution).
enum CatalogConnectorType {
  schuko16a,
  cee16a3p,
  cee16a5p,
  cee32a3p,
  cee32a5p,
  cee63a5p,
  cee125a5p,
  powerlock200a,
  powerlock400a,
  powerCon,
  powerConTrue1,
  powerConTrue1Top,
  xlr3,
  xlr5,
  speakonNl4,
  speakonNl8,
  etherCon,
  bnc,
  jack63,
  rca,
  hdmi,
  sdi,
  usb,
  other,
}

extension CatalogConnectorTypeJson on CatalogConnectorType {
  String toJson() => name;

  String get label => switch (this) {
    CatalogConnectorType.schuko16a => '16 A Schuko',
    CatalogConnectorType.cee16a3p => '16 A CEE 3P',
    CatalogConnectorType.cee16a5p => '16 A CEE 5P',
    CatalogConnectorType.cee32a3p => '32 A CEE 3P',
    CatalogConnectorType.cee32a5p => '32 A CEE 5P',
    CatalogConnectorType.cee63a5p => '63 A CEE 5P',
    CatalogConnectorType.cee125a5p => '125 A CEE 5P',
    CatalogConnectorType.powerlock200a => 'Powerlock 200 A',
    CatalogConnectorType.powerlock400a => 'Powerlock 400 A',
    CatalogConnectorType.powerCon => 'powerCON',
    CatalogConnectorType.powerConTrue1 => 'powerCON TRUE1',
    CatalogConnectorType.powerConTrue1Top => 'powerCON TRUE1 TOP',
    CatalogConnectorType.xlr3 => 'XLR 3-pin',
    CatalogConnectorType.xlr5 => 'XLR 5-pin (DMX)',
    CatalogConnectorType.speakonNl4 => 'SpeakON NL4',
    CatalogConnectorType.speakonNl8 => 'SpeakON NL8',
    CatalogConnectorType.etherCon => 'EtherCON (RJ45)',
    CatalogConnectorType.bnc => 'BNC',
    CatalogConnectorType.jack63 => 'Jack 6.3 mm',
    CatalogConnectorType.rca => 'RCA (Cinch)',
    CatalogConnectorType.hdmi => 'HDMI',
    CatalogConnectorType.sdi => 'SDI',
    CatalogConnectorType.usb => 'USB',
    CatalogConnectorType.other => 'Inne',
  };

  /// Best-effort match of one raw stored/imported string to a connector
  /// type: an exact `name` match first, then a normalized (lowercase,
  /// letters/digits only) alias lookup so older free-text values (e.g. this
  /// field's pre-multi-select data, or a slightly-off value typed by hand)
  /// still resolve where reasonably possible. Returns null - dropped by
  /// callers, never guessed wrong - when nothing matches.
  static CatalogConnectorType? fromJson(String? value) {
    if (value == null) {
      return null;
    }
    for (final type in CatalogConnectorType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return _aliasesByNormalizedText[_normalize(value)];
  }

  /// Reads either the current `connectorTypeIds` array or, for a backup
  /// produced before the multi-select change, the old single
  /// `connectorTypeId` string field - wrapped into a one-item list via
  /// [fromJson]'s alias matching, or dropped if it does not resolve.
  static List<CatalogConnectorType> fromJsonField(Map<String, Object?> json) {
    final list = json['connectorTypeIds'] as List<Object?>?;
    if (list != null) {
      return list
          .whereType<String>()
          .map(fromJson)
          .whereType<CatalogConnectorType>()
          .toList();
    }
    final legacy = fromJson(json['connectorTypeId'] as String?);
    return legacy == null ? const [] : [legacy];
  }

  /// Decodes the raw string stored in the Drift/PocketBase text column,
  /// which is either a JSON-encoded array of ids (current format) or a bare
  /// legacy free-text value (pre-multi-select rows/records not yet
  /// resynced) - see `CatalogDevices.connectorTypeIdsJson` in
  /// `app_database.dart`.
  static List<CatalogConnectorType> decodeStoredList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    List<Object?> items;
    try {
      final decoded = jsonDecode(raw);
      items = decoded is List ? decoded : [raw];
    } on FormatException {
      items = [raw];
    }
    return items
        .whereType<String>()
        .map(fromJson)
        .whereType<CatalogConnectorType>()
        .toList();
  }

  static String encodeStoredList(List<CatalogConnectorType> types) {
    return jsonEncode(types.map((type) => type.name).toList());
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  }

  static const _aliasesByNormalizedText = <String, CatalogConnectorType>{
    'schuko': CatalogConnectorType.schuko16a,
    'schuko16a': CatalogConnectorType.schuko16a,
    '16aunischuko': CatalogConnectorType.schuko16a,
    'cee16a3p': CatalogConnectorType.cee16a3p,
    'cee16a5p': CatalogConnectorType.cee16a5p,
    'cee32a3p': CatalogConnectorType.cee32a3p,
    'cee32a5p': CatalogConnectorType.cee32a5p,
    'cee63a5p': CatalogConnectorType.cee63a5p,
    'cee125a5p': CatalogConnectorType.cee125a5p,
    'powerlock200a': CatalogConnectorType.powerlock200a,
    'powerlock400a': CatalogConnectorType.powerlock400a,
    'powercon': CatalogConnectorType.powerCon,
    'powercontrue1': CatalogConnectorType.powerConTrue1,
    'powercontrue1top': CatalogConnectorType.powerConTrue1Top,
    'xlr3': CatalogConnectorType.xlr3,
    'xlr5': CatalogConnectorType.xlr5,
    'dmx': CatalogConnectorType.xlr5,
    'dmx5': CatalogConnectorType.xlr5,
    'speakonnl4': CatalogConnectorType.speakonNl4,
    'nl4': CatalogConnectorType.speakonNl4,
    'speakonnl8': CatalogConnectorType.speakonNl8,
    'nl8': CatalogConnectorType.speakonNl8,
    'ethercon': CatalogConnectorType.etherCon,
    'rj45': CatalogConnectorType.etherCon,
    'bnc': CatalogConnectorType.bnc,
    'jack63': CatalogConnectorType.jack63,
    'jack': CatalogConnectorType.jack63,
    'trs': CatalogConnectorType.jack63,
    'rca': CatalogConnectorType.rca,
    'cinch': CatalogConnectorType.rca,
    'hdmi': CatalogConnectorType.hdmi,
    'sdi': CatalogConnectorType.sdi,
    'usb': CatalogConnectorType.usb,
  };
}
