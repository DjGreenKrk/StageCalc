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
      'quantityUnit': quantityUnit.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.toJson(),
    };
  }

  static CatalogDevice fromJson(Map<String, Object?> json) {
    return CatalogDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      manufacturer: json['manufacturer'] as String?,
      category: CatalogDeviceCategoryJson.fromJson(json['category'] as String?),
      powerW: (json['powerW'] as num? ?? 0).toDouble(),
      currentA: (json['currentA'] as num? ?? 0).toDouble(),
      weightKg: (json['weightKg'] as num? ?? 0).toDouble(),
      connectorTypeId: json['connectorTypeId'] as String?,
      quantityUnit: CatalogQuantityUnitJson.fromJson(
        json['quantityUnit'] as String?,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncStatus: OfflineSyncStatusJson.fromJson(json['syncStatus'] as String?),
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
