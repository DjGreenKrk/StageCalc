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
    final outlets = <PowerOutletTemplate>[];
    for (var index = 0; index < result.outletCount; index++) {
      outlets.add(
        PowerOutletTemplate(
          id: 'outlet_${now.microsecondsSinceEpoch}_$index',
          name: 'Gniazdo ${index + 1}',
          connectorTypeId: result.outletConnectorTypeId,
          phase: _phaseForIndex(index),
        ),
      );
    }

    await repository.savePreset(
      PowerPreset(
        id: 'preset_${now.microsecondsSinceEpoch}',
        name: result.name,
        inputConnectorTypeId: result.inputConnectorTypeId,
        outlets: outlets,
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

  PowerPhase _phaseForIndex(int index) {
    return switch (index % 3) {
      0 => PowerPhase.l1,
      1 => PowerPhase.l2,
      _ => PowerPhase.l3,
    };
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
  final _outletCountController = TextEditingController(text: '6');
  String? _inputConnectorTypeId = 'cee_32a_5p';
  String _outletConnectorTypeId = 'schuko_16a';

  @override
  void dispose() {
    _nameController.dispose();
    _outletCountController.dispose();
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
              onChanged: (value) =>
                  setState(() => _inputConnectorTypeId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _outletConnectorTypeId,
              decoration: const InputDecoration(labelText: 'Typ gniazd'),
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
                  setState(() => _outletConnectorTypeId = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _outletCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Liczba gniazd'),
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
    final outletCount = int.tryParse(_outletCountController.text.trim()) ?? 0;
    if (name.isEmpty || outletCount <= 0) {
      return;
    }

    Navigator.of(context).pop(
      _PresetFormResult(
        name: name,
        inputConnectorTypeId: _inputConnectorTypeId,
        outletConnectorTypeId: _outletConnectorTypeId,
        outletCount: outletCount,
      ),
    );
  }
}

class _PresetFormResult {
  const _PresetFormResult({
    required this.name,
    required this.outletConnectorTypeId,
    required this.outletCount,
    this.inputConnectorTypeId,
  });

  final String name;
  final String? inputConnectorTypeId;
  final String outletConnectorTypeId;
  final int outletCount;
}
