import '../../../catalog/domain/entities/catalog_device.dart';
import '../entities/project_models.dart';
import 'project_totals_service.dart';

const _nearLimitLoadFactor = 0.9;

/// Calculates the mass a [ProjectTruss] actually carries from its assigned
/// groups (including any assigned hooks) plus any manual load, and compares
/// it against the truss's own limits - either manually entered, or
/// interpolated from a linked catalog device's manufacturer load chart
/// (`ProjectTruss.trussCatalogDeviceId` / `CatalogDevice.loadChart`).
class TrussLoadService {
  const TrussLoadService([this._totalsService = const ProjectTotalsService()]);

  final ProjectTotalsService _totalsService;

  TrussLoad calculateLoad(
    ProjectTruss truss,
    Project project, {
    List<CatalogDevice> catalogDevices = const [],
  }) {
    final assignedGroupIds = truss.assignedGroupIds.toSet();
    final groupsMassKg = project.groups
        .where((group) => assignedGroupIds.contains(group.id))
        .fold<double>(
          0,
          (sum, group) =>
              sum +
              _totalsService.calculateGroup(group).weightKg +
              hookRequirement(group).hooksWeightKg,
        );
    final totalMassKg = groupsMassKg + truss.manualLoadKg;
    final distributedLoadKgPerM = truss.lengthM > 0
        ? totalMassKg / truss.lengthM
        : 0.0;

    final trussDevice = truss.trussCatalogDeviceId == null
        ? null
        : catalogDevices
              .where((device) => device.id == truss.trussCatalogDeviceId)
              .firstOrNull;
    final interpolated = _interpolateLimits(truss.lengthM, trussDevice);
    final hasInterpolatedLimits = interpolated.status != _ChartStatus.noData;

    // A manually-entered limit of zero (or less) is never physically
    // meaningful for a truss - treat it the same as "not set" so a stray `0`
    // (whether typed by mistake or left over from data saved before this
    // field required an explicit value) doesn't silently override a real
    // chart-based limit via `??`, which only substitutes for `null`.
    final manualTotalLoadKg = _asLimit(truss.maxTotalLoadKg);
    final manualDistributedLoadKgPerM = _asLimit(
      truss.maxDistributedLoadKgPerM,
    );

    return TrussLoad(
      trussId: truss.id,
      groupsMassKg: groupsMassKg,
      manualLoadKg: truss.manualLoadKg,
      totalMassKg: totalMassKg,
      distributedLoadKgPerM: distributedLoadKgPerM,
      maxTotalLoadKg: manualTotalLoadKg ?? interpolated.pointLoadKg,
      maxDistributedLoadKgPerM:
          manualDistributedLoadKgPerM ?? interpolated.distributedLoadKgPerM,
      totalLimitFromChart:
          manualTotalLoadKg == null && interpolated.pointLoadKg != null,
      distributedLimitFromChart:
          manualDistributedLoadKgPerM == null &&
          interpolated.distributedLoadKgPerM != null,
      hasInterpolatedLimits: hasInterpolatedLimits,
      isChartExtrapolated: interpolated.status == _ChartStatus.extrapolated,
    );
  }

  double? _asLimit(double? value) =>
      (value == null || value <= 0) ? null : value;

  /// How many hooks [group] needs (from `riggingPointsSnapshot` on its
  /// items) versus how many are actually assigned, and the resulting extra
  /// weight. This is a property of the group itself, independent of which
  /// truss (if any) it ends up assigned to - a group keeps the same
  /// physical hooks regardless.
  GroupHookRequirement hookRequirement(ProjectGroup group) {
    final requiredHooks = group.items
        .fold<double>(
          0,
          (sum, item) =>
              sum + (item.riggingPointsSnapshot ?? 0) * item.quantity,
        )
        .ceil();
    final assignedHooks = group.hookAssignments.fold<int>(
      0,
      (sum, assignment) => sum + assignment.quantity,
    );
    final hooksWeightKg = group.hookAssignments.fold<double>(
      0,
      (sum, assignment) =>
          sum + assignment.hookWeightKgSnapshot * assignment.quantity,
    );

    return GroupHookRequirement(
      requiredHooks: requiredHooks,
      assignedHooks: assignedHooks,
      hooksWeightKg: hooksWeightKg,
    );
  }

  /// Interpolates point/distributed load capacity at [lengthM] from
  /// [trussDevice]'s `loadChart`, ported from the legacy calculator
  /// (`truss-calculator.tsx`, `getInterpolatedLimits`): exact match wins,
  /// otherwise linear interpolation between the two closest table entries,
  /// falling back to linear extrapolation from the two nearest entries when
  /// [lengthM] is outside the table's range.
  _InterpolatedLimits _interpolateLimits(
    double lengthM,
    CatalogDevice? trussDevice,
  ) {
    final chart = trussDevice?.loadChart ?? const [];
    if (chart.isEmpty) {
      return const _InterpolatedLimits(status: _ChartStatus.noData);
    }

    final sortedChart = [...chart]
      ..sort((a, b) => a.lengthM.compareTo(b.lengthM));

    final exactMatch = sortedChart
        .where((entry) => entry.lengthM == lengthM)
        .firstOrNull;
    if (exactMatch != null) {
      return _InterpolatedLimits(
        pointLoadKg: exactMatch.pointLoadKg,
        distributedLoadKgPerM: exactMatch.distributedLoadKgPerM,
        status: _ChartStatus.ok,
      );
    }

    if (sortedChart.length < 2) {
      final onlyEntry = sortedChart.single;
      return _InterpolatedLimits(
        pointLoadKg: onlyEntry.pointLoadKg,
        distributedLoadKgPerM: onlyEntry.distributedLoadKgPerM,
        status: _ChartStatus.extrapolated,
      );
    }

    late final TrussLoadChartEntry p1;
    late final TrussLoadChartEntry p2;
    var status = _ChartStatus.ok;

    if (lengthM < sortedChart.first.lengthM) {
      status = _ChartStatus.extrapolated;
      p1 = sortedChart[0];
      p2 = sortedChart[1];
    } else if (lengthM > sortedChart.last.lengthM) {
      status = _ChartStatus.extrapolated;
      p1 = sortedChart[sortedChart.length - 2];
      p2 = sortedChart[sortedChart.length - 1];
    } else {
      p1 = sortedChart.lastWhere((entry) => entry.lengthM < lengthM);
      p2 = sortedChart.firstWhere((entry) => entry.lengthM > lengthM);
    }

    return _InterpolatedLimits(
      pointLoadKg: _interpolate(
        lengthM,
        p1.lengthM,
        p1.pointLoadKg,
        p2.lengthM,
        p2.pointLoadKg,
      ),
      distributedLoadKgPerM: _interpolate(
        lengthM,
        p1.lengthM,
        p1.distributedLoadKgPerM,
        p2.lengthM,
        p2.distributedLoadKgPerM,
      ),
      status: status,
    );
  }

  double _interpolate(double x, double x1, double y1, double x2, double y2) {
    if (x1 == x2) {
      return y1;
    }
    return y1 + ((x - x1) * (y2 - y1)) / (x2 - x1);
  }
}

enum _ChartStatus { ok, noData, extrapolated }

class _InterpolatedLimits {
  const _InterpolatedLimits({
    this.pointLoadKg,
    this.distributedLoadKgPerM,
    required this.status,
  });

  final double? pointLoadKg;
  final double? distributedLoadKgPerM;
  final _ChartStatus status;
}

class GroupHookRequirement {
  const GroupHookRequirement({
    required this.requiredHooks,
    required this.assignedHooks,
    required this.hooksWeightKg,
  });

  final int requiredHooks;
  final int assignedHooks;
  final double hooksWeightKg;

  bool get isSatisfied => assignedHooks >= requiredHooks;
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
    this.totalLimitFromChart = false,
    this.distributedLimitFromChart = false,
    this.hasInterpolatedLimits = false,
    this.isChartExtrapolated = false,
  });

  final String trussId;
  final double groupsMassKg;
  final double manualLoadKg;
  final double totalMassKg;
  final double distributedLoadKgPerM;
  final double? maxTotalLoadKg;
  final double? maxDistributedLoadKgPerM;

  /// Whether [maxTotalLoadKg] / [maxDistributedLoadKgPerM] came from the
  /// linked truss device's load chart rather than a manually-entered value.
  final bool totalLimitFromChart;
  final bool distributedLimitFromChart;

  /// Whether the truss has a linked catalog device with load chart data at
  /// all (regardless of whether either limit ended up manually overridden).
  final bool hasInterpolatedLimits;

  /// Whether the truss's length falls outside the load chart's own range,
  /// so the shown limit is an extrapolation rather than a table lookup.
  final bool isChartExtrapolated;

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
