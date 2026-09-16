import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/greencrew_colors.dart';
import '../../../shared/widgets/greencrew_card.dart';
import '../../../shared/widgets/greencrew_empty_state.dart';
import '../domain/entities/catalog_device.dart';

/// Read-only spec sheet for one [CatalogDevice], reached by tapping its card
/// in the catalog list. Trusses additionally get a load-chart curve instead
/// of the raw length/load number rows shown in the edit dialog.
///
/// Deliberately has no edit/delete of its own - "Edytuj" just pops `true` so
/// the catalog list (which already owns the edit dialog and repository) can
/// open it, exactly like `ProjectsScreen` popping a result up to itself
/// after `ProjectEditorScreen` closes.
class CatalogDeviceDetailScreen extends StatelessWidget {
  const CatalogDeviceDetailScreen({required this.device, super.key});

  final CatalogDevice device;

  @override
  Widget build(BuildContext context) {
    final category = device.category;

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: [
          IconButton(
            tooltip: 'Edytuj urządzenie',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GreenCrewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Podstawowe dane',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _SpecRow(label: 'Producent', value: device.manufacturer ?? '-'),
                _SpecRow(label: 'Kategoria', value: category.label),
                _SpecRow(
                  label: 'Jednostka',
                  value: _unitLabel(device.quantityUnit),
                ),
              ],
            ),
          ),
          if (category.showsElectricalFields) ...[
            const SizedBox(height: 12),
            GreenCrewCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dane elektryczne',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _SpecRow(
                    label: 'Moc',
                    value: '${device.powerW.toStringAsFixed(0)} W',
                  ),
                  _SpecRow(
                    label: 'Prąd',
                    value: '${device.currentA.toStringAsFixed(1)} A',
                  ),
                  _SpecRow(
                    label: 'Waga',
                    value: '${device.weightKg.toStringAsFixed(1)} kg',
                  ),
                  if (device.connectorTypeIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final connector in device.connectorTypeIds)
                          Chip(label: Text(connector.label)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (category == CatalogDeviceCategory.rigging) ...[
            const SizedBox(height: 12),
            GreenCrewCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rigging',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _SpecRow(
                    label: 'Rodzaj',
                    value: device.riggingKind?.label ?? 'Nieokreślony',
                  ),
                  if (device.riggingPoints != null)
                    _SpecRow(
                      label: 'Punkty zaczepienia',
                      value: '${device.riggingPoints}',
                    ),
                ],
              ),
            ),
          ],
          if (device.riggingKind == RiggingDeviceKind.truss) ...[
            const SizedBox(height: 12),
            if (device.loadChart.isEmpty)
              GreenCrewCard(
                child: GreenCrewEmptyState(
                  icon: Icons.show_chart,
                  title: 'Brak tabeli nośności',
                  message: 'Dodaj ją w edycji urządzenia, aby zobaczyć wykres.',
                ),
              )
            else
              _LoadChartCard(loadChart: device.loadChart),
          ],
        ],
      ),
    );
  }

  String _unitLabel(CatalogQuantityUnit unit) {
    return switch (unit) {
      CatalogQuantityUnit.pcs => 'szt.',
      CatalogQuantityUnit.meters => 'm',
    };
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: GreenCrewColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Both load-chart series drawn on one line chart with a hand-built legend
/// below it, mirroring how manufacturer catalogs (e.g. Duratruss) usually
/// present a truss's point-load and distributed-load curves together.
class _LoadChartCard extends StatelessWidget {
  const _LoadChartCard({required this.loadChart});

  final List<TrussLoadChartEntry> loadChart;

  static const _pointLoadColor = GreenCrewColors.primary;
  static const _distributedLoadColor = GreenCrewColors.info;

  @override
  Widget build(BuildContext context) {
    final sortedEntries = List<TrussLoadChartEntry>.of(loadChart)
      ..sort((a, b) => a.lengthM.compareTo(b.lengthM));

    final pointLoadSpots = [
      for (final entry in sortedEntries)
        FlSpot(entry.lengthM, entry.pointLoadKg),
    ];
    final distributedLoadSpots = [
      for (final entry in sortedEntries)
        FlSpot(entry.lengthM, entry.distributedLoadKgPerM),
    ];

    return GreenCrewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Krzywa nośności',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                backgroundColor: GreenCrewColors.surfaceVariant,
                gridData: FlGridData(
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: GreenCrewColors.border,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => const FlLine(
                    color: GreenCrewColors.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${value.toStringAsFixed(1)} m'),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) =>
                          Text(value.toStringAsFixed(0)),
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border.fromBorderSide(
                    BorderSide(color: GreenCrewColors.border),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: pointLoadSpots,
                    color: _pointLoadColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: distributedLoadSpots,
                    color: _distributedLoadColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _LegendEntry(
                color: _pointLoadColor,
                label: 'Obciążenie punktowe (kg)',
              ),
              _LegendEntry(
                color: _distributedLoadColor,
                label: 'Obciążenie rozłożone (kg/m)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
