part of '../project_editor_screen.dart';

String _connectorLabel(String? connectorTypeId) {
  if (connectorTypeId == null) {
    return 'Bez wejścia';
  }

  return ConnectorTypes.all
          .where((type) => type.id == connectorTypeId)
          .firstOrNull
          ?.label ??
      connectorTypeId;
}

bool _isThreePhaseConnector(String connectorTypeId) {
  return ConnectorTypes.findById(connectorTypeId)?.phaseCount == 3;
}

bool _isSinglePhaseConnector(String? connectorTypeId) {
  if (connectorTypeId == null) {
    return false;
  }
  return ConnectorTypes.findById(connectorTypeId)?.phaseCount == 1;
}

PowerPhase _normalizedOutletPhase({
  required String connectorTypeId,
  required PowerPhase phase,
  required String? inputConnectorTypeId,
}) {
  if (_isThreePhaseConnector(connectorTypeId)) {
    return PowerPhase.all;
  }
  if (_isSinglePhaseConnector(inputConnectorTypeId) ||
      phase == PowerPhase.all) {
    return PowerPhase.l1;
  }
  return phase;
}

String _defaultConnectorName(String connectorTypeId) {
  final connector = ConnectorTypes.findById(connectorTypeId);
  return switch (connector?.id) {
    'schuko_16a' => 'Schuko',
    'cee_16a_3p' => 'CEE 16A',
    'cee_16a_5p' => 'CEE 16A',
    'cee_32a_5p' => 'CEE 32A',
    'cee_63a_5p' => 'CEE 63A',
    'cee_125a_5p' => 'CEE 125A',
    'powerlock_200a' => 'Powerlock 200A',
    'powerlock_400a' => 'Powerlock 400A',
    _ => connector?.label ?? connectorTypeId,
  };
}

String _defaultOutletName({
  String? label,
  required String connectorTypeId,
  required PowerPhase phase,
  required int index,
}) {
  final base = label == null || label.trim().isEmpty
      ? _defaultConnectorName(connectorTypeId)
      : label.trim();

  if (phase == PowerPhase.all) {
    return '$base ${index + 1}';
  }

  return '$base ${_phaseLabel(phase)}.${index + 1}';
}

PowerPhase _phaseByGroupedIndex(int index, int count) {
  final normalizedCount = count <= 0 ? 1 : count;
  final phaseBlockSize = (normalizedCount / 3).ceil();
  final phaseSlot = index ~/ phaseBlockSize;
  if (phaseSlot <= 0) {
    return PowerPhase.l1;
  }
  if (phaseSlot == 1) {
    return PowerPhase.l2;
  }
  return PowerPhase.l3;
}

String _phaseLabel(PowerPhase phase) {
  return switch (phase) {
    PowerPhase.l1 => 'L1',
    PowerPhase.l2 => 'L2',
    PowerPhase.l3 => 'L3',
    PowerPhase.all => 'All',
  };
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      avatar: const Icon(Icons.bolt, size: 16),
    );
  }
}
