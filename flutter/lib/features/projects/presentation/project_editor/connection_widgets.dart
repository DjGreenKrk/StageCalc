part of '../project_editor_screen.dart';

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.connection,
    required this.project,
    required this.patchValidation,
    required this.onDelete,
  });

  final PowerConnection connection;
  final Project project;
  final PatchValidationResult patchValidation;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final group = project.groups
        .where((candidate) => candidate.id == connection.targetGroupId)
        .firstOrNull;
    final targetDistro = project.distros
        .where((candidate) => candidate.id == connection.targetDistroId)
        .firstOrNull;
    final distro = project.distros
        .where((candidate) => candidate.id == connection.sourceDistroId)
        .firstOrNull;
    final outlet = distro?.outlets
        .where((candidate) => candidate.id == connection.sourceOutletId)
        .firstOrNull;
    final duplicated = patchValidation.isOutletDuplicated(
      connection.sourceOutletId,
    );

    return GreenCrewCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group?.name ??
                      targetDistro?.name ??
                      'Nieznany cel polaczenia',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${distro?.name ?? 'Brak rozdzielnicy'} / ${outlet?.name ?? 'Brak gniazda'}'
                  ' -> ${connection.targetType == PowerConnectionTargetType.distro ? 'rozdzielnica' : 'grupa'}',
                ),
                if (duplicated) ...[
                  const SizedBox(height: 8),
                  const Chip(
                    avatar: Icon(Icons.link_off, size: 16),
                    label: Text('Gniazdo uzyte wiele razy'),
                  ),
                ],
                if (connection.selectedPhases.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final phase in connection.selectedPhases)
                        Chip(label: Text(_phaseLabel(phase))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Usun polaczenie',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _ConnectionDialog extends StatefulWidget {
  const _ConnectionDialog({required this.project});

  final Project project;

  @override
  State<_ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<_ConnectionDialog> {
  late PowerConnectionTargetType _targetType;
  String? _groupId;
  String? _targetDistroId;
  String? _outletKey;
  final Set<String> _selectedOutletKeys = {};
  final Set<PowerPhase> _selectedPhases = {PowerPhase.l1};
  var _allowOccupiedOutlet = false;

  @override
  void initState() {
    super.initState();
    _targetType = widget.project.groups.isNotEmpty
        ? PowerConnectionTargetType.group
        : PowerConnectionTargetType.distro;
    _groupId = widget.project.groups.firstOrNull?.id;
    _targetDistroId = _availableTargetDistros.firstOrNull?.id;
    _selectFirstAvailableOutlet();
  }

  @override
  Widget build(BuildContext context) {
    final outletOptions = _outletOptions;
    final selectedOutletOptions = _selectedOutletOptions;
    final hasOccupiedOutlet = _matchingOutletOptions.any(
      (option) => _isOutletOccupied(option.outlet.id),
    );
    final showPhaseSelector =
        _targetType == PowerConnectionTargetType.group &&
        selectedOutletOptions.any(
          (option) => option.outlet.phase == PowerPhase.all,
        );
    final canSubmit = _hasValidTarget && selectedOutletOptions.isNotEmpty;

    return AlertDialog(
      title: const Text('Polacz'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<PowerConnectionTargetType>(
              segments: const [
                ButtonSegment(
                  value: PowerConnectionTargetType.group,
                  icon: Icon(Icons.view_module_outlined),
                  label: Text('Grupa'),
                ),
                ButtonSegment(
                  value: PowerConnectionTargetType.distro,
                  icon: Icon(Icons.electrical_services),
                  label: Text('Rozdzielnica'),
                ),
              ],
              selected: {_targetType},
              onSelectionChanged: (selection) {
                setState(() {
                  _targetType = selection.single;
                  _selectFirstAvailableOutlet();
                });
              },
            ),
            const SizedBox(height: 12),
            if (_targetType == PowerConnectionTargetType.group)
              DropdownButtonFormField<String>(
                initialValue: _groupId,
                decoration: const InputDecoration(labelText: 'Grupa'),
                items: widget.project.groups
                    .map(
                      (group) => DropdownMenuItem(
                        value: group.id,
                        child: Text(group.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _groupId = value;
                      _selectFirstAvailableOutlet();
                    });
                  }
                },
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _targetDistroId,
                decoration: const InputDecoration(
                  labelText: 'Rozdzielnica podrzedna',
                ),
                items: _availableTargetDistros
                    .map(
                      (distro) => DropdownMenuItem(
                        value: distro.id,
                        child: Text(
                          '${distro.name} / wejscie ${_connectorLabel(distro.inputConnectorTypeId)}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _targetDistroId = value;
                      _selectFirstAvailableOutlet();
                    });
                  }
                },
              ),
            const SizedBox(height: 12),
            if (hasOccupiedOutlet) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _allowOccupiedOutlet,
                title: const Text('Pokaz uzyte zlacza'),
                subtitle: const Text('Pozwala nadpisac istniejace polaczenie.'),
                onChanged: (value) {
                  setState(() {
                    _allowOccupiedOutlet = value;
                    _selectFirstAvailableOutlet();
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            if (outletOptions.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Brak pasujacych wolnych gniazd.'),
              )
            else if (_targetType == PowerConnectionTargetType.group) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gniazda',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedOutletKeys
                          ..clear()
                          ..addAll(outletOptions.map((option) => option.key));
                      });
                    },
                    child: const Text('Wybierz wszystkie'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedOutletKeys.clear());
                    },
                    child: const Text('Wyczysc'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (final option in outletOptions)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _selectedOutletKeys.contains(option.key),
                  title: Text(
                    '${option.distro.name} / ${option.outlet.name} '
                    '${_phaseLabel(option.outlet.phase)}'
                    '${_isOutletOccupied(option.outlet.id) ? ' zajete' : ''}',
                  ),
                  onChanged: (selected) {
                    setState(() {
                      if (selected ?? false) {
                        _selectedOutletKeys.add(option.key);
                      } else {
                        _selectedOutletKeys.remove(option.key);
                      }
                    });
                  },
                ),
            ] else
              DropdownButtonFormField<String>(
                initialValue: _outletKey,
                decoration: const InputDecoration(labelText: 'Gniazdo'),
                items: [
                  for (final option in outletOptions)
                    DropdownMenuItem(
                      value: option.key,
                      child: Text(
                        '${option.distro.name} / ${option.outlet.name} '
                        '${_phaseLabel(option.outlet.phase)}'
                        '${_isOutletOccupied(option.outlet.id) ? ' zajete' : ''}',
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _outletKey = value);
                  }
                },
              ),
            if (showPhaseSelector) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final phase in [
                      PowerPhase.l1,
                      PowerPhase.l2,
                      PowerPhase.l3,
                    ])
                      FilterChip(
                        label: Text(_phaseLabel(phase)),
                        selected: _selectedPhases.contains(phase),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPhases.add(phase);
                            } else if (_selectedPhases.length > 1) {
                              _selectedPhases.remove(phase);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: canSubmit ? _submit : null,
          child: const Text('Polacz'),
        ),
      ],
    );
  }

  bool get _hasValidTarget {
    return switch (_targetType) {
      PowerConnectionTargetType.group => _groupId != null,
      PowerConnectionTargetType.distro => _targetDistroId != null,
    };
  }

  List<ProjectDistro> get _availableTargetDistros {
    return widget.project.distros
        .where((distro) => distro.inputConnectorTypeId != null)
        .toList();
  }

  List<_OutletOption> get _outletOptions {
    final options = _matchingOutletOptions;
    if (_allowOccupiedOutlet) {
      return options;
    }
    return options
        .where((option) => !_isOutletOccupied(option.outlet.id))
        .toList();
  }

  List<_OutletOption> get _matchingOutletOptions {
    final targetDistroId = _targetDistroId;
    final targetDistro = targetDistroId == null
        ? null
        : widget.project.distros
              .where((distro) => distro.id == targetDistroId)
              .firstOrNull;
    final requiredConnectorTypeId =
        _targetType == PowerConnectionTargetType.distro
        ? targetDistro?.inputConnectorTypeId
        : null;
    final options = <_OutletOption>[];

    for (final distro in widget.project.distros) {
      if (_targetType == PowerConnectionTargetType.distro &&
          distro.id == targetDistroId) {
        continue;
      }
      for (final outlet in distro.outlets) {
        if (requiredConnectorTypeId != null &&
            outlet.connectorTypeId != requiredConnectorTypeId) {
          continue;
        }
        options.add(_OutletOption(distro: distro, outlet: outlet));
      }
    }

    return options;
  }

  void _selectFirstAvailableOutlet() {
    final options = _outletOptions;
    if (options.isEmpty) {
      _outletKey = null;
      _selectedOutletKeys.clear();
      return;
    }

    if (_targetType == PowerConnectionTargetType.group) {
      final validKeys = options.map((option) => option.key).toSet();
      _selectedOutletKeys.removeWhere((key) => !validKeys.contains(key));
      if (_selectedOutletKeys.isEmpty) {
        _selectedOutletKeys.add(options.first.key);
      }
      _outletKey = null;
      return;
    }

    _selectedOutletKeys.clear();
    if (_outletKey != null &&
        options.any((option) => option.key == _outletKey)) {
      return;
    }

    _outletKey = options.first.key;
  }

  bool _isOutletOccupied(String outletId) {
    return widget.project.connections.any(
      (connection) => connection.sourceOutletId == outletId,
    );
  }

  List<_OutletOption> get _selectedOutletOptions {
    if (_targetType == PowerConnectionTargetType.group) {
      return _outletOptions
          .where((option) => _selectedOutletKeys.contains(option.key))
          .toList();
    }

    final outletKey = _outletKey;
    if (outletKey == null) {
      return const [];
    }
    final option = _outletOptions
        .where((candidate) => candidate.key == outletKey)
        .firstOrNull;
    return option == null ? const [] : [option];
  }

  void _submit() {
    final selectedOptions = _selectedOutletOptions;
    if (selectedOptions.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _ConnectionResult(
        targetType: _targetType,
        targetGroupId: _targetType == PowerConnectionTargetType.group
            ? _groupId
            : null,
        targetDistroId: _targetType == PowerConnectionTargetType.distro
            ? _targetDistroId
            : null,
        sources: [
          for (final option in selectedOptions)
            _ConnectionSourceResult(
              sourceDistroId: option.distro.id,
              sourceOutletId: option.outlet.id,
            ),
        ],
        selectedPhases:
            _targetType == PowerConnectionTargetType.group &&
                selectedOptions.any(
                  (option) => option.outlet.phase == PowerPhase.all,
                )
            ? _selectedPhases.toList()
            : const [],
      ),
    );
  }
}

class _OutletOption {
  const _OutletOption({required this.distro, required this.outlet});

  final ProjectDistro distro;
  final ProjectOutlet outlet;

  String get key => '${distro.id}|${outlet.id}';
}

class _ConnectionResult {
  const _ConnectionResult({
    required this.targetType,
    required this.sources,
    required this.selectedPhases,
    this.targetGroupId,
    this.targetDistroId,
  });

  final PowerConnectionTargetType targetType;
  final String? targetGroupId;
  final String? targetDistroId;
  final List<_ConnectionSourceResult> sources;
  final List<PowerPhase> selectedPhases;
}

class _ConnectionSourceResult {
  const _ConnectionSourceResult({
    required this.sourceDistroId,
    required this.sourceOutletId,
  });

  final String sourceDistroId;
  final String sourceOutletId;
}
