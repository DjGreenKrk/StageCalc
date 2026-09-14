import 'package:flutter/material.dart';

import '../../../shared/widgets/greencrew_button.dart';
import '../../../shared/widgets/greencrew_card.dart';
import '../../../shared/widgets/greencrew_section_header.dart';
import '../../catalog/domain/entities/catalog_device.dart';
import '../../clients/domain/entities/client.dart';
import '../../locations/domain/entities/location.dart';
import '../../power_presets/domain/entities/power_preset.dart';
import '../data/project_repository.dart';
import '../domain/entities/power_models.dart';
import '../domain/entities/project_models.dart';
import '../../../infrastructure/files/local_file_writer/local_file_writer.dart';
import '../domain/services/patch_validation_service.dart';
import '../domain/services/power_calculation_service.dart';
import '../domain/services/project_pdf_report_service.dart';
import '../domain/services/project_report_service.dart';
import '../domain/services/project_totals_service.dart';
import '../domain/services/truss_load_service.dart';
import 'project_editor_controller.dart';

part 'project_editor/metadata_widgets.dart';
part 'project_editor/distro_widgets.dart';
part 'project_editor/distro_create_dialog.dart';
part 'project_editor/custom_outlet_group_editor.dart';
part 'project_editor/distro_layout_dialog.dart';
part 'project_editor/connection_widgets.dart';
part 'project_editor/group_widgets.dart';
part 'project_editor/catalog_selection_dialog.dart';
part 'project_editor/truss_widgets.dart';
part 'project_editor/shared_helpers.dart';

/// Editor screen for a single [Project]. All project mutations live in
/// [ProjectEditorController] (see ADR-015) — this widget only shows dialogs,
/// reads their results, and hands them to the controller.
class ProjectEditorScreen extends StatefulWidget {
  const ProjectEditorScreen({
    required this.project,
    required this.repository,
    super.key,
  });

  final Project project;
  final ProjectRepository repository;

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  late final ProjectEditorController _controller;
  static const _reportService = ProjectReportService();
  static const _pdfReportService = ProjectPdfReportService();

  @override
  void initState() {
    super.initState();
    _controller = ProjectEditorController(
      project: widget.project,
      repository: widget.repository,
    );
    _controller.addListener(_handleControllerChanged);
    _controller.loadReferences();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = _controller.project;
    final totals = _controller.totals;
    final powerLoads = _controller.powerLoads;
    final patchValidation = _controller.patchValidation;
    final view = _controller.view;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_controller.hasChanges);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(project.name),
          actions: [
            IconButton(
              tooltip: 'Eksportuj raport tekstowy',
              onPressed: _exportReport,
              icon: const Icon(Icons.summarize_outlined),
            ),
            IconButton(
              tooltip: 'Eksportuj raport PDF',
              onPressed: _exportPdfReport,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProjectMetadataCard(
              project: project,
              clients: _controller.clients,
              locations: _controller.locations,
              onEdit: _openProjectMetadataDialog,
            ),
            const SizedBox(height: 16),
            GreenCrewCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    label: 'Moc',
                    value: '${totals.powerKw.toStringAsFixed(1)} kW',
                  ),
                  _MetricChip(
                    label: 'Prąd',
                    value: '${totals.currentA.toStringAsFixed(1)} A',
                  ),
                  _MetricChip(
                    label: 'Masa',
                    value: '${totals.weightKg.toStringAsFixed(0)} kg',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<ProjectEditorView>(
              segments: const [
                ButtonSegment(
                  value: ProjectEditorView.equipment,
                  icon: Icon(Icons.view_list_outlined),
                  label: Text('Sprzęt'),
                ),
                ButtonSegment(
                  value: ProjectEditorView.patcher,
                  icon: Icon(Icons.cable),
                  label: Text('Patcher'),
                ),
                ButtonSegment(
                  value: ProjectEditorView.trusses,
                  icon: Icon(Icons.linear_scale),
                  label: Text('Kratownice'),
                ),
              ],
              selected: {view},
              onSelectionChanged: (selection) {
                _controller.setView(selection.single);
              },
            ),
            const SizedBox(height: 16),
            if (view == ProjectEditorView.equipment) ...[
              GreenCrewSectionHeader(
                title: 'Grupy',
                action: GreenCrewButton(
                  label: 'Dodaj grupę',
                  icon: Icons.add,
                  onPressed: _openAddGroupDialog,
                  secondary: true,
                ),
              ),
              const SizedBox(height: 12),
              if (project.groups.isEmpty)
                const GreenCrewCard(
                  child: Text('Brak grup. Dodaj pierwszą grupę urządzeń.'),
                )
              else
                for (final group in project.groups) ...[
                  _GroupCard(
                    group: group,
                    onAddItem: () => _openAddItemDialog(group),
                    onAddCatalogItem: () => _openAddCatalogItemDialog(group),
                    onEditGroup: () => _openEditGroupDialog(group),
                    onDeleteGroup: () => _deleteGroup(group),
                    onEditItem: (item) => _openEditItemDialog(group, item),
                    onDeleteItem: (item) => _deleteItem(group, item),
                  ),
                  const SizedBox(height: 12),
                ],
            ] else if (view == ProjectEditorView.patcher) ...[
              GreenCrewSectionHeader(
                title: 'Rozdzielnice',
                action: GreenCrewButton(
                  label: 'Dodaj',
                  icon: Icons.add,
                  onPressed: _openAddDistroMenu,
                  secondary: true,
                ),
              ),
              const SizedBox(height: 12),
              if (project.distros.isEmpty)
                const GreenCrewCard(
                  child: Text('Brak rozdzielnic w projekcie.'),
                )
              else
                for (final distro in project.distros) ...[
                  _DistroCard(
                    distro: distro,
                    project: project,
                    isPowerSource: !project.connections.any(
                      (connection) =>
                          connection.targetType ==
                              PowerConnectionTargetType.distro &&
                          connection.targetDistroId == distro.id,
                    ),
                    phaseLoad: powerLoads.distroPhaseLoads[distro.id],
                    distroLoad: powerLoads.distroLoads[distro.id],
                    outletLoads: powerLoads.outletLoads,
                    patchValidation: patchValidation,
                    onEdit: () => _openEditDistroDialog(distro),
                    onDelete: () => _deleteDistro(distro),
                    onOutletTap: (outlet, connections) =>
                        _openOutletTap(distro, outlet, connections),
                  ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 16),
              GreenCrewSectionHeader(
                title: 'Połączenia',
                action: GreenCrewButton(
                  label: 'Połącz',
                  icon: Icons.cable,
                  onPressed: _controller.canCreateConnection
                      ? _openAddConnectionDialog
                      : null,
                  secondary: true,
                ),
              ),
              const SizedBox(height: 12),
              if (project.connections.isEmpty)
                const GreenCrewCard(
                  child: Text('Brak połączeń grup z rozdzielnicami.'),
                )
              else
                for (final connection in project.connections) ...[
                  _ConnectionCard(
                    connection: connection,
                    project: project,
                    patchValidation: patchValidation,
                    onDelete: () => _deleteConnection(connection),
                  ),
                  const SizedBox(height: 12),
                ],
            ] else ...[
              GreenCrewSectionHeader(
                title: 'Kratownice',
                action: GreenCrewButton(
                  label: 'Dodaj',
                  icon: Icons.add,
                  onPressed: () => _openAddTrussDialog(project.groups),
                  secondary: true,
                ),
              ),
              const SizedBox(height: 12),
              if (project.trusses.isEmpty)
                const GreenCrewCard(child: Text('Brak kratownic w projekcie.'))
              else
                for (final truss in project.trusses) ...[
                  _TrussCard(
                    truss: truss,
                    load: _controller.trussLoad(truss),
                    groups: project.groups,
                    onEdit: () => _openEditTrussDialog(truss, project.groups),
                    onDelete: () => _deleteTruss(truss),
                  ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 12),
              const GreenCrewSectionHeader(title: 'Haki grup urządzeń'),
              const SizedBox(height: 12),
              if (_groupsNeedingHooks(project).isEmpty)
                const GreenCrewCard(
                  child: Text(
                    'Żadna grupa nie ma jeszcze urządzeń wymagających haków '
                    '(pole "Punkty zaczepienia" w katalogu).',
                  ),
                )
              else
                for (final group in _groupsNeedingHooks(project)) ...[
                  _GroupHooksCard(
                    group: group,
                    requirement: _controller.hookRequirement(group),
                    onAddHook: () => _openAddHookDialog(group),
                    onEditQuantity: (assignment, quantity) => _runMutation(
                      () => _controller.editHookAssignmentQuantity(
                        group,
                        assignment,
                        quantity,
                      ),
                    ),
                    onRemove: (assignment) => _runMutation(
                      () => _controller.deleteHookAssignment(group, assignment),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    await action();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Projekt zapisany lokalnie')));
  }

  Future<void> _exportReport() async {
    final report = _reportService.buildTextReport(_controller.project);
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;

    try {
      final path = await writeLocalFile(
        subfolder: 'reports',
        fileName: 'stagecalc_raport_$timestamp.txt',
        content: report,
      );

      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Raport wyeksportowany'),
          content: SelectableText(path),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się wyeksportować raportu: $error')),
      );
    }
  }

  Future<void> _exportPdfReport() async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;

    try {
      final bytes = await _pdfReportService.buildPdfReport(_controller.project);
      final path = await writeLocalBytesFile(
        subfolder: 'reports',
        fileName: 'stagecalc_raport_$timestamp.pdf',
        bytes: bytes,
      );

      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Raport PDF wyeksportowany'),
          content: SelectableText(path),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się wyeksportować raportu PDF: $error'),
        ),
      );
    }
  }

  Future<void> _openProjectMetadataDialog() async {
    final result = await showDialog<_ProjectMetadataResult>(
      context: context,
      builder: (context) => _ProjectMetadataDialog(
        project: _controller.project,
        clients: _controller.clients,
        locations: _controller.locations,
      ),
    );

    if (result == null) {
      return;
    }

    await _runMutation(
      () => _controller.updateMetadata(
        name: result.name,
        clientId: result.clientId,
        locationId: result.locationId,
      ),
    );
  }

  Future<void> _openAddDistroMenu() async {
    final projectLocation = _controller.locations
        .where((location) => location.id == _controller.project.locationId)
        .firstOrNull;
    final result = await showDialog<_DistroCreateResult>(
      context: context,
      builder: (context) => _DistroCreateDialog(
        presets: _controller.powerPresets,
        location: projectLocation,
      ),
    );

    if (result == null) {
      return;
    }

    await _runMutation(
      () => _controller.addDistro(
        name: result.name,
        sourceType: result.sourceType,
        presetId: result.preset?.id,
        locationConnectorGroupId: result.locationConnectorGroupId,
        inputConnectorTypeId: result.inputConnectorTypeId,
        outletTemplates: result.outlets,
      ),
    );
  }

  Future<void> _openEditDistroDialog(ProjectDistro distro) async {
    final result = await showDialog<_DistroLayoutResult>(
      context: context,
      builder: (context) => _DistroLayoutDialog(distro: distro),
    );

    if (result == null) {
      return;
    }

    await _runMutation(
      () => _controller.editDistro(
        distro,
        name: result.name,
        inputConnectorTypeId: result.inputConnectorTypeId,
        outlets: result.outlets,
        manualInputMaxCurrentA: result.manualInputMaxCurrentA,
      ),
    );
  }

  Future<void> _deleteDistro(ProjectDistro distro) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć rozdzielnicę?'),
        content: Text('"${distro.name}" zostanie usunięta lokalnie.'),
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

    await _runMutation(() => _controller.deleteDistro(distro));
  }

  Future<void> _openAddConnectionDialog() async {
    final result = await showDialog<_ConnectionResult>(
      context: context,
      builder: (context) => _ConnectionDialog(project: _controller.project),
    );

    if (result == null) {
      return;
    }

    await _addConnectionsFromResult(result);
  }

  Future<void> _addConnectionsFromResult(_ConnectionResult result) {
    return _runMutation(
      () => _controller.addConnections(
        targetType: result.targetType,
        targetGroupId: result.targetGroupId,
        targetDistroId: result.targetDistroId,
        sources: [
          for (final source in result.sources)
            ProjectConnectionSource(
              sourceDistroId: source.sourceDistroId,
              sourceOutletId: source.sourceOutletId,
            ),
        ],
        selectedPhases: result.selectedPhases,
        notes: result.notes,
      ),
    );
  }

  Future<void> _deleteConnection(PowerConnection connection) async {
    await _runMutation(() => _controller.deleteConnection(connection));
  }

  /// Tapping a "patch point" outlet tile (visual patcher): an empty outlet
  /// opens a quick single-outlet connect dialog, an already-patched one
  /// opens its details (target, notes, disconnect) instead of the bulk
  /// "Połącz" dialog used for the "Połączenia" list below.
  void _openOutletTap(
    ProjectDistro distro,
    ProjectOutlet outlet,
    List<PowerConnection> connections,
  ) {
    if (connections.isEmpty) {
      _openQuickConnectDialog(distro, outlet, occupiedPhases: const {});
    } else {
      _openOutletDetailsDialog(distro, outlet, connections);
    }
  }

  Future<void> _openQuickConnectDialog(
    ProjectDistro distro,
    ProjectOutlet outlet, {
    required Set<PowerPhase> occupiedPhases,
  }) async {
    final result = await showDialog<_ConnectionResult>(
      context: context,
      builder: (context) => _QuickConnectDialog(
        project: _controller.project,
        sourceDistro: distro,
        outlet: outlet,
        occupiedPhases: occupiedPhases,
      ),
    );

    if (result == null) {
      return;
    }

    await _addConnectionsFromResult(result);
  }

  Future<void> _openOutletDetailsDialog(
    ProjectDistro distro,
    ProjectOutlet outlet,
    List<PowerConnection> connections,
  ) async {
    final action = await showDialog<_OutletDetailsAction>(
      context: context,
      builder: (context) => _OutletDetailsDialog(
        project: _controller.project,
        outlet: outlet,
        connections: connections,
        onSaveNotes: (connection, notes) => _runMutation(
          () => _controller.editConnectionNotes(connection, notes),
        ),
        onDisconnect: (connection) =>
            _runMutation(() => _controller.deleteConnection(connection)),
      ),
    );

    if (!mounted || action != _OutletDetailsAction.addAnother) {
      return;
    }

    final occupiedPhases = <PowerPhase>{};
    for (final connection in connections) {
      if (connection.targetType == PowerConnectionTargetType.distro) {
        occupiedPhases.addAll(const [
          PowerPhase.l1,
          PowerPhase.l2,
          PowerPhase.l3,
        ]);
      } else {
        occupiedPhases.addAll(connection.selectedPhases);
      }
    }

    await _openQuickConnectDialog(
      distro,
      outlet,
      occupiedPhases: occupiedPhases,
    );
  }

  Future<void> _openAddGroupDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _GroupNameDialog(
        title: 'Dodaj grupę',
        confirmLabel: 'Dodaj',
        initialName: 'Nowa grupa',
      ),
    );

    final trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty) {
      return;
    }

    await _runMutation(() => _controller.addGroup(trimmedName));
  }

  Future<void> _openEditGroupDialog(ProjectGroup group) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _GroupNameDialog(
        title: 'Edytuj grupę',
        confirmLabel: 'Zapisz',
        initialName: group.name,
      ),
    );

    final trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty) {
      return;
    }

    await _runMutation(() => _controller.editGroup(group, trimmedName));
  }

  Future<void> _deleteGroup(ProjectGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć grupę?'),
        content: Text(
          'Grupa "${group.name}" i jej pozycje zostaną usunięte lokalnie.',
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

    await _runMutation(() => _controller.deleteGroup(group));
  }

  Future<void> _openAddItemDialog(ProjectGroup group) async {
    final result = await showDialog<_ItemFormResult>(
      context: context,
      builder: (context) =>
          const _ItemDialog(title: 'Dodaj pozycję', confirmLabel: 'Dodaj'),
    );

    if (result == null) {
      return;
    }

    await _runMutation(
      () => _controller.addItem(
        group,
        name: result.name,
        quantity: result.quantity,
        powerW: result.powerW,
        currentA: result.currentA,
        weightKg: result.weightKg,
      ),
    );
  }

  Future<void> _openAddCatalogItemDialog(ProjectGroup group) async {
    final devices = await _controller.loadCatalogDevices();

    if (!mounted) {
      return;
    }

    final result = await showDialog<_CatalogSelectionResult>(
      context: context,
      builder: (context) => _CatalogSelectionDialog(devices: devices),
    );

    if (result == null) {
      return;
    }

    await _runMutation(
      () => _controller.addCatalogItem(group, result.device, result.quantity),
    );
  }

  Future<void> _openEditItemDialog(ProjectGroup group, ProjectItem item) async {
    final result = await showDialog<_ItemFormResult>(
      context: context,
      builder: (context) => _ItemDialog(
        title: 'Edytuj pozycję',
        confirmLabel: 'Zapisz',
        item: item,
      ),
    );

    if (result == null) {
      return;
    }

    await _runMutation(
      () => _controller.editItem(
        group,
        item,
        name: result.name,
        quantity: result.quantity,
        powerW: result.powerW,
        currentA: result.currentA,
        weightKg: result.weightKg,
      ),
    );
  }

  Future<void> _deleteItem(ProjectGroup group, ProjectItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć pozycję?'),
        content: Text('"${item.nameSnapshot}" zostanie usunięta z grupy.'),
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

    await _runMutation(() => _controller.deleteItem(group, item));
  }

  List<CatalogDevice> get _trussDevices => _controller.catalogDevices
      .where((device) => device.category == CatalogDeviceCategory.rigging)
      .toList();

  Future<void> _openAddTrussDialog(List<ProjectGroup> groups) async {
    final result = await showDialog<_TrussFormResult>(
      context: context,
      builder: (context) =>
          _TrussDialog(groups: groups, trussDevices: _trussDevices),
    );

    if (result == null) {
      return;
    }

    await _runMutation(
      () => _controller.addTruss(
        name: result.name,
        lengthM: result.lengthM,
        trussCatalogDeviceId: result.trussCatalogDeviceId,
        manualLoadKg: result.manualLoadKg,
        maxTotalLoadKg: result.maxTotalLoadKg,
        maxDistributedLoadKgPerM: result.maxDistributedLoadKgPerM,
        assignedGroupIds: result.assignedGroupIds,
        notes: result.notes,
      ),
    );
  }

  Future<void> _openEditTrussDialog(
    ProjectTruss truss,
    List<ProjectGroup> groups,
  ) async {
    final result = await showDialog<_TrussFormResult>(
      context: context,
      builder: (context) => _TrussDialog(
        truss: truss,
        groups: groups,
        trussDevices: _trussDevices,
      ),
    );

    if (result == null) {
      return;
    }

    await _runMutation(
      () => _controller.editTruss(
        truss,
        name: result.name,
        lengthM: result.lengthM,
        trussCatalogDeviceId: result.trussCatalogDeviceId,
        manualLoadKg: result.manualLoadKg,
        maxTotalLoadKg: result.maxTotalLoadKg,
        maxDistributedLoadKgPerM: result.maxDistributedLoadKgPerM,
        assignedGroupIds: result.assignedGroupIds,
        notes: result.notes,
      ),
    );
  }

  Future<void> _deleteTruss(ProjectTruss truss) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć kratownicę?'),
        content: Text('"${truss.name}" zostanie usunięta lokalnie.'),
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

    await _runMutation(() => _controller.deleteTruss(truss));
  }

  List<ProjectGroup> _groupsNeedingHooks(Project project) {
    return project.groups
        .where((group) => _controller.hookRequirement(group).requiredHooks > 0)
        .toList();
  }

  Future<void> _openAddHookDialog(ProjectGroup group) async {
    final devices = await _controller.loadCatalogDevices();

    if (!mounted) {
      return;
    }

    final result = await showDialog<_CatalogSelectionResult>(
      context: context,
      builder: (context) => _CatalogSelectionDialog(devices: devices),
    );

    if (result == null) {
      return;
    }

    await _runMutation(
      () => _controller.addHookAssignment(
        group,
        result.device,
        result.quantity.round().clamp(1, 1 << 30),
      ),
    );
  }
}
