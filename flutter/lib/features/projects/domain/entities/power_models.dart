enum PowerPhase { l1, l2, l3, all }

extension PowerPhaseJson on PowerPhase {
  String toJson() => name;

  static PowerPhase fromJson(String? value) {
    return PowerPhase.values.firstWhere(
      (phase) => phase.name == value,
      orElse: () => PowerPhase.l1,
    );
  }
}

enum ProjectGroupPowerProfile { singlePhase, threePhaseSymmetric }

extension ProjectGroupPowerProfileJson on ProjectGroupPowerProfile {
  String toJson() => name;

  static ProjectGroupPowerProfile fromJson(String? value) {
    return ProjectGroupPowerProfile.values.firstWhere(
      (profile) => profile.name == value,
      orElse: () => ProjectGroupPowerProfile.singlePhase,
    );
  }
}

class PowerConnectorTypeDefinition {
  const PowerConnectorTypeDefinition({
    required this.id,
    required this.label,
    required this.maxCurrentA,
    required this.phaseCount,
  });

  final String id;
  final String label;
  final double maxCurrentA;
  final int phaseCount;
}

class PowerPhaseLoad {
  const PowerPhaseLoad({this.l1A = 0, this.l2A = 0, this.l3A = 0});

  final double l1A;
  final double l2A;
  final double l3A;

  double get totalA => l1A + l2A + l3A;

  PowerPhaseLoad operator +(PowerPhaseLoad other) {
    return PowerPhaseLoad(
      l1A: l1A + other.l1A,
      l2A: l2A + other.l2A,
      l3A: l3A + other.l3A,
    );
  }
}

class ConnectorTypes {
  const ConnectorTypes._();

  static PowerConnectorTypeDefinition? findById(String? id) {
    if (id == null) {
      return null;
    }

    return all.where((type) => type.id == id).firstOrNull;
  }

  static const all = <PowerConnectorTypeDefinition>[
    PowerConnectorTypeDefinition(
      id: 'schuko_16a',
      label: '16 A Uni-Schuko',
      maxCurrentA: 16,
      phaseCount: 1,
    ),
    PowerConnectorTypeDefinition(
      id: 'cee_16a_3p',
      label: '16 A CEE 3P',
      maxCurrentA: 16,
      phaseCount: 1,
    ),
    PowerConnectorTypeDefinition(
      id: 'cee_16a_5p',
      label: '16 A CEE 5P',
      maxCurrentA: 16,
      phaseCount: 3,
    ),
    PowerConnectorTypeDefinition(
      id: 'cee_32a_5p',
      label: '32 A CEE 5P',
      maxCurrentA: 32,
      phaseCount: 3,
    ),
    PowerConnectorTypeDefinition(
      id: 'cee_63a_5p',
      label: '63 A CEE 5P',
      maxCurrentA: 63,
      phaseCount: 3,
    ),
    PowerConnectorTypeDefinition(
      id: 'cee_125a_5p',
      label: '125 A CEE 5P',
      maxCurrentA: 125,
      phaseCount: 3,
    ),
    PowerConnectorTypeDefinition(
      id: 'powerlock_200a',
      label: 'Powerlock 200 A',
      maxCurrentA: 200,
      phaseCount: 3,
    ),
    PowerConnectorTypeDefinition(
      id: 'powerlock_400a',
      label: 'Powerlock 400 A',
      maxCurrentA: 400,
      phaseCount: 3,
    ),
  ];
}
