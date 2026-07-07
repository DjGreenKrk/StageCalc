import 'package:flutter/material.dart';

import '../../../infrastructure/local_database/app_database_provider.dart';
import '../../../shared/models/offline_sync_status.dart';
import '../../../shared/widgets/greencrew_card.dart';
import '../../../shared/widgets/greencrew_empty_state.dart';
import '../../../shared/widgets/greencrew_section_header.dart';
import '../../projects/domain/entities/power_models.dart';
import '../data/drift_power_preset_repository.dart';
import '../data/power_preset_repository.dart';
import '../domain/entities/power_preset.dart';

class PowerPresetsPanel extends StatefulWidget {
  const PowerPresetsPanel({super.key});

  @override
  State<PowerPresetsPanel> createState() => _PowerPresetsPanelState();
}

class _PowerPresetsPanelState extends State<PowerPresetsPanel> {
  PowerPresetRepository? _repository;
  List<PowerPreset> _presets = const [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = DriftPowerPresetRepository(
        AppDatabaseProvider.instance,
      );
      await repository.ensureSeedData();
      final presets = await repository.getPresets();

      if (!mounted) {
        return;
      }

      setState(() {
        _repository = repository;
        _presets = presets;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Nie udalo sie wczytac presetow. Dane lokalne pozostaly bez zmian.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 360,
        child: GreenCrewEmptyState(
          icon: Icons.error_outline,
          title: 'Blad danych',
          message: _error!,
          actionLabel: 'Sprobuj ponownie',
          onAction: _loadPresets,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GreenCrewSectionHeader(
          title: 'Presety rozdzielnic',
          action: OutlinedButton.icon(
            onPressed: _openPresetDialog,
            icon: const Icon(Icons.add),
            label: const Text('Dodaj preset'),
          ),
        ),
        const SizedBox(height: 12),
        if (_presets.isEmpty)
          GreenCrewCard(
            child: GreenCrewEmptyState(
              icon: Icons.electrical_services_outlined,
              title: 'Brak presetow',
              message: 'Dodaj preset rozdzielnicy, aby uzyc go w patcherze.',
              actionLabel: 'Dodaj preset',
              onAction: _openPresetDialog,
            ),
          )
        else
          for (final preset in _presets) ...[
            _PowerPresetCard(
              preset: preset,
              onDelete: () => _deletePreset(preset),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Future<void> _openPresetDialog() async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final result = await showDialog<_PresetFormResult>(
      context: context,
      builder: (context) => const _PresetDialog(),
    );

    if (result == null) {
      return;
    }

    final now = DateTime.now();
    await repository.savePreset(
      PowerPreset(
        id: 'preset_${now.microsecondsSinceEpoch}',
        name: result.name,
        inputConnectorTypeId: result.inputConnectorTypeId,
        outlets: result.outlets,
        createdAt: now,
        updatedAt: now,
        syncStatus: OfflineSyncStatus.localOnly,
      ),
    );

    final presets = await repository.getPresets();
    if (!mounted) {
      return;
    }

    setState(() => _presets = presets);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Preset zapisany lokalnie')));
  }

  Future<void> _deletePreset(PowerPreset preset) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunac preset?'),
        content: Text('"${preset.name}" zostanie usuniety lokalnie.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usun'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await repository.deletePreset(preset.id);
    final presets = await repository.getPresets();

    if (!mounted) {
      return;
    }

    setState(() => _presets = presets);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Preset usuniety lokalnie')));
  }
}

class _PowerPresetCard extends StatelessWidget {
  const _PowerPresetCard({required this.preset, required this.onDelete});

  final PowerPreset preset;
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
                  preset.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Usun preset',
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
                label: Text(_connectorLabel(preset.inputConnectorTypeId)),
              ),
              Chip(
                avatar: const Icon(Icons.power, size: 16),
                label: Text('${preset.outlets.length} gniazd'),
              ),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final outlet in preset.outlets)
                Chip(
                  label: Text('${outlet.name} ${_phaseLabel(outlet.phase)}'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _connectorLabel(String? connectorTypeId) {
    if (connectorTypeId == null) {
      return 'Bez wejscia';
    }

    return ConnectorTypes.all
            .where((type) => type.id == connectorTypeId)
            .firstOrNull
            ?.label ??
        connectorTypeId;
  }

  String _phaseLabel(PowerPhase phase) {
    return switch (phase) {
      PowerPhase.l1 => 'L1',
      PowerPhase.l2 => 'L2',
      PowerPhase.l3 => 'L3',
      PowerPhase.all => 'All',
    };
  }
}

class _PresetDialog extends StatefulWidget {
  const _PresetDialog();

  @override
  State<_PresetDialog> createState() => _PresetDialogState();
}

class _PresetDialogState extends State<_PresetDialog> {
  final _nameController = TextEditingController(text: 'Nowy preset');
  String? _inputConnectorTypeId = 'cee_32a_5p';
  List<_PresetOutletGroup> _outletGroups = const [
    _PresetOutletGroup(
      id: 'default_schuko',
      label: 'Schuko',
      connectorTypeId: 'schuko_16a',
      count: 6,
      phaseMode: _PresetPhaseMode.balanced,
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj preset'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nazwa'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _inputConnectorTypeId,
              decoration: const InputDecoration(labelText: 'Wejscie'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Bez wejscia'),
                ),
                for (final connector in ConnectorTypes.all)
                  DropdownMenuItem<String?>(
                    value: connector.id,
                    child: Text(connector.label),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _inputConnectorTypeId = value;
                  _outletGroups = _normalizePresetOutletGroups(
                    _outletGroups,
                    value,
                  );
                });
              },
            ),
            const SizedBox(height: 12),
            _PresetOutletGroupsEditor(
              groups: _outletGroups,
              inputConnectorTypeId: _inputConnectorTypeId,
              onChanged: (groups) {
                setState(() {
                  _outletGroups = _normalizePresetOutletGroups(
                    groups,
                    _inputConnectorTypeId,
                  );
                });
              },
            ),
          ],
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
    final outlets = _buildOutlets();
    if (name.isEmpty || outlets.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _PresetFormResult(
        name: name,
        inputConnectorTypeId: _inputConnectorTypeId,
        outlets: outlets,
      ),
    );
  }

  List<PowerOutletTemplate> _buildOutlets() {
    var globalIndex = 0;
    return [
      for (final group in _normalizePresetOutletGroups(
        _outletGroups,
        _inputConnectorTypeId,
      ))
        for (var index = 0; index < group.count.clamp(0, 48).toInt(); index++)
          PowerOutletTemplate(
            id: 'outlet_${globalIndex++}',
            name: _defaultOutletName(
              label: group.label,
              connectorTypeId: group.connectorTypeId,
              phase: group.phaseMode.phaseForIndex(
                index,
                count: group.count.clamp(0, 48).toInt(),
              ),
              index: index,
            ),
            connectorTypeId: group.connectorTypeId,
            phase: group.phaseMode.phaseForIndex(
              index,
              count: group.count.clamp(0, 48).toInt(),
            ),
          ),
    ];
  }
}

class _PresetOutletGroup {
  const _PresetOutletGroup({
    required this.id,
    required this.label,
    required this.connectorTypeId,
    required this.count,
    required this.phaseMode,
  });

  final String id;
  final String label;
  final String connectorTypeId;
  final int count;
  final _PresetPhaseMode phaseMode;
}

enum _PresetPhaseMode { l1Only, balanced, all }

extension _PresetPhaseModeData on _PresetPhaseMode {
  String get label {
    return switch (this) {
      _PresetPhaseMode.l1Only => 'Wszystkie L1',
      _PresetPhaseMode.balanced => 'L1/L2/L3 grupami',
      _PresetPhaseMode.all => 'Wszystkie 3F / All',
    };
  }

  PowerPhase phaseForIndex(int index, {required int count}) {
    return switch (this) {
      _PresetPhaseMode.l1Only => PowerPhase.l1,
      _PresetPhaseMode.balanced => _phaseByGroupedIndex(index, count),
      _PresetPhaseMode.all => PowerPhase.all,
    };
  }
}

class _PresetOutletGroupsEditor extends StatelessWidget {
  const _PresetOutletGroupsEditor({
    required this.groups,
    required this.inputConnectorTypeId,
    required this.onChanged,
  });

  final List<_PresetOutletGroup> groups;
  final String? inputConnectorTypeId;
  final ValueChanged<List<_PresetOutletGroup>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sekcje wyjsc',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              onPressed: () => _addGroup(context),
              icon: const Icon(Icons.add),
              label: const Text('Dodaj'),
            ),
          ],
        ),
        if (groups.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Brak sekcji wyjsc.'),
          )
        else
          for (final group in groups)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(group.label),
              subtitle: Text(
                '${group.count}x ${_connectorLabel(group.connectorTypeId)} / ${group.phaseMode.label}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Edytuj sekcje',
                    onPressed: () => _editGroup(context, group),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Usun sekcje',
                    onPressed: () {
                      onChanged(
                        groups
                            .where((candidate) => candidate.id != group.id)
                            .toList(),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Future<void> _addGroup(BuildContext context) async {
    final result = await showDialog<_PresetOutletGroup>(
      context: context,
      builder: (context) => _PresetOutletGroupDialog(
        inputConnectorTypeId: inputConnectorTypeId,
        group: _PresetOutletGroup(
          id: 'group_${DateTime.now().microsecondsSinceEpoch}',
          label: 'Schuko',
          connectorTypeId: 'schuko_16a',
          count: 1,
          phaseMode: _PresetPhaseMode.l1Only,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    onChanged([...groups, result]);
  }

  Future<void> _editGroup(
    BuildContext context,
    _PresetOutletGroup group,
  ) async {
    final result = await showDialog<_PresetOutletGroup>(
      context: context,
      builder: (context) => _PresetOutletGroupDialog(
        group: group,
        inputConnectorTypeId: inputConnectorTypeId,
      ),
    );

    if (result == null) {
      return;
    }

    onChanged(
      groups
          .map((candidate) => candidate.id == result.id ? result : candidate)
          .toList(),
    );
  }
}

class _PresetOutletGroupDialog extends StatefulWidget {
  const _PresetOutletGroupDialog({
    required this.group,
    required this.inputConnectorTypeId,
  });

  final _PresetOutletGroup group;
  final String? inputConnectorTypeId;

  @override
  State<_PresetOutletGroupDialog> createState() =>
      _PresetOutletGroupDialogState();
}

class _PresetOutletGroupDialogState extends State<_PresetOutletGroupDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _countController;
  late String _connectorTypeId;
  late _PresetPhaseMode _phaseMode;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.group.label);
    _countController = TextEditingController(text: '${widget.group.count}');
    _connectorTypeId = widget.group.connectorTypeId;
    _phaseMode = widget.group.phaseMode;
    _normalizePhaseMode();
    _labelWasEdited =
        widget.group.label.trim() != _defaultConnectorName(_connectorTypeId);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sekcja wyjsc'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              onChanged: (_) => _labelWasEdited = true,
              decoration: const InputDecoration(labelText: 'Opis'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _connectorTypeId,
              decoration: const InputDecoration(labelText: 'Typ zlacza'),
              items: ConnectorTypes.all
                  .map(
                    (connector) => DropdownMenuItem(
                      value: connector.id,
                      child: Text(connector.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _connectorTypeId = value;
                    if (_isThreePhaseConnector(value)) {
                      _phaseMode = _PresetPhaseMode.all;
                    } else if (_inputIsSinglePhase) {
                      _phaseMode = _PresetPhaseMode.l1Only;
                    } else if (_phaseMode == _PresetPhaseMode.all) {
                      _phaseMode = _PresetPhaseMode.balanced;
                    }
                    _refreshAutoLabel();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ilosc'),
            ),
            const SizedBox(height: 12),
            if (_isThreePhaseConnector(_connectorTypeId))
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Zlacze 3F uzywa wszystkich faz.'),
              )
            else if (_inputIsSinglePhase)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Wejscie 1F uzywa jednej fazy dla wyjsc 1F.'),
              )
            else
              DropdownButtonFormField<_PresetPhaseMode>(
                initialValue: _phaseMode,
                decoration: const InputDecoration(labelText: 'Rozklad faz'),
                items: _PresetPhaseMode.values
                    .where((mode) => mode != _PresetPhaseMode.all)
                    .map(
                      (mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(mode.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _phaseMode = value);
                  }
                },
              ),
          ],
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
    final label = _labelController.text.trim();
    final count = int.tryParse(_countController.text.trim()) ?? 0;
    if (label.isEmpty || count <= 0) {
      return;
    }

    Navigator.of(context).pop(
      _PresetOutletGroup(
        id: widget.group.id,
        label: label,
        connectorTypeId: _connectorTypeId,
        count: count,
        phaseMode: _normalizedPhaseMode,
      ),
    );
  }

  bool get _inputIsSinglePhase =>
      _isSinglePhaseConnector(widget.inputConnectorTypeId);

  _PresetPhaseMode get _normalizedPhaseMode {
    if (_isThreePhaseConnector(_connectorTypeId)) {
      return _PresetPhaseMode.all;
    }
    if (_inputIsSinglePhase) {
      return _PresetPhaseMode.l1Only;
    }
    return _phaseMode == _PresetPhaseMode.all
        ? _PresetPhaseMode.balanced
        : _phaseMode;
  }

  void _normalizePhaseMode() {
    _phaseMode = _normalizedPhaseMode;
  }

  var _labelWasEdited = false;

  void _refreshAutoLabel() {
    if (_labelWasEdited) {
      return;
    }
    _labelController.text = _defaultConnectorName(_connectorTypeId);
  }
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
  required String label,
  required String connectorTypeId,
  required PowerPhase phase,
  required int index,
}) {
  final base = label.trim().isEmpty
      ? _defaultConnectorName(connectorTypeId)
      : label;

  if (phase == PowerPhase.all) {
    return '$base ${index + 1}';
  }

  return '$base ${_phaseLabel(phase)}.${index + 1}';
}

String _connectorLabel(String connectorTypeId) {
  return ConnectorTypes.findById(connectorTypeId)?.label ?? connectorTypeId;
}

bool _isThreePhaseConnector(String connectorTypeId) {
  return ConnectorTypes.findById(connectorTypeId)?.phaseCount == 3;
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

bool _isSinglePhaseConnector(String? connectorTypeId) {
  if (connectorTypeId == null) {
    return false;
  }
  return ConnectorTypes.findById(connectorTypeId)?.phaseCount == 1;
}

List<_PresetOutletGroup> _normalizePresetOutletGroups(
  List<_PresetOutletGroup> groups,
  String? inputConnectorTypeId,
) {
  final inputIsSinglePhase = _isSinglePhaseConnector(inputConnectorTypeId);
  return groups.map((group) {
    final phaseMode = _isThreePhaseConnector(group.connectorTypeId)
        ? _PresetPhaseMode.all
        : inputIsSinglePhase
        ? _PresetPhaseMode.l1Only
        : group.phaseMode == _PresetPhaseMode.all
        ? _PresetPhaseMode.balanced
        : group.phaseMode;
    if (phaseMode == group.phaseMode) {
      return group;
    }
    return _PresetOutletGroup(
      id: group.id,
      label: group.label,
      connectorTypeId: group.connectorTypeId,
      count: group.count,
      phaseMode: phaseMode,
    );
  }).toList();
}

String _phaseLabel(PowerPhase phase) {
  return switch (phase) {
    PowerPhase.l1 => 'L1',
    PowerPhase.l2 => 'L2',
    PowerPhase.l3 => 'L3',
    PowerPhase.all => 'All',
  };
}

class _PresetFormResult {
  const _PresetFormResult({
    required this.name,
    required this.outlets,
    this.inputConnectorTypeId,
  });

  final String name;
  final String? inputConnectorTypeId;
  final List<PowerOutletTemplate> outlets;
}
