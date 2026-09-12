import '../../../../shared/models/offline_sync_status.dart';

class CatalogDevice {
  const CatalogDevice({
    required this.id,
    required this.name,
    required this.quantityUnit,
    required this.createdAt,
    required this.updatedAt,
    this.manufacturer,
    this.category = CatalogDeviceCategory.device,
    this.powerW = 0,
    this.currentA = 0,
    this.weightKg = 0,
    this.connectorTypeId,
    this.riggingPoints,
    this.loadChart = const [],
    this.syncStatus = OfflineSyncStatus.localOnly,
  });

  final String id;
  final String name;
  final String? manufacturer;
  final CatalogDeviceCategory category;
  final double powerW;
  final double currentA;
  final double weightKg;
  final String? connectorTypeId;

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

  CatalogDevice copyWith({
    String? id,
    String? name,
    String? manufacturer,
    CatalogDeviceCategory? category,
    double? powerW,
    double? currentA,
    double? weightKg,
    String? connectorTypeId,
    int? riggingPoints,
    List<TrussLoadChartEntry>? loadChart,
    CatalogQuantityUnit? quantityUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
    OfflineSyncStatus? syncStatus,
  }) {
    return CatalogDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      powerW: powerW ?? this.powerW,
      currentA: currentA ?? this.currentA,
      weightKg: weightKg ?? this.weightKg,
      connectorTypeId: connectorTypeId ?? this.connectorTypeId,
      riggingPoints: riggingPoints ?? this.riggingPoints,
      loadChart: loadChart ?? this.loadChart,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
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
      'connectorTypeId': connectorTypeId,
      'riggingPoints': riggingPoints,
      'loadChart': loadChart.map((entry) => entry.toJson()).toList(),
      'quantityUnit': quantityUnit.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.toJson(),
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
      connectorTypeId: json['connectorTypeId'] as String?,
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

enum CatalogDeviceCategory { device, distribution, cable, rigging, other }

extension CatalogDeviceCategoryJson on CatalogDeviceCategory {
  String toJson() => name;

  static CatalogDeviceCategory fromJson(String? value) {
    return CatalogDeviceCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => CatalogDeviceCategory.device,
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
