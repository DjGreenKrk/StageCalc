part of '../project_editor_screen.dart';

class _TrussCard extends StatelessWidget {
  const _TrussCard({
    required this.truss,
    required this.load,
    required this.groups,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectTruss truss;
  final TrussLoad load;
  final List<ProjectGroup> groups;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final assignedGroupNames = truss.assignedGroupIds
        .map((id) => groups.where((group) => group.id == id).firstOrNull?.name)
        .whereType<String>()
        .toList();

    return GreenCrewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  truss.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Edytuj kratownice',
                onPressed: onEdit,
                icon: const Icon(Icons.tune),
              ),
              IconButton(
                tooltip: 'Usun kratownice',
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
                avatar: const Icon(Icons.straighten, size: 16),
                label: Text('${truss.lengthM.toStringAsFixed(1)} m'),
              ),
              Chip(
                avatar: const Icon(Icons.fitness_center, size: 16),
                label: Text(
                  '${load.totalMassKg.toStringAsFixed(1)} kg'
                  '${load.maxTotalLoadKg == null ? '' : ' / ${load.maxTotalLoadKg!.toStringAsFixed(0)} kg'}',
                ),
                backgroundColor: load.isOverTotalLimit
                    ? colorScheme.errorContainer
                    : load.isNearTotalLimit
                    ? Colors.amber.shade700
                    : null,
              ),
              Chip(
                avatar: const Icon(Icons.horizontal_rule, size: 16),
                label: Text(
                  '${load.distributedLoadKgPerM.toStringAsFixed(1)} kg/m'
                  '${load.maxDistributedLoadKgPerM == null ? '' : ' / ${load.maxDistributedLoadKgPerM!.toStringAsFixed(1)} kg/m'}',
                ),
                backgroundColor: load.isOverDistributedLimit
                    ? colorScheme.errorContainer
                    : load.isNearDistributedLimit
                    ? Colors.amber.shade700
                    : null,
              ),
              if (!load.hasKnownLimits)
                const Chip(
                  avatar: Icon(Icons.help_outline, size: 16),
                  label: Text('Brak zdefiniowanych limitow'),
                ),
            ],
          ),
          if (assignedGroupNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in assignedGroupNames)
                  Chip(
                    avatar: const Icon(Icons.view_module_outlined, size: 16),
                    label: Text(name),
                  ),
              ],
            ),
          ],
          if ((truss.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(truss.notes!),
          ],
        ],
      ),
    );
  }
}

class _TrussDialog extends StatefulWidget {
  const _TrussDialog({required this.groups, this.truss});

  final List<ProjectGroup> groups;
  final ProjectTruss? truss;

  @override
  State<_TrussDialog> createState() => _TrussDialogState();
}

class _TrussDialogState extends State<_TrussDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _lengthController;
  late final TextEditingController _manualLoadController;
  late final TextEditingController _maxTotalLoadController;
  late final TextEditingController _maxDistributedLoadController;
  late final TextEditingController _notesController;
  late Set<String> _assignedGroupIds;

  @override
  void initState() {
    super.initState();
    final truss = widget.truss;
    _nameController = TextEditingController(text: truss?.name ?? 'Kratownica');
    _lengthController = TextEditingController(
      text: (truss?.lengthM ?? 0).toStringAsFixed(1),
    );
    _manualLoadController = TextEditingController(
      text: (truss?.manualLoadKg ?? 0).toStringAsFixed(1),
    );
    _maxTotalLoadController = TextEditingController(
      text: truss?.maxTotalLoadKg?.toStringAsFixed(0) ?? '',
    );
    _maxDistributedLoadController = TextEditingController(
      text: truss?.maxDistributedLoadKgPerM?.toStringAsFixed(1) ?? '',
    );
    _notesController = TextEditingController(text: truss?.notes ?? '');
    _assignedGroupIds = {...?truss?.assignedGroupIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _manualLoadController.dispose();
    _maxTotalLoadController.dispose();
    _maxDistributedLoadController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.truss == null ? 'Dodaj kratownice' : 'Edytuj kratownice',
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nazwa'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lengthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dlugosc',
                  suffixText: 'm',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _manualLoadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reczne obciazenie',
                  suffixText: 'kg',
                  helperText: 'Np. akcesoria bez wlasnej grupy w projekcie.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxTotalLoadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limit calkowity (opcjonalnie)',
                  suffixText: 'kg',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxDistributedLoadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limit rozlozony (opcjonalnie)',
                  suffixText: 'kg/m',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notatki'),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Przypisane grupy',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (widget.groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Projekt nie ma jeszcze zadnej grupy urzadzen.'),
                )
              else
                for (final group in widget.groups)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _assignedGroupIds.contains(group.id),
                    title: Text(group.name),
                    onChanged: (selected) {
                      setState(() {
                        if (selected ?? false) {
                          _assignedGroupIds.add(group.id);
                        } else {
                          _assignedGroupIds.remove(group.id);
                        }
                      });
                    },
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Zapisz')),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _TrussFormResult(
        name: name,
        lengthM: _parseNumber(_lengthController.text),
        manualLoadKg: _parseNumber(_manualLoadController.text),
        maxTotalLoadKg: _parseOptionalNumber(_maxTotalLoadController.text),
        maxDistributedLoadKgPerM: _parseOptionalNumber(
          _maxDistributedLoadController.text,
        ),
        assignedGroupIds: _assignedGroupIds.toList(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }

  double _parseNumber(String value, {double fallback = 0}) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? fallback;
  }

  double? _parseOptionalNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }
}

class _TrussFormResult {
  const _TrussFormResult({
    required this.name,
    required this.lengthM,
    required this.manualLoadKg,
    required this.maxTotalLoadKg,
    required this.maxDistributedLoadKgPerM,
    required this.assignedGroupIds,
    this.notes,
  });

  final String name;
  final double lengthM;
  final double manualLoadKg;
  final double? maxTotalLoadKg;
  final double? maxDistributedLoadKgPerM;
  final List<String> assignedGroupIds;
  final String? notes;
}
