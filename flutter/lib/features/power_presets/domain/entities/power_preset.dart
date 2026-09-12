import '../../../../shared/models/offline_sync_status.dart';
import '../../../projects/domain/entities/power_models.dart';

class PowerPreset {
  const PowerPreset({
    required this.id,
    required this.name,
    required this.outlets,
    required this.createdAt,
    required this.updatedAt,
    this.inputConnectorTypeId,
    this.notes,
    this.syncStatus = OfflineSyncStatus.localOnly,
  });

  final String id;
  final String name;
  final String? inputConnectorTypeId;
  final String? notes;
  final List<PowerOutletTemplate> outlets;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OfflineSyncStatus syncStatus;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'inputConnectorTypeId': inputConnectorTypeId,
      'notes': notes,
      'outlets': outlets.map((outlet) => outlet.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.toJson(),
    };
  }

  static PowerPreset fromJson(Map<String, Object?> json) {
    final outletsJson = json['outlets'] as List<Object?>? ?? const [];

    return PowerPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      inputConnectorTypeId: json['inputConnectorTypeId'] as String?,
      notes: json['notes'] as String?,
      outlets: outletsJson
          .whereType<Map>()
          .map(
            (outlet) =>
                PowerOutletTemplate.fromJson(Map<String, Object?>.from(outlet)),
          )
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncStatus: OfflineSyncStatusJson.fromJson(json['syncStatus'] as String?),
    );
  }
}

class PowerOutletTemplate {
  const PowerOutletTemplate({
    required this.id,
    required this.name,
    required this.connectorTypeId,
    required this.phase,
  });

  final String id;
  final String name;
  final String connectorTypeId;
  final PowerPhase phase;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'connectorTypeId': connectorTypeId,
      'phase': phase.toJson(),
    };
  }

  static PowerOutletTemplate fromJson(Map<String, Object?> json) {
    return PowerOutletTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      connectorTypeId: json['connectorTypeId'] as String,
      phase: PowerPhaseJson.fromJson(json['phase'] as String?),
    );
  }
}
