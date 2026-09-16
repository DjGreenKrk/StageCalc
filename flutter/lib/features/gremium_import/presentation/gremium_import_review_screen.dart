import 'package:flutter/material.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/entities/catalog_device.dart';
import '../../catalog/presentation/catalog_link_device_dialog.dart';
import '../../projects/data/project_repository.dart';
import '../domain/entities/gremium_category_guess.dart';
import '../domain/entities/gremium_pack_list.dart';
import '../domain/services/gremium_catalog_matcher.dart';
import '../domain/services/gremium_import_commit_service.dart';

/// Review panel shown right after a Gremium pack-list file is parsed and
/// matched, before anything is saved (ADR-034): every item can be excluded,
/// assigned a target group, and (for items with no existing catalog match)
/// either linked to an already-existing device or created as a new one in
/// an existing `CatalogDeviceCategory` (never a Gremium-specific category).
class GremiumImportReviewScreen extends StatefulWidget {
  const GremiumImportReviewScreen({
    required this.packList,
    required this.matches,
    required this.catalogDevices,
    required this.catalogRepository,
    required this.projectRepository,
    super.key,
  });

  final GremiumPackList packList;
  final List<GremiumMatchResult> matches;
  final List<CatalogDevice> catalogDevices;
  final CatalogRepository catalogRepository;
  final ProjectRepository projectRepository;

  @override
  State<GremiumImportReviewScreen> createState() =>
      _GremiumImportReviewScreenState();
}

class _GremiumImportReviewScreenState extends State<GremiumImportReviewScreen> {
  late final String _defaultGroupName;
  late final List<_ReviewRow> _rows;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _defaultGroupName = 'Import z Gremium (${widget.packList.project.name})';
    _rows = widget.matches
        .map(
          (match) => _ReviewRow(
            match: match,
            groupNameController: TextEditingController(text: _defaultGroupName),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.groupNameController.dispose();
    }
    super.dispose();
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

  Future<void> _bulkAssignGroup() async {
    final controller = TextEditingController(text: _defaultGroupName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Przypisz zaznaczone do grupy'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nazwa grupy'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Przypisz'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) {
      return;
    }
    setState(() {
      for (final row in _selectedRows) {
        row.groupNameController.text = name;
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final decisions = _selectedRows.map(_decisionFor).toList();
    final service = GremiumImportCommitService(
      catalogRepository: widget.catalogRepository,
      projectRepository: widget.projectRepository,
    );

    try {
      final summary = await service.commit(
        gremiumProject: widget.packList.project,
        decisions: decisions,
      );
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

  GremiumImportDecision _decisionFor(_ReviewRow row) {
    final groupName = row.groupNameController.text.trim();
    final resolvedGroupName = groupName.isEmpty ? _defaultGroupName : groupName;

    switch (row.match.status) {
      case GremiumMatchStatus.ownItem:
        return GremiumImportDecision(
          item: row.item,
          targetGroupName: resolvedGroupName,
          action: GremiumImportAction.ownItemOnly,
        );
      case GremiumMatchStatus.linked:
        return GremiumImportDecision(
          item: row.item,
          targetGroupName: resolvedGroupName,
          action: GremiumImportAction.useCatalogDevice,
          existingDeviceId: row.match.matchedDevice!.id,
        );
      case GremiumMatchStatus.newDevice:
        final manual = row.manualLinkDevice;
        if (manual != null) {
          return GremiumImportDecision(
            item: row.item,
            targetGroupName: resolvedGroupName,
            action: GremiumImportAction.useCatalogDevice,
            existingDeviceId: manual.id,
            linkExistingDevice: true,
          );
        }
        return GremiumImportDecision(
          item: row.item,
          targetGroupName: resolvedGroupName,
          action: GremiumImportAction.createNewDevice,
          category: row.category,
          riggingKind: row.riggingKind,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRows = _selectedRows;

    return Scaffold(
      appBar: AppBar(
        title: Text('Import: ${widget.packList.project.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.drive_file_move_outline),
            tooltip: 'Przypisz zaznaczone do grupy',
            onPressed: selectedRows.isEmpty ? null : _bulkAssignGroup,
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: _rows.length,
        separatorBuilder: (context, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = _rows[index];
          return _RowTile(
            row: row,
            onChanged: () => setState(() {}),
            onPickExisting: () => _pickExistingDevice(row),
          );
        },
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
        .where((row) => row.match.status == GremiumMatchStatus.linked)
        .length;
    final manuallyLinked = selectedRows
        .where((row) => row.isNewDeviceRow && row.manualLinkDevice != null)
        .length;
    final toCreate = selectedRows
        .where((row) => row.isNewDeviceRow && row.manualLinkDevice == null)
        .length;
    final ownItems = selectedRows
        .where((row) => row.match.status == GremiumMatchStatus.ownItem)
        .length;
    final missingElectrical = selectedRows
        .where((row) => row.needsElectricalData)
        .length;

    final parts = <String>[
      '${selectedRows.length} do zaimportowania',
      if (linked > 0) '$linked w katalogu',
      if (manuallyLinked > 0) '$manuallyLinked połączonych ręcznie',
      if (toCreate > 0) '$toCreate nowych w katalogu',
      if (ownItems > 0) '$ownItems pozycji własnych',
    ];

    final warnings = <String>[
      if (missingElectrical > 0) '$missingElectrical bez mocy/prądu',
    ];

    final buffer = StringBuffer(parts.join(' • '));
    if (warnings.isNotEmpty) {
      buffer.write('\nWymaga uzupełnienia: ${warnings.join(', ')}');
    }
    return buffer.toString();
  }
}

class _ReviewRow {
  _ReviewRow({required this.match, required this.groupNameController})
    : category = guessGremiumCategory(match.item),
      riggingKind = guessGremiumRiggingKind(match.item);

  final GremiumMatchResult match;
  final TextEditingController groupNameController;
  bool selected = true;
  CatalogDeviceCategory category;
  RiggingDeviceKind? riggingKind;
  CatalogDevice? manualLinkDevice;

  GremiumItem get item => match.item;
  bool get isNewDeviceRow => match.status == GremiumMatchStatus.newDevice;

  bool get needsElectricalData =>
      isNewDeviceRow &&
      manualLinkDevice == null &&
      category.showsElectricalFields &&
      item.technical.ratedPowerW == null &&
      item.technical.ratedCurrentA == null;
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
    final quantity = row.item.quantity;
    final quantityLabel = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(1);

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
                  '${row.item.displayLabel} (${quantityLabel}x)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
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
                        if (row.category == CatalogDeviceCategory.rigging)
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<RiggingDeviceKind>(
                              initialValue:
                                  row.riggingKind ?? RiggingDeviceKind.other,
                              isDense: true,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Rodzaj sprzętu riggingowego',
                              ),
                              items: [
                                for (final kind in RiggingDeviceKind.values)
                                  DropdownMenuItem(
                                    value: kind,
                                    child: Text(
                                      kind.label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (kind) {
                                if (kind == null) {
                                  return;
                                }
                                row.riggingKind = kind;
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
                if (row.selected) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: row.groupNameController,
                      decoration: const InputDecoration(
                        labelText: 'Grupa docelowa',
                        isDense: true,
                      ),
                    ),
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
      GremiumMatchStatus.linked => (
        'W katalogu: ${row.match.matchedDevice!.name}',
        Icons.check_circle_outline,
      ),
      GremiumMatchStatus.ownItem => (
        'Pozycja własna',
        Icons.inventory_2_outlined,
      ),
      GremiumMatchStatus.newDevice => (
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
