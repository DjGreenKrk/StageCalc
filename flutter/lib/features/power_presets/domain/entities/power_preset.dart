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
}
