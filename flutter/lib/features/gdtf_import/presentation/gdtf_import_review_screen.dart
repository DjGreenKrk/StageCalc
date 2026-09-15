import 'package:flutter/material.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/entities/catalog_device.dart';
import '../../catalog/presentation/catalog_link_device_dialog.dart';
import '../domain/entities/gdtf_category_guess.dart';
import '../domain/entities/gdtf_fixture_type.dart';
import '../domain/entities/gdtf_import_failure.dart';
import '../domain/services/gdtf_catalog_matcher.dart';
import '../domain/services/gdtf_import_commit_service.dart';

/// Review panel shown right after picked GDTF files are parsed and matched,
/// before anything is saved (ADR-035): every fixture can be excluded, and
/// (for fixtures with no existing catalog match) either linked to an
/// already-existing device or created as a new one in an existing
/// `CatalogDeviceCategory`. Purely catalog-scoped - unlike the Gremium
/// import review (ADR-034) there is no project/group concept here.
class GdtfImportReviewScreen extends StatefulWidget {
  const GdtfImportReviewScreen({
    required this.matches,
    required this.failures,
    required this.catalogDevices,
    required this.catalogRepository,
    super.key,
  });

  final List<GdtfMatchResult> matches;
  final List<GdtfImportFailure> failures;
  final List<CatalogDevice> catalogDevices;
  final CatalogRepository catalogRepository;

  @override
  State<GdtfImportReviewScreen> createState() => _GdtfImportReviewScreenState();
}

class _GdtfImportReviewScreenState extends State<GdtfImportReviewScreen> {
  late final List<_ReviewRow> _rows;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rows = widget.matches.map((match) => _ReviewRow(match: match)).toList();
  }

  List<_ReviewRow> get _selectedRows =>
      _rows.where((row) => row.selected).toList();

  Future<void> _pickExistingDevice(_ReviewRow row) async {
    final selected = await showDialog<CatalogDevice>(
      context: context,
      builder: (_) => CatalogLinkDeviceDialog(devices: widget.catalogDevices),
    );
    if (selected != null) {
      setState(() => row.manualLinkDevice = selected);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final decisions = _selectedRows.map(_decisionFor).toList();
    final service = GdtfImportCommitService(
      catalogRepository: widget.catalogRepository,
    );

    try {
      final summary = await service.commit(decisions);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(summary);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import nie powiódł się.\n$error')),
      );
    }
  }

  GdtfImportDecision _decisionFor(_ReviewRow row) {
    switch (row.match.status) {
      case GdtfMatchStatus.linked:
        return GdtfImportDecision(
          fixture: row.fixture,
          action: GdtfImportAction.useCatalogDevice,
          existingDeviceId: row.match.matchedDevice!.id,
        );
      case GdtfMatchStatus.newDevice:
        final manual = row.manualLinkDevice;
        if (manual != null) {
          return GdtfImportDecision(
            fixture: row.fixture,
            action: GdtfImportAction.useCatalogDevice,
            existingDeviceId: manual.id,
            linkExistingDevice: true,
          );
        }
        return GdtfImportDecision(
          fixture: row.fixture,
          action: GdtfImportAction.createNewDevice,
          category: row.category,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRows = _selectedRows;
    final failures = widget.failures;

    return Scaffold(
      appBar: AppBar(title: const Text('Import GDTF')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        children: [
          if (failures.isNotEmpty) ...[
            _FailuresCard(failures: failures),
            const SizedBox(height: 8),
          ],
          for (final row in _rows) ...[
            _RowTile(
              row: row,
              onChanged: () => setState(() {}),
              onPickExisting: () => _pickExistingDevice(row),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _summaryText(selectedRows),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Anuluj'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting || selectedRows.isEmpty
                          ? null
                          : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Importuj'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summaryText(List<_ReviewRow> selectedRows) {
    final linked = selectedRows
        .where((row) => row.match.status == GdtfMatchStatus.linked)
        .length;
    final manuallyLinked = selectedRows
        .where((row) => row.isNewDeviceRow && row.manualLinkDevice != null)
        .length;
    final toCreate = selectedRows
        .where((row) => row.isNewDeviceRow && row.manualLinkDevice == null)
        .length;
    final missingElectrical = selectedRows
        .where((row) => row.needsElectricalData)
        .length;

    final parts = <String>[
      '${selectedRows.length} do zaimportowania',
      if (linked > 0) '$linked w katalogu',
      if (manuallyLinked > 0) '$manuallyLinked połączonych ręcznie',
      if (toCreate > 0) '$toCreate nowych w katalogu',
    ];

    final warnings = <String>[
      if (missingElectrical > 0) '$missingElectrical bez mocy',
    ];

    final buffer = StringBuffer(parts.join(' • '));
    if (warnings.isNotEmpty) {
      buffer.write('\nWymaga uzupełnienia: ${warnings.join(', ')}');
    }
    return buffer.toString();
  }
}

class _ReviewRow {
  _ReviewRow({required this.match})
    : category = guessGdtfCategory(match.fixture);

  final GdtfMatchResult match;
  bool selected = true;
  CatalogDeviceCategory category;
  CatalogDevice? manualLinkDevice;

  GdtfFixtureType get fixture => match.fixture;
  bool get isNewDeviceRow => match.status == GdtfMatchStatus.newDevice;

  bool get needsElectricalData =>
      isNewDeviceRow &&
      manualLinkDevice == null &&
      category.showsElectricalFields &&
      fixture.powerW == null;
}

class _FailuresCard extends StatelessWidget {
  const _FailuresCard({required this.failures});

  final List<GdtfImportFailure> failures;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nie udało się wczytać (${failures.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            for (final failure in failures)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${failure.fileName}: ${failure.reason}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.row,
    required this.onChanged,
    required this.onPickExisting,
  });

  final _ReviewRow row;
  final VoidCallback onChanged;
  final VoidCallback onPickExisting;

  @override
  Widget build(BuildContext context) {
    final fixture = row.fixture;
    final subtitle = [
      if (fixture.manufacturer != null) fixture.manufacturer,
      fixture.sourceFileName,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: row.selected,
            onChanged: (value) {
              row.selected = value ?? false;
              onChanged();
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fixture.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                _StatusChip(row: row),
                if (row.isNewDeviceRow && row.selected) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (row.manualLinkDevice == null) ...[
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<CatalogDeviceCategory>(
                            initialValue: row.category,
                            isDense: true,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Kategoria w katalogu',
                            ),
                            items: [
                              for (final category
                                  in CatalogDeviceCategory.values)
                                DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (category) {
                              if (category == null) {
                                return;
                              }
                              row.category = category;
                              onChanged();
                            },
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onPickExisting,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('Połącz z istniejącym'),
                        ),
                      ] else
                        Chip(
                          label: Text(
                            'Połączone: ${row.manualLinkDevice!.name}',
                          ),
                          onDeleted: () {
                            row.manualLinkDevice = null;
                            onChanged();
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.row});

  final _ReviewRow row;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (row.match.status) {
      GdtfMatchStatus.linked => (
        'W katalogu: ${row.match.matchedDevice!.name}',
        Icons.check_circle_outline,
      ),
      GdtfMatchStatus.newDevice => (
        'Nowe urządzenie',
        Icons.fiber_new_outlined,
      ),
    };
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
