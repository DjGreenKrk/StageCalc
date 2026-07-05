import 'package:flutter/material.dart';

import '../../../infrastructure/local_database/app_database_provider.dart';
import '../../../shared/models/offline_sync_status.dart';
import '../../../shared/widgets/greencrew_card.dart';
import '../../../shared/widgets/greencrew_empty_state.dart';
import '../../../shared/widgets/greencrew_fab.dart';
import '../../../shared/widgets/greencrew_search_bar.dart';
import '../../../shared/widgets/greencrew_section_header.dart';
import '../../power_presets/presentation/power_presets_panel.dart';
import '../data/catalog_repository.dart';
import '../data/drift_catalog_repository.dart';
import '../domain/entities/catalog_device.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  CatalogRepository? _repository;
  List<CatalogDevice> _devices = const [];
  var _view = _CatalogView.devices;
  var _query = '';
  var _isLoading = true;
  String? _error;

  List<CatalogDevice> get _filteredDevices {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return _devices;
    }

    return _devices.where((device) {
      final manufacturer = device.manufacturer ?? '';
      return device.name.toLowerCase().contains(normalizedQuery) ||
          manufacturer.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = DriftCatalogRepository(AppDatabaseProvider.instance);
      await repository.ensureSeedData();
      final devices = await repository.getDevices();

      if (!mounted) {
        return;
      }

      setState(() {
        _repository = repository;
        _devices = devices;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Nie udalo sie wczytac katalogu. Dane lokalne pozostaly bez zmian.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDevices = _filteredDevices;

    return Scaffold(
      floatingActionButton: _view == _CatalogView.devices
          ? GreenCrewFab(
              label: 'Dodaj urzadzenie',
              icon: Icons.add,
              onPressed: _isLoading ? null : () => _openDeviceDialog(),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GreenCrewSectionHeader(title: 'Katalog'),
          const SizedBox(height: 12),
          SegmentedButton<_CatalogView>(
            segments: const [
              ButtonSegment(
                value: _CatalogView.devices,
                icon: Icon(Icons.inventory_2_outlined),
                label: Text('Urzadzenia'),
              ),
              ButtonSegment(
                value: _CatalogView.presets,
                icon: Icon(Icons.electrical_services_outlined),
                label: Text('Presety'),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (selection) {
              setState(() => _view = selection.single);
            },
          ),
          const SizedBox(height: 16),
          if (_view == _CatalogView.devices) ...[
            GreenCrewSearchBar(
              hintText: 'Szukaj urzadzenia',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SizedBox(
                height: 360,
                child: GreenCrewEmptyState(
                  icon: Icons.error_outline,
                  title: 'Blad danych',
                  message: _error!,
                  actionLabel: 'Sprobuj ponownie',
                  onAction: _loadDevices,
                ),
              )
            else if (filteredDevices.isEmpty)
              GreenCrewCard(
                child: GreenCrewEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Brak urzadzen',
                  message: _query.isEmpty
                      ? 'Dodaj urzadzenia i rozdzielnie, aby uzywac ich w projektach.'
                      : 'Zmien zapytanie albo dodaj nowe urzadzenie.',
                  actionLabel: 'Dodaj urzadzenie',
                  onAction: () => _openDeviceDialog(),
                ),
              )
            else
              for (final device in filteredDevices) ...[
                _CatalogDeviceCard(
                  device: device,
                  onEdit: () => _openDeviceDialog(device: device),
                  onDelete: () => _deleteDevice(device),
                ),
                const SizedBox(height: 12),
              ],
          ] else
            const PowerPresetsPanel(),
        ],
      ),
    );
  }

  Future<void> _openDeviceDialog({CatalogDevice? device}) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final result = await showDialog<_CatalogDeviceFormResult>(
      context: context,
      builder: (context) => _CatalogDeviceDialog(device: device),
    );

    if (result == null) {
      return;
    }

    final now = DateTime.now();
    final savedDevice = CatalogDevice(
      id: device?.id ?? 'device_${now.microsecondsSinceEpoch}',
      name: result.name,
      manufacturer: result.manufacturer,
      category: result.category,
      powerW: result.powerW,
      currentA: result.currentA,
      weightKg: result.weightKg,
      connectorTypeId: result.connectorTypeId,
      quantityUnit: result.quantityUnit,
      createdAt: device?.createdAt ?? now,
      updatedAt: now,
      syncStatus: device?.syncStatus ?? OfflineSyncStatus.localOnly,
    );

    await repository.saveDevice(savedDevice);
    final devices = await repository.getDevices();

    if (!mounted) {
      return;
    }

    setState(() => _devices = devices);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Katalog zapisany lokalnie')));
  }

  Future<void> _deleteDevice(CatalogDevice device) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunac urzadzenie?'),
        content: Text(
          '"${device.name}" zostanie usuniete z katalogu lokalnego.',
        ),
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

    await repository.deleteDevice(device.id);
    final devices = await repository.getDevices();

    if (!mounted) {
      return;
    }

    setState(() => _devices = devices);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Urzadzenie usuniete lokalnie')),
    );
  }
}

enum _CatalogView { devices, presets }

class _CatalogDeviceCard extends StatelessWidget {
  const _CatalogDeviceCard({
    required this.device,
    required this.onEdit,
    required this.onDelete,
  });

  final CatalogDevice device;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final manufacturer = device.manufacturer;

    return GreenCrewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  device.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Edytuj urzadzenie',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Usun urzadzenie',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          if (manufacturer != null && manufacturer.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(manufacturer),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                icon: Icons.bolt,
                label: '${(device.powerW / 1000).toStringAsFixed(1)} kW',
              ),
              _MetricChip(
                icon: Icons.electrical_services,
                label: '${device.currentA.toStringAsFixed(1)} A',
              ),
              _MetricChip(
                icon: Icons.scale,
                label: '${device.weightKg.toStringAsFixed(1)} kg',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatalogDeviceDialog extends StatefulWidget {
  const _CatalogDeviceDialog({this.device});

  final CatalogDevice? device;

  @override
  State<_CatalogDeviceDialog> createState() => _CatalogDeviceDialogState();
}

class _CatalogDeviceDialogState extends State<_CatalogDeviceDialog> {
  static const _voltageV = 230.0;

  late final TextEditingController _nameController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _powerController;
  late final TextEditingController _currentController;
  late final TextEditingController _weightController;
  late final TextEditingController _connectorController;
  late CatalogDeviceCategory _category;
  late CatalogQuantityUnit _quantityUnit;
  var _isUpdatingElectricalFields = false;

  @override
  void initState() {
    super.initState();
    final device = widget.device;
    _nameController = TextEditingController(text: device?.name ?? '');
    _manufacturerController = TextEditingController(
      text: device?.manufacturer ?? '',
    );
    _powerController = TextEditingController(
      text: (device?.powerW ?? 0).toStringAsFixed(0),
    );
    _currentController = TextEditingController(
      text: (device?.currentA ?? 0).toStringAsFixed(1),
    );
    _weightController = TextEditingController(
      text: (device?.weightKg ?? 0).toStringAsFixed(1),
    );
    _connectorController = TextEditingController(
      text: device?.connectorTypeId ?? '',
    );
    _powerController.addListener(_syncCurrentFromPower);
    _currentController.addListener(_syncPowerFromCurrent);
    _category = device?.category ?? CatalogDeviceCategory.device;
    _quantityUnit = device?.quantityUnit ?? CatalogQuantityUnit.pcs;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _powerController.dispose();
    _currentController.dispose();
    _weightController.dispose();
    _connectorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.device == null ? 'Dodaj urzadzenie' : 'Edytuj urzadzenie',
      ),
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
              controller: _manufacturerController,
              decoration: const InputDecoration(labelText: 'Producent'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CatalogDeviceCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategoria'),
              items: CatalogDeviceCategory.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(_categoryLabel(category)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
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
            const SizedBox(height: 12),
            TextField(
              controller: _connectorController,
              decoration: const InputDecoration(labelText: 'Typ zlacza'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CatalogQuantityUnit>(
              initialValue: _quantityUnit,
              decoration: const InputDecoration(labelText: 'Jednostka'),
              items: CatalogQuantityUnit.values
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(_unitLabel(unit)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _quantityUnit = value);
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
        FilledButton(
          onPressed: _submit,
          child: Text(widget.device == null ? 'Dodaj' : 'Zapisz'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _CatalogDeviceFormResult(
        name: name,
        manufacturer: _emptyToNull(_manufacturerController.text),
        category: _category,
        powerW: _parseNumber(_powerController.text),
        currentA: _parseNumber(_currentController.text),
        weightKg: _parseNumber(_weightController.text),
        connectorTypeId: _emptyToNull(_connectorController.text),
        quantityUnit: _quantityUnit,
      ),
    );
  }

  double _parseNumber(String value) {
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
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

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _categoryLabel(CatalogDeviceCategory category) {
    return switch (category) {
      CatalogDeviceCategory.device => 'Urzadzenie',
      CatalogDeviceCategory.distribution => 'Rozdzielnia',
      CatalogDeviceCategory.cable => 'Kabel',
      CatalogDeviceCategory.rigging => 'Rigging',
      CatalogDeviceCategory.other => 'Inne',
    };
  }

  String _unitLabel(CatalogQuantityUnit unit) {
    return switch (unit) {
      CatalogQuantityUnit.pcs => 'szt.',
      CatalogQuantityUnit.meters => 'm',
    };
  }
}

class _CatalogDeviceFormResult {
  const _CatalogDeviceFormResult({
    required this.name,
    required this.category,
    required this.powerW,
    required this.currentA,
    required this.weightKg,
    required this.quantityUnit,
    this.manufacturer,
    this.connectorTypeId,
  });

  final String name;
  final String? manufacturer;
  final CatalogDeviceCategory category;
  final double powerW;
  final double currentA;
  final double weightKg;
  final String? connectorTypeId;
  final CatalogQuantityUnit quantityUnit;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), avatar: Icon(icon, size: 16));
  }
}
