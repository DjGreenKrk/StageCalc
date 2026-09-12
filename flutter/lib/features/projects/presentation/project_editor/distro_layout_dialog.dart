part of '../project_editor_screen.dart';

class _DistroLayoutDialog extends StatefulWidget {
  const _DistroLayoutDialog({required this.distro});

  final ProjectDistro distro;

  @override
  State<_DistroLayoutDialog> createState() => _DistroLayoutDialogState();
}

class _DistroLayoutDialogState extends State<_DistroLayoutDialog> {
  late final TextEditingController _nameController;
  late String? _inputConnectorTypeId;
  late List<ProjectOutlet> _outlets;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.distro.name);
    _inputConnectorTypeId = widget.distro.inputConnectorTypeId;
    _outlets = [...widget.distro.outlets];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edytuj rozdzielnice'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
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
                    child: Text('Brak / nieznane'),
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
                    _outlets = _normalizeOutletPhases(_outlets);
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gniazda',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _outlets.isEmpty ? null : _autoAssignPhases,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Auto fazy'),
                  ),
                  TextButton.icon(
                    onPressed: _addOutlet,
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_outlets.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Brak gniazd.'),
                )
              else
                for (final outlet in _outlets) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(outlet.name),
                    subtitle: Text(
                      '${_connectorLabel(outlet.connectorTypeId)} / ${_phaseLabel(outlet.phase)} / '
                      '${outlet.maxCurrentA.toStringAsFixed(0)} A',
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Edytuj gniazdo',
                          onPressed: () => _editOutlet(outlet),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Usun gniazdo',
                          onPressed: () {
                            setState(() {
                              _outlets = _outlets
                                  .where(
                                    (candidate) => candidate.id != outlet.id,
                                  )
                                  .toList();
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
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

  Future<void> _addOutlet() async {
    final connector = ConnectorTypes.findById('schuko_16a');
    final result = await showDialog<ProjectOutlet>(
      context: context,
      builder: (context) => _OutletEditDialog(
        inputConnectorTypeId: _inputConnectorTypeId,
        outletIndex: _outlets.length,
        outlet: ProjectOutlet(
          id: 'outlet_${DateTime.now().microsecondsSinceEpoch}',
          name: _defaultOutletName(
            connectorTypeId: 'schuko_16a',
            phase: PowerPhase.l1,
            index: _outlets.length,
          ),
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
          maxCurrentA: connector?.maxCurrentA ?? 16,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() => _outlets = [..._outlets, result]);
  }

  Future<void> _editOutlet(ProjectOutlet outlet) async {
    final result = await showDialog<ProjectOutlet>(
      context: context,
      builder: (context) => _OutletEditDialog(
        outlet: outlet,
        inputConnectorTypeId: _inputConnectorTypeId,
        outletIndex: _outlets.indexWhere(
          (candidate) => candidate.id == outlet.id,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _outlets = _outlets
          .map((candidate) => candidate.id == result.id ? result : candidate)
          .toList();
    });
  }

  void _autoAssignPhases() {
    setState(() {
      _outlets = _autoAssignOutletPhases(
        _outlets,
        inputConnectorTypeId: _inputConnectorTypeId,
      );
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _DistroLayoutResult(
        name: name,
        inputConnectorTypeId: _inputConnectorTypeId,
        outlets: _normalizeOutletPhases(_outlets),
      ),
    );
  }

  List<ProjectOutlet> _normalizeOutletPhases(List<ProjectOutlet> outlets) {
    return outlets.map((outlet) {
      final phase = _normalizedOutletPhase(
        connectorTypeId: outlet.connectorTypeId,
        phase: outlet.phase,
        inputConnectorTypeId: _inputConnectorTypeId,
      );
      if (phase == outlet.phase) {
        return outlet;
      }
      return outlet.copyWith(phase: phase);
    }).toList();
  }
}

class _OutletEditDialog extends StatefulWidget {
  const _OutletEditDialog({
    required this.outlet,
    required this.inputConnectorTypeId,
    required this.outletIndex,
  });

  final ProjectOutlet outlet;
  final String? inputConnectorTypeId;
  final int outletIndex;

  @override
  State<_OutletEditDialog> createState() => _OutletEditDialogState();
}

class _OutletEditDialogState extends State<_OutletEditDialog> {
  late final TextEditingController _nameController;
  late String _connectorTypeId;
  late PowerPhase _phase;
  var _nameWasEdited = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.outlet.name);
    _connectorTypeId = widget.outlet.connectorTypeId;
    _phase = widget.outlet.phase;
    _normalizePhase();
    _nameWasEdited =
        widget.outlet.name.trim() !=
        _defaultOutletName(
          connectorTypeId: _connectorTypeId,
          phase: _normalizedPhase,
          index: widget.outletIndex < 0 ? 0 : widget.outletIndex,
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edytuj gniazdo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              onChanged: (_) => _nameWasEdited = true,
              decoration: const InputDecoration(labelText: 'Nazwa'),
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
                      _phase = PowerPhase.all;
                    } else if (_inputIsSinglePhase) {
                      _phase = PowerPhase.l1;
                    } else if (_phase == PowerPhase.all) {
                      _phase = PowerPhase.l1;
                    }
                    _refreshAutoName();
                  });
                }
              },
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
              DropdownButtonFormField<PowerPhase>(
                initialValue: _phase == PowerPhase.all ? PowerPhase.l1 : _phase,
                decoration: const InputDecoration(labelText: 'Faza'),
                items: const [PowerPhase.l1, PowerPhase.l2, PowerPhase.l3]
                    .map(
                      (phase) => DropdownMenuItem(
                        value: phase,
                        child: Text(_phaseLabel(phase)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _phase = value;
                      _refreshAutoName();
                    });
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
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final connector = ConnectorTypes.findById(_connectorTypeId);
    Navigator.of(context).pop(
      ProjectOutlet(
        id: widget.outlet.id,
        templateOutletId: widget.outlet.templateOutletId,
        name: name,
        connectorTypeId: _connectorTypeId,
        phase: _normalizedPhase,
        maxCurrentA: connector?.maxCurrentA ?? widget.outlet.maxCurrentA,
      ),
    );
  }

  bool get _inputIsSinglePhase =>
      _isSinglePhaseConnector(widget.inputConnectorTypeId);

  PowerPhase get _normalizedPhase => _normalizedOutletPhase(
    connectorTypeId: _connectorTypeId,
    phase: _phase,
    inputConnectorTypeId: widget.inputConnectorTypeId,
  );

  void _normalizePhase() {
    _phase = _normalizedPhase;
  }

  void _refreshAutoName() {
    if (_nameWasEdited) {
      return;
    }
    _nameController.text = _defaultOutletName(
      connectorTypeId: _connectorTypeId,
      phase: _normalizedPhase,
      index: widget.outletIndex < 0 ? 0 : widget.outletIndex,
    );
  }
}

class _DistroLayoutResult {
  const _DistroLayoutResult({
    required this.name,
    required this.inputConnectorTypeId,
    required this.outlets,
  });

  final String name;
  final String? inputConnectorTypeId;
  final List<ProjectOutlet> outlets;
}

List<ProjectOutlet> _autoAssignOutletPhases(
  List<ProjectOutlet> outlets, {
  required String? inputConnectorTypeId,
}) {
  final inputIsSinglePhase = _isSinglePhaseConnector(inputConnectorTypeId);
  final assignableOutletIds = outlets
      .where((outlet) => !_isThreePhaseConnector(outlet.connectorTypeId))
      .map((outlet) => outlet.id)
      .toList();

  var assignableIndex = 0;
  return outlets.map((outlet) {
    final phase = _isThreePhaseConnector(outlet.connectorTypeId)
        ? PowerPhase.all
        : inputIsSinglePhase
        ? PowerPhase.l1
        : _phaseByGroupedIndex(assignableIndex++, assignableOutletIds.length);
    return outlet.copyWith(phase: phase);
  }).toList();
}
