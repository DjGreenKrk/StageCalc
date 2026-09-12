part of '../project_editor_screen.dart';

class _DistroCard extends StatelessWidget {
  const _DistroCard({
    required this.distro,
    required this.isPowerSource,
    required this.outletLoads,
    required this.patchValidation,
    required this.onEdit,
    required this.onDelete,
    this.phaseLoad,
    this.distroLoad,
  });

  final ProjectDistro distro;
  final bool isPowerSource;
  final PowerPhaseLoad? phaseLoad;
  final DistroPowerLoad? distroLoad;
  final Map<String, OutletPowerLoad> outletLoads;
  final PatchValidationResult patchValidation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
              for (final outlet in distro.outlets)
                _OutletLoadChip(
                  outlet: outlet,
                  load: outletLoads[outlet.id],
                  isDuplicated: patchValidation.isOutletDuplicated(outlet.id),
                ),
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

class _OutletLoadChip extends StatelessWidget {
  const _OutletLoadChip({
    required this.outlet,
    required this.isDuplicated,
    this.load,
  });

  final ProjectOutlet outlet;
  final bool isDuplicated;
  final OutletPowerLoad? load;

  @override
  Widget build(BuildContext context) {
    final outletLoad = load;
    final isOverloaded = outletLoad?.isOverloaded ?? false;
    final isNearLimit = outletLoad?.isNearLimit ?? false;
    final hasLoad = outletLoad?.hasLoad ?? false;
    final colorScheme = Theme.of(context).colorScheme;
    final phaseLoad = outletLoad?.maxLoadedPhaseA ?? 0;

    return Chip(
      avatar: Icon(
        isDuplicated
            ? Icons.link_off
            : isOverloaded || isNearLimit
            ? Icons.warning_amber
            : hasLoad
            ? Icons.bolt
            : Icons.power_outlined,
        size: 16,
      ),
      backgroundColor: isDuplicated || isOverloaded
          ? colorScheme.errorContainer
          : isNearLimit
          ? Colors.amber.shade700
          : hasLoad
          ? colorScheme.primaryContainer
          : null,
      label: Text(
        '${outlet.name} ${_phaseLabel(outlet.phase)} '
        '${phaseLoad.toStringAsFixed(1)}/${outlet.maxCurrentA.toStringAsFixed(0)} A',
      ),
    );
  }
}
