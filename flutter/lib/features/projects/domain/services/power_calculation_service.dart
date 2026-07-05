import '../entities/power_models.dart';
import '../entities/project_models.dart';
import 'project_totals_service.dart';

const _nearLimitLoadFactor = 0.9;

class PowerCalculationService {
  const PowerCalculationService([
    this._totalsService = const ProjectTotalsService(),
  ]);

  final ProjectTotalsService _totalsService;

  PowerPhaseLoad calculateGroupLoad({
    required ProjectGroup group,
    required PowerPhase outletPhase,
    Set<PowerPhase> selectedPhases = const {PowerPhase.l1},
    int sharedConnectionCount = 1,
  }) {
    final currentA =
        _totalsService.calculateGroup(group).currentA /
        sharedConnectionCount.clamp(1, 9999);

    if (outletPhase == PowerPhase.l1) {
      return PowerPhaseLoad(l1A: currentA);
    }
    if (outletPhase == PowerPhase.l2) {
      return PowerPhaseLoad(l2A: currentA);
    }
    if (outletPhase == PowerPhase.l3) {
      return PowerPhaseLoad(l3A: currentA);
    }

    if (group.powerProfile == ProjectGroupPowerProfile.threePhaseSymmetric) {
      final perPhase = currentA / 3;
      return PowerPhaseLoad(l1A: perPhase, l2A: perPhase, l3A: perPhase);
    }

    final phases = selectedPhases.isEmpty ? {PowerPhase.l1} : selectedPhases;
    final perPhase = currentA / phases.length;

    return PowerPhaseLoad(
      l1A: phases.contains(PowerPhase.l1) ? perPhase : 0,
      l2A: phases.contains(PowerPhase.l2) ? perPhase : 0,
      l3A: phases.contains(PowerPhase.l3) ? perPhase : 0,
    );
  }

  ProjectPowerLoad calculateProjectLoads(Project project) {
    final outletLoads = <String, OutletPowerLoad>{};
    final distroLoads = <String, DistroPowerLoad>{};
    final groupConnectionCounts = <String, int>{};
    final distrosById = {
      for (final distro in project.distros) distro.id: distro,
    };

    for (final connection in project.connections) {
      final groupId = connection.targetGroupId;
      if (groupId == null) {
        continue;
      }
      groupConnectionCounts[groupId] =
          (groupConnectionCounts[groupId] ?? 0) + 1;
    }

    for (final distro in project.distros) {
      final distroLoad = _calculateDistroLoad(
        project: project,
        distro: distro,
        distrosById: distrosById,
        outletLoads: outletLoads,
        groupConnectionCounts: groupConnectionCounts,
        visitedDistroIds: const {},
      );

      final inputConnector = ConnectorTypes.findById(
        distro.inputConnectorTypeId,
      );
      distroLoads[distro.id] = DistroPowerLoad(
        distroId: distro.id,
        load: distroLoad,
        inputMaxCurrentA: inputConnector?.maxCurrentA ?? 0,
      );
    }

    return ProjectPowerLoad(outletLoads: outletLoads, distroLoads: distroLoads);
  }

  PowerPhaseLoad _calculateDistroLoad({
    required Project project,
    required ProjectDistro distro,
    required Map<String, ProjectDistro> distrosById,
    required Map<String, OutletPowerLoad> outletLoads,
    required Map<String, int> groupConnectionCounts,
    required Set<String> visitedDistroIds,
  }) {
    if (visitedDistroIds.contains(distro.id)) {
      return const PowerPhaseLoad();
    }

    final nextVisitedDistroIds = {...visitedDistroIds, distro.id};
    var distroLoad = const PowerPhaseLoad();

    for (final outlet in distro.outlets) {
      var outletLoad = const PowerPhaseLoad();
      final outletConnections = project.connections.where(
        (candidate) => candidate.sourceOutletId == outlet.id,
      );

      for (final connection in outletConnections) {
        if (connection.targetGroupId != null) {
          final group = project.groups
              .where((candidate) => candidate.id == connection.targetGroupId)
              .firstOrNull;

          if (group != null) {
            outletLoad += calculateGroupLoad(
              group: group,
              outletPhase: outlet.phase,
              selectedPhases: connection.selectedPhases.toSet(),
              sharedConnectionCount:
                  groupConnectionCounts[connection.targetGroupId] ?? 1,
            );
          }
        }

        if (connection.targetDistroId != null) {
          final childDistro = distrosById[connection.targetDistroId];
          if (childDistro != null) {
            outletLoad += _calculateDistroLoad(
              project: project,
              distro: childDistro,
              distrosById: distrosById,
              outletLoads: outletLoads,
              groupConnectionCounts: groupConnectionCounts,
              visitedDistroIds: nextVisitedDistroIds,
            );
          }
        }
      }

      outletLoads[outlet.id] = OutletPowerLoad(
        outletId: outlet.id,
        load: outletLoad,
        maxCurrentA: outlet.maxCurrentA,
      );
      distroLoad += outletLoad;
    }

    return distroLoad;
  }
}

class ProjectPowerLoad {
  const ProjectPowerLoad({
    required this.outletLoads,
    required this.distroLoads,
  });

  final Map<String, OutletPowerLoad> outletLoads;
  final Map<String, DistroPowerLoad> distroLoads;

  Map<String, PowerPhaseLoad> get distroPhaseLoads {
    return distroLoads.map(
      (distroId, distroLoad) => MapEntry(distroId, distroLoad.load),
    );
  }
}

class DistroPowerLoad {
  const DistroPowerLoad({
    required this.distroId,
    required this.load,
    required this.inputMaxCurrentA,
  });

  final String distroId;
  final PowerPhaseLoad load;
  final double inputMaxCurrentA;

  double get maxLoadedPhaseA {
    return [load.l1A, load.l2A, load.l3A].reduce((a, b) => a > b ? a : b);
  }

  bool get isInputOverloaded =>
      inputMaxCurrentA > 0 && maxLoadedPhaseA > inputMaxCurrentA;

  bool get isInputNearLimit =>
      inputMaxCurrentA > 0 &&
      !isInputOverloaded &&
      maxLoadedPhaseA >= inputMaxCurrentA * _nearLimitLoadFactor;

  bool isPhaseOverloaded(PowerPhase phase) {
    if (inputMaxCurrentA <= 0) {
      return false;
    }

    return switch (phase) {
      PowerPhase.l1 => load.l1A > inputMaxCurrentA,
      PowerPhase.l2 => load.l2A > inputMaxCurrentA,
      PowerPhase.l3 => load.l3A > inputMaxCurrentA,
      PowerPhase.all => maxLoadedPhaseA > inputMaxCurrentA,
    };
  }

  bool isPhaseNearLimit(PowerPhase phase) {
    if (inputMaxCurrentA <= 0 || isPhaseOverloaded(phase)) {
      return false;
    }

    return switch (phase) {
      PowerPhase.l1 => load.l1A >= inputMaxCurrentA * _nearLimitLoadFactor,
      PowerPhase.l2 => load.l2A >= inputMaxCurrentA * _nearLimitLoadFactor,
      PowerPhase.l3 => load.l3A >= inputMaxCurrentA * _nearLimitLoadFactor,
      PowerPhase.all =>
        maxLoadedPhaseA >= inputMaxCurrentA * _nearLimitLoadFactor,
    };
  }
}

class OutletPowerLoad {
  const OutletPowerLoad({
    required this.outletId,
    required this.load,
    required this.maxCurrentA,
  });

  final String outletId;
  final PowerPhaseLoad load;
  final double maxCurrentA;

  double get maxLoadedPhaseA {
    return [load.l1A, load.l2A, load.l3A].reduce((a, b) => a > b ? a : b);
  }

  bool get hasLoad => maxLoadedPhaseA > 0;

  bool get isOverloaded => maxCurrentA > 0 && maxLoadedPhaseA > maxCurrentA;

  bool get isNearLimit =>
      maxCurrentA > 0 &&
      !isOverloaded &&
      maxLoadedPhaseA >= maxCurrentA * _nearLimitLoadFactor;
}
