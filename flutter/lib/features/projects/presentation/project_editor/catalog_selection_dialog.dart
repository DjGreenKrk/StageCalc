part of '../project_editor_screen.dart';

class _CatalogSelectionDialog extends StatefulWidget {
  const _CatalogSelectionDialog({required this.devices});

  final List<CatalogDevice> devices;

  @override
  State<_CatalogSelectionDialog> createState() =>
      _CatalogSelectionDialogState();
}

class _CatalogSelectionDialogState extends State<_CatalogSelectionDialog> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  CatalogDeviceCategory? _category;
  CatalogDevice? _selectedDevice;

  List<CatalogDevice> get _filteredDevices {
    final query = _searchController.text.trim().toLowerCase();
    return widget.devices.where((device) {
      final manufacturer = device.manufacturer ?? '';
      final matchesQuery =
          query.isEmpty ||
          device.name.toLowerCase().contains(query) ||
          manufacturer.toLowerCase().contains(query);
      final matchesCategory = _category == null || device.category == _category;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedDevice = widget.devices.firstOrNull;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDevices = _filteredDevices;
    final selectedDevice = _selectedDevice;

    return AlertDialog(
      title: const Text('Dodaj z katalogu'),
      content: widget.devices.isEmpty
          ? const Text('Katalog jest pusty.')
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Szukaj',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {
                      final nextDevices = _filteredDevices;
                      final selectedStillVisible = nextDevices.any(
                        (device) => device.id == _selectedDevice?.id,
                      );
                      if (!selectedStillVisible) {
                        _selectedDevice = nextDevices.firstOrNull;
                      }
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CatalogDeviceCategory?>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Kategoria'),
                    items: [
                      const DropdownMenuItem<CatalogDeviceCategory?>(
                        value: null,
                        child: Text('Wszystkie'),
                      ),
                      for (final category in CatalogDeviceCategory.values)
                        DropdownMenuItem<CatalogDeviceCategory?>(
                          value: category,
                          child: Text(_categoryLabel(category)),
                        ),
                    ],
                    onChanged: (category) {
                      setState(() {
                        _category = category;
                        final nextDevices = _filteredDevices;
                        final selectedStillVisible = nextDevices.any(
                          (device) => device.id == _selectedDevice?.id,
                        );
                        if (!selectedStillVisible) {
                          _selectedDevice = nextDevices.firstOrNull;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (filteredDevices.isEmpty)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Brak wyników.'),
                    )
                  else
                    SizedBox(
                      height: 220,
                      width: double.maxFinite,
                      child: ListView.separated(
                        itemCount: filteredDevices.length,
                        separatorBuilder: (context, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final device = filteredDevices[index];
                          final selected = device.id == selectedDevice?.id;
                          return ListTile(
                            selected: selected,
                            contentPadding: EdgeInsets.zero,
                            title: Text(device.name),
                            subtitle: Text(
                              [
                                device.manufacturer,
                                _categoryLabel(device.category),
                              ].whereType<String>().join(' / '),
                            ),
                            trailing: selected ? const Icon(Icons.check) : null,
                            onTap: () {
                              setState(() => _selectedDevice = device);
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final quantity in [1, 2, 4, 6, 8, 12])
                          ActionChip(
                            label: Text('$quantity'),
                            onPressed: () {
                              _quantityController.text = '$quantity';
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ilość',
                      suffixText: selectedDevice == null
                          ? null
                          : _unitLabel(selectedDevice.quantityUnit),
                    ),
                  ),
                  if (selectedDevice != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetricChip(
                            label: 'Moc',
                            value:
                                '${(selectedDevice.powerW / 1000).toStringAsFixed(1)} kW',
                          ),
                          _MetricChip(
                            label: 'Prąd',
                            value:
                                '${selectedDevice.currentA.toStringAsFixed(1)} A',
                          ),
                          _MetricChip(
                            label: 'Masa',
                            value:
                                '${selectedDevice.weightKg.toStringAsFixed(1)} kg',
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
          onPressed: selectedDevice == null ? null : _submit,
          child: const Text('Dodaj'),
        ),
      ],
    );
  }

  void _submit() {
    final selectedDevice = _selectedDevice;
    if (selectedDevice == null) {
      return;
    }

    Navigator.of(context).pop(
      _CatalogSelectionResult(
        device: selectedDevice,
        quantity: _parseNumber(_quantityController.text, fallback: 1),
      ),
    );
  }

  double _parseNumber(String value, {double fallback = 0}) {
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized) ?? fallback;
  }

  String _unitLabel(CatalogQuantityUnit unit) {
    return switch (unit) {
      CatalogQuantityUnit.pcs => 'szt.',
      CatalogQuantityUnit.meters => 'm',
    };
  }

  String _categoryLabel(CatalogDeviceCategory category) {
    return switch (category) {
      CatalogDeviceCategory.lighting => 'Oświetlenie',
      CatalogDeviceCategory.sound => 'Nagłośnienie',
      CatalogDeviceCategory.multimedia => 'Multimedia',
      CatalogDeviceCategory.distribution => 'Rozdzielnia',
      CatalogDeviceCategory.cable => 'Kabel',
      CatalogDeviceCategory.rigging => 'Rigging',
      CatalogDeviceCategory.other => 'Inne',
    };
  }
}

class _CatalogSelectionResult {
  const _CatalogSelectionResult({required this.device, required this.quantity});

  final CatalogDevice device;
  final double quantity;
}
