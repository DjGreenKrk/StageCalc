import '../entities/project_models.dart';
import 'project_totals_service.dart';

const _nearLimitLoadFactor = 0.9;

/// Calculates the mass a [ProjectTruss] actually carries from its assigned
/// groups plus any manual load, and compares it against the truss's own
/// limits.
///
/// This intentionally does not yet cover hooks (`riggingPoints`) or
/// manufacturer load-chart interpolation - neither has a data model in the
/// app yet (see `docs/DATA_MODEL.md`, "Kratownice"). `maxTotalLoadKg` and
/// `maxDistributedLoadKgPerM` are plain user-entered limits for now, not
/// derived from an interpolated chart.
class TrussLoadService {
  const TrussLoadService([this._totalsService = const ProjectTotalsService()]);

  final ProjectTotalsService _totalsService;

  TrussLoad calculateLoad(ProjectTruss truss, Project project) {
    final assignedGroupIds = truss.assignedGroupIds.toSet();
    final groupsMassKg = project.groups
        .where((group) => assignedGroupIds.contains(group.id))
        .fold<double>(
          0,
          (sum, group) => sum + _totalsService.calculateGroup(group).weightKg,
        );
    final totalMassKg = groupsMassKg + truss.manualLoadKg;
    final distributedLoadKgPerM = truss.lengthM > 0
        ? totalMassKg / truss.lengthM
        : 0.0;

    return TrussLoad(
      trussId: truss.id,
      groupsMassKg: groupsMassKg,
      manualLoadKg: truss.manualLoadKg,
      totalMassKg: totalMassKg,
      distributedLoadKgPerM: distributedLoadKgPerM,
      maxTotalLoadKg: truss.maxTotalLoadKg,
      maxDistributedLoadKgPerM: truss.maxDistributedLoadKgPerM,
    );
  }
}

class TrussLoad {
  const TrussLoad({
    required this.trussId,
    required this.groupsMassKg,
    required this.manualLoadKg,
    required this.totalMassKg,
    required this.distributedLoadKgPerM,
    this.maxTotalLoadKg,
    this.maxDistributedLoadKgPerM,
  });

  final String trussId;
  final double groupsMassKg;
  final double manualLoadKg;
  final double totalMassKg;
  final double distributedLoadKgPerM;
  final double? maxTotalLoadKg;
  final double? maxDistributedLoadKgPerM;

  /// Whether either limit is known at all. When both are null there is
  /// nothing to check the load against - that should read as "unknown", not
  /// silently as "fine".
  bool get hasKnownLimits =>
      maxTotalLoadKg != null || maxDistributedLoadKgPerM != null;

  bool get isOverTotalLimit =>
      maxTotalLoadKg != null && totalMassKg > maxTotalLoadKg!;

  bool get isNearTotalLimit =>
      maxTotalLoadKg != null &&
      !isOverTotalLimit &&
      totalMassKg >= maxTotalLoadKg! * _nearLimitLoadFactor;

  bool get isOverDistributedLimit =>
      maxDistributedLoadKgPerM != null &&
      distributedLoadKgPerM > maxDistributedLoadKgPerM!;

  bool get isNearDistributedLimit =>
      maxDistributedLoadKgPerM != null &&
      !isOverDistributedLimit &&
      distributedLoadKgPerM >= maxDistributedLoadKgPerM! * _nearLimitLoadFactor;

  bool get isOverloaded => isOverTotalLimit || isOverDistributedLimit;
}
