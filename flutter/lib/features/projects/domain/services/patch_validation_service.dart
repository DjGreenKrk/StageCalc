import '../entities/project_models.dart';
import 'power_calculation_service.dart';

class PatchValidationService {
  const PatchValidationService();

  PatchValidationResult validate(Project project, ProjectPowerLoad powerLoad) {
    final outletUsage = <String, List<PowerConnection>>{};

    for (final connection in project.connections) {
      outletUsage
          .putIfAbsent(connection.sourceOutletId, () => <PowerConnection>[])
          .add(connection);
    }

    final duplicateOutletIds = outletUsage.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => entry.key)
        .toSet();

    final overloadedOutletIds = {
      for (final entry in powerLoad.outletLoads.entries)
        if (entry.value.isOverloaded) entry.key,
    };

    final overloadedDistroIds = {
      for (final entry in powerLoad.distroLoads.entries)
        if (entry.value.isInputOverloaded) entry.key,
    };

    return PatchValidationResult(
      duplicateOutletIds: duplicateOutletIds,
      cyclicDistroIds: _findCyclicDistroIds(project),
      overloadedOutletIds: overloadedOutletIds,
      overloadedDistroIds: overloadedDistroIds,
    );
  }

  /// Finds every distro that is part of a cycle in the distro-to-distro
  /// cascade graph (A feeds B feeds ... feeds A). `PowerCalculationService`
  /// already stops such a cycle from looping forever when calculating loads,
  /// but it does so silently; this makes the cycle visible so it can be
  /// flagged in the patcher instead of just producing a truncated result.
  Set<String> _findCyclicDistroIds(Project project) {
    final childDistroIds = <String, List<String>>{};
    for (final connection in project.connections) {
      final targetDistroId = connection.targetDistroId;
      if (connection.targetType == PowerConnectionTargetType.distro &&
          targetDistroId != null) {
        childDistroIds
            .putIfAbsent(connection.sourceDistroId, () => [])
            .add(targetDistroId);
      }
    }

    final cyclicDistroIds = <String>{};
    for (final distro in project.distros) {
      if (_canReachItself(distro.id, distro.id, childDistroIds, {})) {
        cyclicDistroIds.add(distro.id);
      }
    }
    return cyclicDistroIds;
  }

  bool _canReachItself(
    String startId,
    String currentId,
    Map<String, List<String>> childDistroIds,
    Set<String> visited,
  ) {
    for (final childId in childDistroIds[currentId] ?? const []) {
      if (childId == startId) {
        return true;
      }
      if (visited.contains(childId)) {
        continue;
      }
      if (_canReachItself(startId, childId, childDistroIds, {
        ...visited,
        childId,
      })) {
        return true;
      }
    }
    return false;
  }
}

class PatchValidationResult {
  const PatchValidationResult({
    required this.duplicateOutletIds,
    required this.cyclicDistroIds,
    required this.overloadedOutletIds,
    required this.overloadedDistroIds,
  });

  final Set<String> duplicateOutletIds;
  final Set<String> cyclicDistroIds;
  final Set<String> overloadedOutletIds;
  final Set<String> overloadedDistroIds;

  bool get hasWarnings =>
      duplicateOutletIds.isNotEmpty ||
      cyclicDistroIds.isNotEmpty ||
      overloadedOutletIds.isNotEmpty ||
      overloadedDistroIds.isNotEmpty;

  bool isOutletDuplicated(String outletId) =>
      duplicateOutletIds.contains(outletId);

  bool isDistroInCycle(String distroId) => cyclicDistroIds.contains(distroId);

  bool isOutletOverloaded(String outletId) =>
      overloadedOutletIds.contains(outletId);

  bool isDistroOverloaded(String distroId) =>
      overloadedDistroIds.contains(distroId);
}
