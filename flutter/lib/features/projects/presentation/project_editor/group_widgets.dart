part of '../project_editor_screen.dart';

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onAddItem,
    required this.onAddCatalogItem,
    required this.onEditGroup,
    required this.onDeleteGroup,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  final ProjectGroup group;
  final VoidCallback onAddItem;
  final VoidCallback onAddCatalogItem;
  final VoidCallback onEditGroup;
  final VoidCallback onDeleteGroup;
  final ValueChanged<ProjectItem> onEditItem;
  final ValueChanged<ProjectItem> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    const totalsService = ProjectTotalsService();
    final totals = totalsService.calculateGroup(group);

    return GreenCrewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Dodaj recznie',
                onPressed: onAddItem,
                icon: const Icon(Icons.add_circle_outline),
              ),
              IconButton(
                tooltip: 'Dodaj z katalogu',
                onPressed: onAddCatalogItem,
                icon: const Icon(Icons.inventory_2_outlined),
              ),
              IconButton(
                tooltip: 'Edytuj grupe',
                onPressed: onEditGroup,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Usun grupe',
                onPressed: onDeleteGroup,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Moc',
                value: '${totals.powerKw.toStringAsFixed(1)} kW',
              ),
              _MetricChip(
                label: 'Prad',
                value: '${totals.currentA.toStringAsFixed(1)} A',
              ),
              _MetricChip(
                label: 'Masa',
                value: '${totals.weightKg.toStringAsFixed(0)} kg',
              ),
            ],
          ),
          const Divider(height: 24),
          if (group.items.isEmpty)
            const Text('Brak pozycji w grupie.')
          else
            for (final item in group.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.nameSnapshot),
                subtitle: Text(
                  [
                    item.manufacturerSnapshot,
                    '${item.quantity.toStringAsFixed(0)} ${_unitLabel(item.unit)}',
                  ].whereType<String>().join(' / '),
                ),
                trailing: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${(item.weightKgSnapshot * item.quantity).toStringAsFixed(1)} kg',
                    ),
                    IconButton(
                      tooltip: 'Edytuj pozycje',
                      onPressed: () => onEditItem(item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Usun pozycje',
                      onPressed: () => onDeleteItem(item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _unitLabel(ProjectItemUnit unit) {
    return switch (unit) {
      ProjectItemUnit.pcs => 'szt.',
      ProjectItemUnit.meters => 'm',
    };
  }
}

class _GroupNameDialog extends StatefulWidget {
  const _GroupNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
  });

  final String title;
  final String confirmLabel;
  final String initialName;

  @override
  State<_GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<_GroupNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nazwa grupy'),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({
    required this.title,
    required this.confirmLabel,
    this.item,
  });

  final String title;
  final String confirmLabel;
  final ProjectItem? item;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  static const _voltageV = 230.0;

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _powerController;
  late final TextEditingController _currentController;
  late final TextEditingController _weightController;
  var _isUpdatingElectricalFields = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(
      text: item?.nameSnapshot ?? 'Pozycja reczna',
    );
    _quantityController = TextEditingController(
      text: (item?.quantity ?? 1).toStringAsFixed(0),
    );
    _powerController = TextEditingController(
      text: (item?.powerWSnapshot ?? 0).toStringAsFixed(0),
    );
    _currentController = TextEditingController(
      text: (item?.currentASnapshot ?? 0).toStringAsFixed(1),
    );
    _weightController = TextEditingController(
      text: (item?.weightKgSnapshot ?? 0).toStringAsFixed(1),
    );
    _powerController.addListener(_syncCurrentFromPower);
    _currentController.addListener(_syncPowerFromCurrent);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _powerController.dispose();
    _currentController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
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
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ilosc',
                suffixText: 'szt.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _powerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Moc',
                suffixText: 'W',
                helperText: 'Przeliczane dla 230 V',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Prad',
                suffixText: 'A',
                helperText: 'Przeliczane dla 230 V',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Masa',
                suffixText: 'kg',
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
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _ItemFormResult(
        name: name,
        quantity: _parseNumber(_quantityController.text, fallback: 1),
        powerW: _parseNumber(_powerController.text),
        currentA: _parseNumber(_currentController.text),
        weightKg: _parseNumber(_weightController.text),
      ),
    );
  }

  double _parseNumber(String value, {double fallback = 0}) {
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized) ?? fallback;
  }

  void _syncCurrentFromPower() {
    if (_isUpdatingElectricalFields) {
      return;
    }

    final powerW = _parseNumberOrNull(_powerController.text);
    if (powerW == null) {
      return;
    }

    _isUpdatingElectricalFields = true;
    _currentController.text = _formatCurrent(powerW / _voltageV);
    _isUpdatingElectricalFields = false;
  }

  void _syncPowerFromCurrent() {
    if (_isUpdatingElectricalFields) {
      return;
    }

    final currentA = _parseNumberOrNull(_currentController.text);
    if (currentA == null) {
      return;
    }

    _isUpdatingElectricalFields = true;
    _powerController.text = _formatPower(currentA * _voltageV);
    _isUpdatingElectricalFields = false;
  }

  double? _parseNumberOrNull(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  String _formatPower(double value) {
    return value.toStringAsFixed(0);
  }

  String _formatCurrent(double value) {
    return value.toStringAsFixed(1);
  }
}

class _ItemFormResult {
  const _ItemFormResult({
    required this.name,
    required this.quantity,
    required this.powerW,
    required this.currentA,
    required this.weightKg,
  });

  final String name;
  final double quantity;
  final double powerW;
  final double currentA;
  final double weightKg;
}
