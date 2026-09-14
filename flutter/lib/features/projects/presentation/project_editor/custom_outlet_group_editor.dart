part of '../project_editor_screen.dart';

enum _CustomDistroPhaseMode { l1Only, balanced, all }

extension _CustomDistroPhaseModeData on _CustomDistroPhaseMode {
  String get label {
    return switch (this) {
      _CustomDistroPhaseMode.l1Only => 'Wszystkie L1',
      _CustomDistroPhaseMode.balanced => 'L1/L2/L3 grupami',
      _CustomDistroPhaseMode.all => 'Wszystkie 3F / All',
    };
  }

  PowerPhase phaseForIndex(int index, {required int count}) {
    return switch (this) {
      _CustomDistroPhaseMode.l1Only => PowerPhase.l1,
      _CustomDistroPhaseMode.balanced => _phaseByGroupedIndex(index, count),
      _CustomDistroPhaseMode.all => PowerPhase.all,
    };
  }
}

class _CustomOutletGroup {
  const _CustomOutletGroup({
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
  final _CustomDistroPhaseMode phaseMode;
}

List<_CustomOutletGroup> _normalizeCustomOutletGroups(
  List<_CustomOutletGroup> groups,
  String? inputConnectorTypeId,
) {
  final inputIsSinglePhase = _isSinglePhaseConnector(inputConnectorTypeId);
  return groups.map((group) {
    final phaseMode = _isThreePhaseConnector(group.connectorTypeId)
        ? _CustomDistroPhaseMode.all
        : inputIsSinglePhase
        ? _CustomDistroPhaseMode.l1Only
        : group.phaseMode == _CustomDistroPhaseMode.all
        ? _CustomDistroPhaseMode.balanced
        : group.phaseMode;
    if (phaseMode == group.phaseMode) {
      return group;
    }
    return _CustomOutletGroup(
      id: group.id,
      label: group.label,
      connectorTypeId: group.connectorTypeId,
      count: group.count,
      phaseMode: phaseMode,
    );
  }).toList();
}

class _OutletGroupsEditor extends StatelessWidget {
  const _OutletGroupsEditor({
    required this.groups,
    required this.inputConnectorTypeId,
    required this.onChanged,
  });

  final List<_CustomOutletGroup> groups;
  final String? inputConnectorTypeId;
  final ValueChanged<List<_CustomOutletGroup>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sekcje wyjść',
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
            child: Text('Brak sekcji wyjść.'),
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
                    tooltip: 'Edytuj sekcję',
                    onPressed: () => _editGroup(context, group),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Usuń sekcję',
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
    final result = await showDialog<_CustomOutletGroup>(
      context: context,
      builder: (context) => _OutletGroupDialog(
        inputConnectorTypeId: inputConnectorTypeId,
        group: _CustomOutletGroup(
          id: 'group_${DateTime.now().microsecondsSinceEpoch}',
          label: 'Schuko',
          connectorTypeId: 'schuko_16a',
          count: 1,
          phaseMode: _CustomDistroPhaseMode.l1Only,
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
    _CustomOutletGroup group,
  ) async {
    final result = await showDialog<_CustomOutletGroup>(
      context: context,
      builder: (context) => _OutletGroupDialog(
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

class _OutletGroupDialog extends StatefulWidget {
  const _OutletGroupDialog({
    required this.group,
    required this.inputConnectorTypeId,
  });

  final _CustomOutletGroup group;
  final String? inputConnectorTypeId;

  @override
  State<_OutletGroupDialog> createState() => _OutletGroupDialogState();
}

class _OutletGroupDialogState extends State<_OutletGroupDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _countController;
  late String _connectorTypeId;
  late _CustomDistroPhaseMode _phaseMode;

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
      title: const Text('Sekcja wyjść'),
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
              decoration: const InputDecoration(labelText: 'Typ złącza'),
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
                      _phaseMode = _CustomDistroPhaseMode.all;
                    } else if (_inputIsSinglePhase) {
                      _phaseMode = _CustomDistroPhaseMode.l1Only;
                    } else if (_phaseMode == _CustomDistroPhaseMode.all) {
                      _phaseMode = _CustomDistroPhaseMode.balanced;
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
              decoration: const InputDecoration(labelText: 'Ilość'),
            ),
            const SizedBox(height: 12),
            if (_isThreePhaseConnector(_connectorTypeId))
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Złącze 3F używa wszystkich faz.'),
              )
            else if (_inputIsSinglePhase)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Wejście 1F używa jednej fazy dla wyjść 1F.'),
              )
            else
              DropdownButtonFormField<_CustomDistroPhaseMode>(
                initialValue: _phaseMode,
                decoration: const InputDecoration(labelText: 'Rozkład faz'),
                items: _CustomDistroPhaseMode.values
                    .where((mode) => mode != _CustomDistroPhaseMode.all)
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
      _CustomOutletGroup(
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

  _CustomDistroPhaseMode get _normalizedPhaseMode {
    if (_isThreePhaseConnector(_connectorTypeId)) {
      return _CustomDistroPhaseMode.all;
    }
    if (_inputIsSinglePhase) {
      return _CustomDistroPhaseMode.l1Only;
    }
    return _phaseMode == _CustomDistroPhaseMode.all
        ? _CustomDistroPhaseMode.balanced
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
