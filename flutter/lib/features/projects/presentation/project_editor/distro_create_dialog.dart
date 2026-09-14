part of '../project_editor_screen.dart';

class _DistroCreateDialog extends StatefulWidget {
  const _DistroCreateDialog({required this.presets, required this.location});

  final List<PowerPreset> presets;
  final Location? location;

  @override
  State<_DistroCreateDialog> createState() => _DistroCreateDialogState();
}

class _DistroCreateDialogState extends State<_DistroCreateDialog> {
  late final TextEditingController _nameController;
  _DistroCreateMode _mode = _DistroCreateMode.quick;
  _QuickDistroTemplate _quickTemplate = _QuickDistroTemplate.schukoSingle;
  String? _customInputConnectorTypeId = 'cee_32a_5p';
  List<_CustomOutletGroup> _customOutletGroups = const [
    _CustomOutletGroup(
      id: 'default_schuko',
      label: 'Schuko',
      connectorTypeId: 'schuko_16a',
      count: 6,
      phaseMode: _CustomDistroPhaseMode.balanced,
    ),
  ];
  PowerPreset? _selectedPreset;
  LocationPowerConnector? _selectedLocationConnector;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.presets.firstOrNull;
    _selectedLocationConnector = widget.location?.powerConnectors.firstOrNull;
    _nameController = TextEditingController(text: _quickTemplate.label);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPreset = _selectedPreset;
    final selectedOutlets = _selectedOutlets;
    final inputConnectorTypeId = _inputConnectorTypeId;

    return AlertDialog(
      title: const Text('Dodaj rozdzielnice'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<_DistroCreateMode>(
              segments: const [
                ButtonSegment(
                  value: _DistroCreateMode.quick,
                  icon: Icon(Icons.flash_on),
                  label: Text('Szybka'),
                ),
                ButtonSegment(
                  value: _DistroCreateMode.preset,
                  icon: Icon(Icons.inventory_2_outlined),
                  label: Text('Preset'),
                ),
                ButtonSegment(
                  value: _DistroCreateMode.custom,
                  icon: Icon(Icons.tune),
                  label: Text('Custom'),
                ),
                ButtonSegment(
                  value: _DistroCreateMode.location,
                  icon: Icon(Icons.location_city_outlined),
                  label: Text('Lokacja'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() {
                  _mode = selection.single;
                  _nameController.text = switch (_mode) {
                    _DistroCreateMode.quick => _quickTemplate.label,
                    _DistroCreateMode.custom => 'Rozdzielnica custom',
                    _DistroCreateMode.location =>
                      _selectedLocationConnector == null
                          ? 'Zasilanie z lokacji'
                          : '${widget.location?.name ?? 'Lokacja'} / ${_selectedLocationConnector!.name}',
                    _DistroCreateMode.preset =>
                      _selectedPreset?.name ?? 'Nowa rozdzielnica',
                  };
                });
              },
            ),
            const SizedBox(height: 12),
            if (_mode == _DistroCreateMode.quick)
              DropdownButtonFormField<_QuickDistroTemplate>(
                initialValue: _quickTemplate,
                decoration: const InputDecoration(labelText: 'Typ'),
                items: _QuickDistroTemplate.values
                    .map(
                      (template) => DropdownMenuItem(
                        value: template,
                        child: Text(template.label),
                      ),
                    )
                    .toList(),
                onChanged: (template) {
                  if (template != null) {
                    setState(() {
                      _quickTemplate = template;
                      _nameController.text = template.label;
                    });
                  }
                },
              )
            else if (_mode == _DistroCreateMode.custom) ...[
              _connectorDropdown(
                label: 'Wejscie',
                value: _customInputConnectorTypeId,
                allowEmpty: true,
                onChanged: (value) {
                  setState(() {
                    _customInputConnectorTypeId = value;
                    _customOutletGroups = _normalizeCustomOutletGroups(
                      _customOutletGroups,
                      value,
                    );
                  });
                },
              ),
              const SizedBox(height: 12),
              _OutletGroupsEditor(
                groups: _customOutletGroups,
                inputConnectorTypeId: _customInputConnectorTypeId,
                onChanged: (groups) {
                  setState(() {
                    _customOutletGroups = _normalizeCustomOutletGroups(
                      groups,
                      _customInputConnectorTypeId,
                    );
                  });
                },
              ),
            ] else if (_mode == _DistroCreateMode.location) ...[
              if (widget.location == null)
                const Text('Projekt nie ma przypisanej lokacji.')
              else if (widget.location!.powerConnectors.isEmpty)
                const Text('Lokacja nie ma zapisanych grup zlaczy.')
              else
                DropdownButtonFormField<LocationPowerConnector>(
                  initialValue: _selectedLocationConnector,
                  decoration: const InputDecoration(labelText: 'Grupa zlaczy'),
                  items: widget.location!.powerConnectors
                      .map(
                        (connector) => DropdownMenuItem(
                          value: connector,
                          child: Text(
                            '${connector.name} / ${connector.entriesSummary}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (connector) {
                    if (connector != null) {
                      setState(() {
                        _selectedLocationConnector = connector;
                        _nameController.text =
                            '${widget.location!.name} / ${connector.name}';
                      });
                    }
                  },
                ),
            ] else if (widget.presets.isEmpty)
              const Text('Brak presetow rozdzielnic.')
            else
              DropdownButtonFormField<PowerPreset>(
                initialValue: selectedPreset,
                decoration: const InputDecoration(labelText: 'Preset'),
                items: widget.presets
                    .map(
                      (preset) => DropdownMenuItem(
                        value: preset,
                        child: Text(preset.name),
                      ),
                    )
                    .toList(),
                onChanged: (preset) {
                  setState(() {
                    _selectedPreset = preset;
                    if (preset != null) {
                      _nameController.text = preset.name;
                    }
                  });
                },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nazwa'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.input, size: 16),
                    label: Text(_connectorLabel(inputConnectorTypeId)),
                  ),
                  Chip(
                    avatar: const Icon(Icons.power, size: 16),
                    label: Text('${selectedOutlets.length} gniazd'),
                  ),
                  for (final outlet in selectedOutlets)
                    Chip(
                      label: Text(
                        '${outlet.name} ${_connectorLabel(outlet.connectorTypeId)}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Dodaj'),
        ),
      ],
    );
  }

  bool get _canSubmit {
    if (_nameController.text.trim().isEmpty) {
      return false;
    }
    if (_mode == _DistroCreateMode.preset) {
      return _selectedPreset != null;
    }
    if (_mode == _DistroCreateMode.custom) {
      return _customOutletGroups.any((group) => group.count > 0);
    }
    if (_mode == _DistroCreateMode.location) {
      return _selectedLocationConnector != null;
    }
    return true;
  }

  String? get _inputConnectorTypeId {
    return switch (_mode) {
      _DistroCreateMode.quick => _quickTemplate.inputConnectorTypeId,
      _DistroCreateMode.preset => _selectedPreset?.inputConnectorTypeId,
      _DistroCreateMode.custom => _customInputConnectorTypeId,
      _DistroCreateMode.location => null,
    };
  }

  List<PowerOutletTemplate> get _selectedOutlets {
    return switch (_mode) {
      _DistroCreateMode.quick => _quickTemplate.outlets,
      _DistroCreateMode.preset =>
        _selectedPreset?.outlets ?? const <PowerOutletTemplate>[],
      _DistroCreateMode.custom => _customOutlets,
      _DistroCreateMode.location => _locationOutlets,
    };
  }

  List<PowerOutletTemplate> get _locationOutlets {
    final connector = _selectedLocationConnector;
    if (connector == null) {
      return const [];
    }

    final outlets = <PowerOutletTemplate>[];
    for (final entry in connector.entries) {
      final count = entry.quantity.clamp(0, 96).toInt();
      for (var index = 0; index < count; index++) {
        final phase = _phaseForLocationConnectorEntry(entry, index, count);
        outlets.add(
          PowerOutletTemplate(
            id: 'location_${connector.id}_${entry.connectorTypeId}_$index',
            name: _defaultOutletName(
              label: connector.name,
              connectorTypeId: entry.connectorTypeId,
              phase: phase,
              index: index,
            ),
            connectorTypeId: entry.connectorTypeId,
            phase: phase,
          ),
        );
      }
    }
    return outlets;
  }

  List<PowerOutletTemplate> get _customOutlets {
    var globalIndex = 0;
    return [
      for (final group in _normalizeCustomOutletGroups(
        _customOutletGroups,
        _customInputConnectorTypeId,
      ))
        for (var index = 0; index < group.count.clamp(0, 48).toInt(); index++)
          PowerOutletTemplate(
            id: 'custom_${globalIndex++}',
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

  Widget _connectorDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool allowEmpty = false,
  }) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        if (allowEmpty)
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Brak / nieznane'),
          ),
        for (final connector in ConnectorTypes.all)
          DropdownMenuItem<String?>(
            value: connector.id,
            child: Text(connector.label),
          ),
      ],
      onChanged: onChanged,
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    if (_mode == _DistroCreateMode.preset) {
      final preset = _selectedPreset;
      if (preset == null) {
        return;
      }
      Navigator.of(context).pop(
        _DistroCreateResult(
          name: name,
          sourceType: ProjectDistroSourceType.preset,
          inputConnectorTypeId: preset.inputConnectorTypeId,
          outlets: preset.outlets,
          preset: preset,
        ),
      );
      return;
    }

    if (_mode == _DistroCreateMode.custom) {
      Navigator.of(context).pop(
        _DistroCreateResult(
          name: name,
          sourceType: ProjectDistroSourceType.manual,
          inputConnectorTypeId: _customInputConnectorTypeId,
          outlets: _customOutlets,
        ),
      );
      return;
    }

    if (_mode == _DistroCreateMode.location) {
      final connector = _selectedLocationConnector;
      if (connector == null) {
        return;
      }
      Navigator.of(context).pop(
        _DistroCreateResult(
          name: name,
          sourceType: ProjectDistroSourceType.location,
          inputConnectorTypeId: null,
          outlets: _locationOutlets,
          locationConnectorGroupId: connector.id,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _DistroCreateResult(
        name: name,
        sourceType: ProjectDistroSourceType.quick,
        inputConnectorTypeId: _quickTemplate.inputConnectorTypeId,
        outlets: _quickTemplate.outlets,
      ),
    );
  }
}

enum _DistroCreateMode { quick, preset, custom, location }

enum _QuickDistroTemplate {
  schukoSingle,
  schukoQuad,
  cee32SixSchuko,
  cee32Thru,
}

extension _QuickDistroTemplateData on _QuickDistroTemplate {
  String get label {
    return switch (this) {
      _QuickDistroTemplate.schukoSingle => 'Gniazdo 16 A',
      _QuickDistroTemplate.schukoQuad => 'Listwa 4x16 A',
      _QuickDistroTemplate.cee32SixSchuko => 'Rozdzielnia 32 A / 6x Schuko',
      _QuickDistroTemplate.cee32Thru => 'Przedluzka 32 A CEE',
    };
  }

  String? get inputConnectorTypeId {
    return switch (this) {
      _QuickDistroTemplate.schukoSingle => 'schuko_16a',
      _QuickDistroTemplate.schukoQuad => 'schuko_16a',
      _QuickDistroTemplate.cee32SixSchuko => 'cee_32a_5p',
      _QuickDistroTemplate.cee32Thru => 'cee_32a_5p',
    };
  }

  List<PowerOutletTemplate> get outlets {
    return switch (this) {
      _QuickDistroTemplate.schukoSingle => const [
        PowerOutletTemplate(
          id: 'quick_schuko_single',
          name: 'Schuko L1.1',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
      ],
      _QuickDistroTemplate.schukoQuad => const [
        PowerOutletTemplate(
          id: 'quick_schuko_quad_1',
          name: 'Schuko L1.1',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
        PowerOutletTemplate(
          id: 'quick_schuko_quad_2',
          name: 'Schuko L1.2',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
        PowerOutletTemplate(
          id: 'quick_schuko_quad_3',
          name: 'Schuko L1.3',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
        PowerOutletTemplate(
          id: 'quick_schuko_quad_4',
          name: 'Schuko L1.4',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
      ],
      _QuickDistroTemplate.cee32SixSchuko => const [
        PowerOutletTemplate(
          id: 'quick_32a_l1_a',
          name: 'Schuko L1.1',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
        PowerOutletTemplate(
          id: 'quick_32a_l1_b',
          name: 'Schuko L1.2',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
        PowerOutletTemplate(
          id: 'quick_32a_l2_a',
          name: 'Schuko L2.1',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l2,
        ),
        PowerOutletTemplate(
          id: 'quick_32a_l2_b',
          name: 'Schuko L2.2',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l2,
        ),
        PowerOutletTemplate(
          id: 'quick_32a_l3_a',
          name: 'Schuko L3.1',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l3,
        ),
        PowerOutletTemplate(
          id: 'quick_32a_l3_b',
          name: 'Schuko L3.2',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l3,
        ),
      ],
      _QuickDistroTemplate.cee32Thru => const [
        PowerOutletTemplate(
          id: 'quick_32a_thru',
          name: 'CEE 32A OUT',
          connectorTypeId: 'cee_32a_5p',
          phase: PowerPhase.all,
        ),
      ],
    };
  }
}

class _DistroCreateResult {
  const _DistroCreateResult({
    required this.name,
    required this.sourceType,
    required this.inputConnectorTypeId,
    required this.outlets,
    this.preset,
    this.locationConnectorGroupId,
  });

  final String name;
  final ProjectDistroSourceType sourceType;
  final String? inputConnectorTypeId;
  final List<PowerOutletTemplate> outlets;
  final PowerPreset? preset;
  final String? locationConnectorGroupId;
}

PowerPhase _phaseForLocationConnectorEntry(
  LocationConnectorEntry entry,
  int index,
  int count,
) {
  final type = ConnectorTypes.findById(entry.connectorTypeId);
  if (type?.phaseCount == 3) {
    return PowerPhase.all;
  }
  return _phaseByGroupedIndex(index, count);
}
