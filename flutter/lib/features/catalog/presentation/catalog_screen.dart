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
  CatalogDeviceCategory? _categoryFilter;
  var _isLoading = true;
  String? _error;

  List<CatalogDevice> get _filteredDevices {
    final normalizedQuery = _query.trim().toLowerCase();
    final categoryFilter = _categoryFilter;

    return _devices.where((device) {
      if (categoryFilter != null && device.category != categoryFilter) {
        return false;
      }
      if (normalizedQuery.isEmpty) {
        return true;
      }
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
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Nie udało się wczytać katalogu. Dane lokalne pozostały bez zmian.\n$error';
        _isLoading = false;
      });
    }
  }

  /// See `ClientsScreen._ensureRepository` - same reasoning: without this,
  /// a [_repository] that is still null (failed or not-yet-finished
  /// [_loadDevices]) makes every action silently do nothing.
  Future<CatalogRepository?> _ensureRepository() async {
    if (_repository != null) {
      return _repository;
    }

    await _loadDevices();
    if (_repository != null) {
      return _repository;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _error ?? 'Baza danych nie jest gotowa. Spróbuj ponownie.',
          ),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final filteredDevices = _filteredDevices;

    return Scaffold(
      floatingActionButton: _view == _CatalogView.devices
          ? GreenCrewFab(
              label: 'Dodaj urządzenie',
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
                label: Text('Urządzenia'),
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
              hintText: 'Szukaj urządzenia',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Wszystkie'),
                    selected: _categoryFilter == null,
                    onSelected: (_) => setState(() => _categoryFilter = null),
                  ),
                  for (final category in CatalogDeviceCategory.values)
                    ChoiceChip(
                      label: Text(_categoryLabel(category)),
                      selected: _categoryFilter == category,
                      onSelected: (selected) {
                        setState(
                          () => _categoryFilter = selected ? category : null,
                        );
                      },
                    ),
                ],
              ),
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
                  title: 'Błąd danych',
                  message: _error!,
                  actionLabel: 'Spróbuj ponownie',
                  onAction: _loadDevices,
                ),
              )
            else if (filteredDevices.isEmpty)
              GreenCrewCard(
                child: GreenCrewEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Brak urządzeń',
                  message: _query.isEmpty
                      ? 'Dodaj urządzenia i rozdzielnie, aby używać ich w projektach.'
                      : 'Zmień zapytanie albo dodaj nowe urządzenie.',
                  actionLabel: 'Dodaj urządzenie',
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
    final repository = await _ensureRepository();
    if (repository == null || !mounted) {
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
      connectorTypeIds: result.connectorTypeIds,
      riggingPoints: result.riggingPoints,
      loadChart: result.loadChart,
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
        title: const Text('Usunąć urządzenie?'),
        content: Text(
          '"${device.name}" zostanie usunięte z katalogu lokalnego.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
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
      const SnackBar(content: Text('Urządzenie usunięte lokalnie')),
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
                tooltip: 'Edytuj urządzenie',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Usuń urządzenie',
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
              if (device.riggingPoints != null)
                _MetricChip(
                  icon: Icons.anchor,
                  label: '${device.riggingPoints} pkt. zaczepienia',
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
  late final Set<CatalogConnectorType> _connectorTypes;
  late final TextEditingController _riggingPointsController;
  late List<_LoadChartRowControllers> _loadChartRows;
  late CatalogDeviceCategory _category;
  late CatalogQuantityUnit _quantityUnit;
  var _isUpdatingElectricalFields = false;

  /// Rigging hardware (trusses, clamps, hooks) and cables don't draw power -
  /// showing "Moc"/"Prąd" for them just invites made-up numbers.
  bool get _showElectrical =>
      _category != CatalogDeviceCategory.rigging &&
      _category != CatalogDeviceCategory.cable;

  /// Rigging items aren't fitted with power/signal connectors themselves -
  /// they're the thing other equipment hangs from or clamps onto.
  bool get _showConnectors => _category != CatalogDeviceCategory.rigging;

  /// "Rigging points" (hook attachment points) describes what a device
  /// needs *from* rigging when it hangs on a truss - a rigging item itself
  /// (the truss, the clamp) doesn't have this, and neither does a cable.
  bool get _showRiggingPoints =>
      _category != CatalogDeviceCategory.rigging &&
      _category != CatalogDeviceCategory.cable;

  /// Cables aren't meaningfully attributed to a manufacturer the way
  /// fixtures/distros are.
  bool get _showManufacturer => _category != CatalogDeviceCategory.cable;

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
    _connectorTypes = {...?device?.connectorTypeIds};
    _riggingPointsController = TextEditingController(
      text: device?.riggingPoints?.toString() ?? '',
    );
    _loadChartRows = [
      for (final entry in device?.loadChart ?? const [])
        _LoadChartRowControllers.fromEntry(entry),
    ];
    _powerController.addListener(_syncCurrentFromPower);
    _currentController.addListener(_syncPowerFromCurrent);
    _category = device?.category ?? CatalogDeviceCategory.lighting;
    _quantityUnit = device?.quantityUnit ?? CatalogQuantityUnit.pcs;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _powerController.dispose();
    _currentController.dispose();
    _weightController.dispose();
    _riggingPointsController.dispose();
    for (final row in _loadChartRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.device == null ? 'Dodaj urządzenie' : 'Edytuj urządzenie',
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
            if (_showManufacturer) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _manufacturerController,
                decoration: const InputDecoration(labelText: 'Producent'),
              ),
            ],
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
            if (_showElectrical) ...[
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
                  labelText: 'Prąd',
                  suffixText: 'A',
                  helperText: 'Przeliczane dla 230 V',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Masa',
                suffixText: 'kg',
              ),
            ),
            if (_showConnectors) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Typy złącz (można wybrać kilka)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in CatalogConnectorType.values)
                    FilterChip(
                      label: Text(type.label),
                      selected: _connectorTypes.contains(type),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _connectorTypes.add(type);
                          } else {
                            _connectorTypes.remove(type);
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
            if (_showRiggingPoints) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _riggingPointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Punkty zaczepienia (opcjonalnie)',
                  helperText:
                      'Liczba haków potrzebnych, gdy urządzenie wisi na kratownicy.',
                ),
              ),
            ],
            if (_category == CatalogDeviceCategory.rigging) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tabela nośności producenta (opcjonalnie)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dodaj wpis',
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(
                      () => _loadChartRows.add(_LoadChartRowControllers()),
                    ),
                  ),
                ],
              ),
              const Text(
                'Używana do interpolacji limitów kratownicy po długości - '
                'zostaw puste, jeśli limity będą wpisywane ręcznie per projekt.',
                style: TextStyle(fontSize: 12),
              ),
              for (final row in _loadChartRows)
                Padding(
                  key: ValueKey(row),
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: row.lengthController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Długość',
                            suffixText: 'm',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: row.pointLoadController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Obc. punktowe',
                            suffixText: 'kg',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: row.distributedLoadController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Obc. rozłożone',
                            suffixText: 'kg/m',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Usuń wpis',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _loadChartRows.remove(row)),
                      ),
                    ],
                  ),
                ),
            ],
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

    // Hidden fields keep whatever was last typed into their controller even
    // while not shown (e.g. power/current entered before switching category
    // to "Rigging") - force them back to their empty/zero state here rather
    // than silently saving stale, no-longer-applicable values.
    Navigator.of(context).pop(
      _CatalogDeviceFormResult(
        name: name,
        manufacturer: _showManufacturer
            ? _emptyToNull(_manufacturerController.text)
            : null,
        category: _category,
        powerW: _showElectrical ? _parseNumber(_powerController.text) : 0,
        currentA: _showElectrical ? _parseNumber(_currentController.text) : 0,
        weightKg: _parseNumber(_weightController.text),
        connectorTypeIds: _showConnectors ? _connectorTypes.toList() : const [],
        riggingPoints: _showRiggingPoints
            ? int.tryParse(_riggingPointsController.text.trim())
            : null,
        loadChart: _category == CatalogDeviceCategory.rigging
            ? _loadChartRows
                  .map((row) => row.toEntry(_parseNumber))
                  .whereType<TrussLoadChartEntry>()
                  .toList()
            : const [],
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
    this.connectorTypeIds = const [],
    this.riggingPoints,
    this.loadChart = const [],
  });

  final String name;
  final String? manufacturer;
  final CatalogDeviceCategory category;
  final double powerW;
  final double currentA;
  final double weightKg;
  final List<CatalogConnectorType> connectorTypeIds;
  final int? riggingPoints;
  final List<TrussLoadChartEntry> loadChart;
  final CatalogQuantityUnit quantityUnit;
}

/// One editable row of a device's `loadChart` in the catalog form. Holds its
/// own controllers so the dialog can add/remove rows freely without losing
/// text state, mirroring the per-row controller pattern used for outlet
/// templates elsewhere in the app.
class _LoadChartRowControllers {
  _LoadChartRowControllers({String? id})
    : id = id ?? 'chart_${DateTime.now().microsecondsSinceEpoch}_$_counter',
      lengthController = TextEditingController(),
      pointLoadController = TextEditingController(),
      distributedLoadController = TextEditingController() {
    _counter++;
  }

  factory _LoadChartRowControllers.fromEntry(TrussLoadChartEntry entry) {
    final row = _LoadChartRowControllers(id: entry.id);
    row.lengthController.text = entry.lengthM.toStringAsFixed(1);
    row.pointLoadController.text = entry.pointLoadKg.toStringAsFixed(0);
    row.distributedLoadController.text = entry.distributedLoadKgPerM
        .toStringAsFixed(1);
    return row;
  }

  static int _counter = 0;

  final String id;
  final TextEditingController lengthController;
  final TextEditingController pointLoadController;
  final TextEditingController distributedLoadController;

  void dispose() {
    lengthController.dispose();
    pointLoadController.dispose();
    distributedLoadController.dispose();
  }

  TrussLoadChartEntry? toEntry(double Function(String) parseNumber) {
    if (lengthController.text.trim().isEmpty) {
      return null;
    }
    return TrussLoadChartEntry(
      id: id,
      lengthM: parseNumber(lengthController.text),
      pointLoadKg: parseNumber(pointLoadController.text),
      distributedLoadKgPerM: parseNumber(distributedLoadController.text),
    );
  }
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
