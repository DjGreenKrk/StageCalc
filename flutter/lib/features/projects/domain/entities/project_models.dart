import '../../../../shared/models/offline_sync_status.dart';
import 'power_models.dart';

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.groups,
    required this.createdAt,
    required this.updatedAt,
    this.phaseId = 'default',
    this.clientId,
    this.locationId,
    this.distros = const [],
    this.connections = const [],
    this.trusses = const [],
    this.syncStatus = OfflineSyncStatus.localOnly,
  });

  final String id;
  final String name;
  final String phaseId;
  final String? clientId;
  final String? locationId;
  final List<ProjectGroup> groups;
  final List<ProjectDistro> distros;
  final List<PowerConnection> connections;
  final List<ProjectTruss> trusses;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OfflineSyncStatus syncStatus;

  Project copyWith({
    String? id,
    String? name,
    String? phaseId,
    String? clientId,
    String? locationId,
    bool clearClientId = false,
    bool clearLocationId = false,
    List<ProjectGroup>? groups,
    List<ProjectDistro>? distros,
    List<PowerConnection>? connections,
    List<ProjectTruss>? trusses,
    DateTime? createdAt,
    DateTime? updatedAt,
    OfflineSyncStatus? syncStatus,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      phaseId: phaseId ?? this.phaseId,
      clientId: clearClientId ? null : clientId ?? this.clientId,
      locationId: clearLocationId ? null : locationId ?? this.locationId,
      groups: groups ?? this.groups,
      distros: distros ?? this.distros,
      connections: connections ?? this.connections,
      trusses: trusses ?? this.trusses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'phaseId': phaseId,
      'clientId': clientId,
      'locationId': locationId,
      'groups': groups.map((group) => group.toJson()).toList(),
      'distros': distros.map((distro) => distro.toJson()).toList(),
      'connections': connections
          .map((connection) => connection.toJson())
          .toList(),
      'trusses': trusses.map((truss) => truss.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.toJson(),
    };
  }

  static Project fromJson(Map<String, Object?> json) {
    final groupsJson = json['groups'] as List<Object?>? ?? const [];
    final distrosJson = json['distros'] as List<Object?>? ?? const [];
    final connectionsJson = json['connections'] as List<Object?>? ?? const [];
    final trussesJson = json['trusses'] as List<Object?>? ?? const [];

    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      phaseId: json['phaseId'] as String? ?? 'default',
      clientId: json['clientId'] as String?,
      locationId: json['locationId'] as String?,
      groups: groupsJson
          .whereType<Map>()
          .map(
            (group) => ProjectGroup.fromJson(Map<String, Object?>.from(group)),
          )
          .toList(),
      distros: distrosJson
          .whereType<Map>()
          .map(
            (distro) =>
                ProjectDistro.fromJson(Map<String, Object?>.from(distro)),
          )
          .toList(),
      connections: connectionsJson
          .whereType<Map>()
          .map(
            (connection) =>
                PowerConnection.fromJson(Map<String, Object?>.from(connection)),
          )
          .toList(),
      trusses: trussesJson
          .whereType<Map>()
          .map(
            (truss) => ProjectTruss.fromJson(Map<String, Object?>.from(truss)),
          )
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncStatus: OfflineSyncStatusJson.fromJson(json['syncStatus'] as String?),
    );
  }
}

class ProjectTruss {
  const ProjectTruss({
    required this.id,
    required this.name,
    this.phaseId = 'default',
    this.trussSystemId,
    this.lengthM = 0,
    this.maxTotalLoadKg,
    this.maxDistributedLoadKgPerM,
    this.manualLoadKg = 0,
    this.assignedGroupIds = const [],
    this.notes,
  });

  final String id;
  final String phaseId;
  final String name;
  final String? trussSystemId;
  final double lengthM;
  final double? maxTotalLoadKg;
  final double? maxDistributedLoadKgPerM;
  final double manualLoadKg;
  final List<String> assignedGroupIds;
  final String? notes;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'phaseId': phaseId,
      'name': name,
      'trussSystemId': trussSystemId,
      'lengthM': lengthM,
      'maxTotalLoadKg': maxTotalLoadKg,
      'maxDistributedLoadKgPerM': maxDistributedLoadKgPerM,
      'manualLoadKg': manualLoadKg,
      'assignedGroupIds': assignedGroupIds,
      'notes': notes,
    };
  }

  static ProjectTruss fromJson(Map<String, Object?> json) {
    final assignedGroupIdsJson =
        json['assignedGroupIds'] as List<Object?>? ?? const [];

    return ProjectTruss(
      id: json['id'] as String,
      phaseId: json['phaseId'] as String? ?? 'default',
      name: json['name'] as String,
      trussSystemId: json['trussSystemId'] as String?,
      lengthM: (json['lengthM'] as num? ?? 0).toDouble(),
      maxTotalLoadKg: (json['maxTotalLoadKg'] as num?)?.toDouble(),
      maxDistributedLoadKgPerM: (json['maxDistributedLoadKgPerM'] as num?)
          ?.toDouble(),
      manualLoadKg: (json['manualLoadKg'] as num? ?? 0).toDouble(),
      assignedGroupIds: assignedGroupIdsJson.whereType<String>().toList(),
      notes: json['notes'] as String?,
    );
  }
}

class PowerConnection {
  const PowerConnection({
    required this.id,
    required this.sourceDistroId,
    required this.sourceOutletId,
    required this.targetGroupId,
    this.phaseId = 'default',
    this.targetType = PowerConnectionTargetType.group,
    this.targetDistroId,
    this.selectedPhases = const [],
    this.notes,
  });

  final String id;
  final String phaseId;
  final String sourceDistroId;
  final String sourceOutletId;
  final PowerConnectionTargetType targetType;
  final String? targetGroupId;
  final String? targetDistroId;
  final List<PowerPhase> selectedPhases;
  final String? notes;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'phaseId': phaseId,
      'sourceDistroId': sourceDistroId,
      'sourceOutletId': sourceOutletId,
      'targetType': targetType.toJson(),
      'targetGroupId': targetGroupId,
      'targetDistroId': targetDistroId,
      'selectedPhases': selectedPhases.map((phase) => phase.toJson()).toList(),
      'notes': notes,
    };
  }

  static PowerConnection fromJson(Map<String, Object?> json) {
    final selectedPhasesJson =
        json['selectedPhases'] as List<Object?>? ?? const [];

    return PowerConnection(
      id: json['id'] as String,
      phaseId: json['phaseId'] as String? ?? 'default',
      sourceDistroId: json['sourceDistroId'] as String,
      sourceOutletId: json['sourceOutletId'] as String,
      targetType: PowerConnectionTargetTypeJson.fromJson(
        json['targetType'] as String?,
      ),
      targetGroupId: json['targetGroupId'] as String?,
      targetDistroId: json['targetDistroId'] as String?,
      selectedPhases: selectedPhasesJson
          .whereType<String>()
          .map(PowerPhaseJson.fromJson)
          .toList(),
      notes: json['notes'] as String?,
    );
  }
}

enum PowerConnectionTargetType { group, distro }

extension PowerConnectionTargetTypeJson on PowerConnectionTargetType {
  String toJson() => name;

  static PowerConnectionTargetType fromJson(String? value) {
    return PowerConnectionTargetType.values.firstWhere(
      (targetType) => targetType.name == value,
      orElse: () => PowerConnectionTargetType.group,
    );
  }
}

class ProjectDistro {
  const ProjectDistro({
    required this.id,
    required this.name,
    required this.outlets,
    this.phaseId = 'default',
    this.sourceType = ProjectDistroSourceType.preset,
    this.catalogDeviceId,
    this.locationConnectorGroupId,
    this.presetId,
    this.inputConnectorTypeId,
    this.isRootPowerSource = false,
  });

  final String id;
  final String phaseId;
  final String name;
  final ProjectDistroSourceType sourceType;
  final String? catalogDeviceId;
  final String? locationConnectorGroupId;
  final String? presetId;
  final String? inputConnectorTypeId;
  final bool isRootPowerSource;
  final List<ProjectOutlet> outlets;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'phaseId': phaseId,
      'name': name,
      'sourceType': sourceType.toJson(),
      'catalogDeviceId': catalogDeviceId,
      'locationConnectorGroupId': locationConnectorGroupId,
      'presetId': presetId,
      'inputConnectorTypeId': inputConnectorTypeId,
      'isRootPowerSource': isRootPowerSource,
      'outlets': outlets.map((outlet) => outlet.toJson()).toList(),
    };
  }

  static ProjectDistro fromJson(Map<String, Object?> json) {
    final outletsJson = json['outlets'] as List<Object?>? ?? const [];

    return ProjectDistro(
      id: json['id'] as String,
      phaseId: json['phaseId'] as String? ?? 'default',
      name: json['name'] as String,
      sourceType: ProjectDistroSourceTypeJson.fromJson(
        json['sourceType'] as String?,
      ),
      catalogDeviceId: json['catalogDeviceId'] as String?,
      locationConnectorGroupId: json['locationConnectorGroupId'] as String?,
      presetId: json['presetId'] as String?,
      inputConnectorTypeId: json['inputConnectorTypeId'] as String?,
      isRootPowerSource: json['isRootPowerSource'] as bool? ?? false,
      outlets: outletsJson
          .whereType<Map>()
          .map(
            (outlet) =>
                ProjectOutlet.fromJson(Map<String, Object?>.from(outlet)),
          )
          .toList(),
    );
  }
}

class ProjectOutlet {
  const ProjectOutlet({
    required this.id,
    required this.name,
    required this.connectorTypeId,
    required this.phase,
    required this.maxCurrentA,
    this.templateOutletId,
  });

  final String id;
  final String? templateOutletId;
  final String name;
  final String connectorTypeId;
  final PowerPhase phase;
  final double maxCurrentA;

  ProjectOutlet copyWith({
    String? id,
    String? templateOutletId,
    String? name,
    String? connectorTypeId,
    PowerPhase? phase,
    double? maxCurrentA,
  }) {
    return ProjectOutlet(
      id: id ?? this.id,
      templateOutletId: templateOutletId ?? this.templateOutletId,
      name: name ?? this.name,
      connectorTypeId: connectorTypeId ?? this.connectorTypeId,
      phase: phase ?? this.phase,
      maxCurrentA: maxCurrentA ?? this.maxCurrentA,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'templateOutletId': templateOutletId,
      'name': name,
      'connectorTypeId': connectorTypeId,
      'phase': phase.toJson(),
      'maxCurrentA': maxCurrentA,
    };
  }

  static ProjectOutlet fromJson(Map<String, Object?> json) {
    return ProjectOutlet(
      id: json['id'] as String,
      templateOutletId: json['templateOutletId'] as String?,
      name: json['name'] as String,
      connectorTypeId: json['connectorTypeId'] as String,
      phase: PowerPhaseJson.fromJson(json['phase'] as String?),
      maxCurrentA: (json['maxCurrentA'] as num? ?? 0).toDouble(),
    );
  }
}

enum ProjectDistroSourceType { location, catalogDevice, preset, quick, manual }

extension ProjectDistroSourceTypeJson on ProjectDistroSourceType {
  String toJson() => name;

  static ProjectDistroSourceType fromJson(String? value) {
    return ProjectDistroSourceType.values.firstWhere(
      (sourceType) => sourceType.name == value,
      orElse: () => ProjectDistroSourceType.preset,
    );
  }
}

class ProjectGroup {
  const ProjectGroup({
    required this.id,
    required this.name,
    required this.items,
    this.powerProfile = ProjectGroupPowerProfile.singlePhase,
  });

  final String id;
  final String name;
  final ProjectGroupPowerProfile powerProfile;
  final List<ProjectItem> items;

  ProjectGroup copyWith({
    String? id,
    String? name,
    ProjectGroupPowerProfile? powerProfile,
    List<ProjectItem>? items,
  }) {
    return ProjectGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      powerProfile: powerProfile ?? this.powerProfile,
      items: items ?? this.items,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'powerProfile': powerProfile.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  static ProjectGroup fromJson(Map<String, Object?> json) {
    final itemsJson = json['items'] as List<Object?>? ?? const [];

    return ProjectGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      powerProfile: ProjectGroupPowerProfileJson.fromJson(
        json['powerProfile'] as String?,
      ),
      items: itemsJson
          .whereType<Map>()
          .map((item) => ProjectItem.fromJson(Map<String, Object?>.from(item)))
          .toList(),
    );
  }
}

class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.nameSnapshot,
    required this.quantity,
    this.manufacturerSnapshot,
    this.catalogDeviceId,
    this.powerWSnapshot = 0,
    this.currentASnapshot = 0,
    this.weightKgSnapshot = 0,
    this.unit = ProjectItemUnit.pcs,
  });

  final String id;
  final String? catalogDeviceId;
  final String nameSnapshot;
  final String? manufacturerSnapshot;
  final double quantity;
  final double powerWSnapshot;
  final double currentASnapshot;
  final double weightKgSnapshot;
  final ProjectItemUnit unit;

  ProjectItem copyWith({
    String? id,
    String? catalogDeviceId,
    String? nameSnapshot,
    String? manufacturerSnapshot,
    double? quantity,
    double? powerWSnapshot,
    double? currentASnapshot,
    double? weightKgSnapshot,
    ProjectItemUnit? unit,
  }) {
    return ProjectItem(
      id: id ?? this.id,
      catalogDeviceId: catalogDeviceId ?? this.catalogDeviceId,
      nameSnapshot: nameSnapshot ?? this.nameSnapshot,
      manufacturerSnapshot: manufacturerSnapshot ?? this.manufacturerSnapshot,
      quantity: quantity ?? this.quantity,
      powerWSnapshot: powerWSnapshot ?? this.powerWSnapshot,
      currentASnapshot: currentASnapshot ?? this.currentASnapshot,
      weightKgSnapshot: weightKgSnapshot ?? this.weightKgSnapshot,
      unit: unit ?? this.unit,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'catalogDeviceId': catalogDeviceId,
      'nameSnapshot': nameSnapshot,
      'manufacturerSnapshot': manufacturerSnapshot,
      'quantity': quantity,
      'powerWSnapshot': powerWSnapshot,
      'currentASnapshot': currentASnapshot,
      'weightKgSnapshot': weightKgSnapshot,
      'unit': unit.toJson(),
    };
  }

  static ProjectItem fromJson(Map<String, Object?> json) {
    return ProjectItem(
      id: json['id'] as String,
      catalogDeviceId: json['catalogDeviceId'] as String?,
      nameSnapshot: json['nameSnapshot'] as String,
      manufacturerSnapshot: json['manufacturerSnapshot'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      powerWSnapshot: (json['powerWSnapshot'] as num? ?? 0).toDouble(),
      currentASnapshot: (json['currentASnapshot'] as num? ?? 0).toDouble(),
      weightKgSnapshot: (json['weightKgSnapshot'] as num? ?? 0).toDouble(),
      unit: ProjectItemUnitJson.fromJson(json['unit'] as String?),
    );
  }
}

enum ProjectItemUnit { pcs, meters }

extension ProjectItemUnitJson on ProjectItemUnit {
  String toJson() => name;

  static ProjectItemUnit fromJson(String? value) {
    return ProjectItemUnit.values.firstWhere(
      (unit) => unit.name == value,
      orElse: () => ProjectItemUnit.pcs,
    );
  }
}

class ProjectTotals {
  const ProjectTotals({
    required this.powerW,
    required this.currentA,
    required this.weightKg,
  });

  final double powerW;
  final double currentA;
  final double weightKg;

  double get powerKw => powerW / 1000;
}
