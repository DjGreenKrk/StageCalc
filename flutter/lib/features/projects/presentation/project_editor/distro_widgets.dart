part of '../project_editor_screen.dart';

class _DistroCard extends StatelessWidget {
  const _DistroCard({
    required this.distro,
    required this.project,
    required this.isPowerSource,
    required this.outletLoads,
    required this.patchValidation,
    required this.onEdit,
    required this.onDelete,
    required this.onOutletTap,
    this.phaseLoad,
    this.distroLoad,
  });

  final ProjectDistro distro;
  final Project project;
  final bool isPowerSource;
  final PowerPhaseLoad? phaseLoad;
  final DistroPowerLoad? distroLoad;
  final Map<String, OutletPowerLoad> outletLoads;
  final PatchValidationResult patchValidation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(ProjectOutlet outlet, List<PowerConnection> connections)
  onOutletTap;

  List<PowerConnection> _connectionsForOutlet(String outletId) {
    return project.connections
        .where((connection) => connection.sourceOutletId == outletId)
        .toList();
  }

  List<String> _targetNamesFor(List<PowerConnection> connections) {
    return [
      for (final connection in connections)
        if (connection.targetType == PowerConnectionTargetType.distro)
          project.distros
                  .where(
                    (candidate) => candidate.id == connection.targetDistroId,
                  )
                  .firstOrNull
                  ?.name ??
              'Nieznana rozdzielnica'
        else
          project.groups
                  .where(
                    (candidate) => candidate.id == connection.targetGroupId,
                  )
                  .firstOrNull
                  ?.name ??
              'Nieznana grupa',
    ];
  }

  Widget _buildOutletTile(ProjectOutlet outlet) {
    final connections = _connectionsForOutlet(outlet.id);
    return _OutletTile(
      outlet: outlet,
      connections: connections,
      targetNames: _targetNamesFor(connections),
      load: outletLoads[outlet.id],
      isDuplicated: patchValidation.isOutletDuplicated(outlet.id),
      onTap: () => onOutletTap(outlet, connections),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GreenCrewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  distro.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (isPowerSource)
                const Chip(
                  avatar: Icon(Icons.power, size: 16),
                  label: Text('Zrodlo'),
                ),
              IconButton(
                tooltip: 'Edytuj rozdzielnice',
                onPressed: onEdit,
                icon: const Icon(Icons.tune),
              ),
              IconButton(
                tooltip: 'Usun rozdzielnice',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.input, size: 16),
                label: Text(_connectorLabel(distro.inputConnectorTypeId)),
              ),
              if (distro.sourceType == ProjectDistroSourceType.location)
                const Chip(
                  avatar: Icon(Icons.location_city_outlined, size: 16),
                  label: Text('Lokacja'),
                ),
              if (patchValidation.isDistroInCycle(distro.id))
                const _StatusChip(
                  label: 'Cykl w polaczeniach rozdzielnic',
                  isError: true,
                  isWarning: false,
                ),
              if ((distroLoad?.isInputOverloaded ?? false) ||
                  (distroLoad?.isInputNearLimit ?? false))
                _StatusChip(
                  label:
                      'Wejscie ${distroLoad!.maxLoadedPhaseA.toStringAsFixed(1)}/'
                      '${distroLoad!.inputMaxCurrentA.toStringAsFixed(0)} A',
                  isError: distroLoad!.isInputOverloaded,
                  isWarning: distroLoad!.isInputNearLimit,
                ),
              Chip(
                avatar: const Icon(Icons.power, size: 16),
                label: Text('${distro.outlets.length} gniazd'),
              ),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LoadChip(
                label: 'L1',
                value: phaseLoad?.l1A ?? 0,
                maxValue: distroLoad?.inputMaxCurrentA ?? 0,
                isOverloaded:
                    distroLoad?.isPhaseOverloaded(PowerPhase.l1) ?? false,
                isNearLimit:
                    distroLoad?.isPhaseNearLimit(PowerPhase.l1) ?? false,
              ),
              _LoadChip(
                label: 'L2',
                value: phaseLoad?.l2A ?? 0,
                maxValue: distroLoad?.inputMaxCurrentA ?? 0,
                isOverloaded:
                    distroLoad?.isPhaseOverloaded(PowerPhase.l2) ?? false,
                isNearLimit:
                    distroLoad?.isPhaseNearLimit(PowerPhase.l2) ?? false,
              ),
              _LoadChip(
                label: 'L3',
                value: phaseLoad?.l3A ?? 0,
                maxValue: distroLoad?.inputMaxCurrentA ?? 0,
                isOverloaded:
                    distroLoad?.isPhaseOverloaded(PowerPhase.l3) ?? false,
                isNearLimit:
                    distroLoad?.isPhaseNearLimit(PowerPhase.l3) ?? false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final outlet in distro.outlets) _buildOutletTile(outlet),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadChip extends StatelessWidget {
  const _LoadChip({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.isOverloaded,
    required this.isNearLimit,
  });

  final String label;
  final double value;
  final double maxValue;
  final bool isOverloaded;
  final bool isNearLimit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final valueText = maxValue > 0
        ? '${value.toStringAsFixed(1)}/${maxValue.toStringAsFixed(0)} A'
        : '${value.toStringAsFixed(1)} A';

    return Chip(
      avatar: Icon(
        isOverloaded || isNearLimit ? Icons.warning_amber : Icons.bolt,
        size: 16,
      ),
      backgroundColor: isOverloaded
          ? colorScheme.errorContainer
          : isNearLimit
          ? Colors.amber.shade700
          : null,
      label: Text('$label $valueText'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isError,
    required this.isWarning,
  });

  final String label;
  final bool isError;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: const Icon(Icons.warning_amber, size: 16),
      backgroundColor: isError
          ? colorScheme.errorContainer
          : isWarning
          ? Colors.amber.shade700
          : null,
      label: Text(label),
    );
  }
}

/// Tappable "patch point" for a single outlet (visual patcher, backlog item
/// "bardziej wizualny uklad patchera") - a bigger, more diagram-like tile
/// than a plain chip, mirroring `docs/FEATURE_SCOPE.md`'s original "Wizualny
/// patcher" spec: shows the outlet's phase, occupancy, load and (if
/// connected) its target at a glance, and reacts to taps instead of only
/// being informational.
class _OutletTile extends StatelessWidget {
  const _OutletTile({
    required this.outlet,
    required this.connections,
    required this.targetNames,
    required this.isDuplicated,
    required this.onTap,
    this.load,
  });

  final ProjectOutlet outlet;
  final List<PowerConnection> connections;
  final List<String> targetNames;
  final bool isDuplicated;
  final VoidCallback onTap;
  final OutletPowerLoad? load;

  Set<PowerPhase> get _occupiedPhases {
    final phases = <PowerPhase>{};
    for (final connection in connections) {
      if (connection.targetType == PowerConnectionTargetType.distro) {
        phases.addAll(const [PowerPhase.l1, PowerPhase.l2, PowerPhase.l3]);
      } else {
        phases.addAll(connection.selectedPhases);
      }
    }
    return phases;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPatched = connections.isNotEmpty;
    final isOverloaded = load?.isOverloaded ?? false;
    final isNearLimit = load?.isNearLimit ?? false;
    final phaseLoad = load?.maxLoadedPhaseA ?? 0;
    final showPhaseDots = outlet.phase == PowerPhase.all;

    final Color backgroundColor;
    final Color borderColor;
    if (isDuplicated || isOverloaded) {
      backgroundColor = colorScheme.errorContainer;
      borderColor = colorScheme.error;
    } else if (isNearLimit) {
      backgroundColor = Colors.amber.shade700.withValues(alpha: 0.2);
      borderColor = Colors.amber.shade700;
    } else if (isPatched) {
      backgroundColor = colorScheme.primaryContainer;
      borderColor = colorScheme.primary;
    } else {
      backgroundColor = Colors.transparent;
      borderColor = colorScheme.outlineVariant;
    }

    return Material(
      key: ValueKey('outlet_tile_${outlet.id}'),
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _phaseLabel(outlet.phase),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  if (showPhaseDots)
                    Row(
                      children: [
                        for (final phase in const [
                          PowerPhase.l1,
                          PowerPhase.l2,
                          PowerPhase.l3,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _occupiedPhases.contains(phase)
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Icon(
                isDuplicated
                    ? Icons.link_off
                    : isOverloaded || isNearLimit
                    ? Icons.warning_amber
                    : isPatched
                    ? Icons.bolt
                    : Icons.add_circle_outline,
                size: 18,
                color: isDuplicated || isOverloaded ? colorScheme.error : null,
              ),
              const SizedBox(height: 4),
              Text(
                isPatched ? targetNames.join(', ') : 'Wolne',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                outlet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${phaseLoad.toStringAsFixed(1)}/${outlet.maxCurrentA.toStringAsFixed(0)} A',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
