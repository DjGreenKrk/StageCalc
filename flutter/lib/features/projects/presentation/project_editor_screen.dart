import 'package:flutter/material.dart';

import '../../../infrastructure/local_database/app_database_provider.dart';
import '../../../shared/widgets/greencrew_button.dart';
import '../../../shared/widgets/greencrew_card.dart';
import '../../../shared/widgets/greencrew_section_header.dart';
import '../../catalog/data/drift_catalog_repository.dart';
import '../../catalog/domain/entities/catalog_device.dart';
import '../../clients/data/drift_client_repository.dart';
import '../../clients/domain/entities/client.dart';
import '../../locations/data/drift_location_repository.dart';
import '../../locations/domain/entities/location.dart';
import '../../power_presets/data/drift_power_preset_repository.dart';
import '../../power_presets/domain/entities/power_preset.dart';
import '../data/project_repository.dart';
import '../domain/entities/power_models.dart';
import '../domain/entities/project_models.dart';
import '../domain/services/patch_validation_service.dart';
import '../domain/services/power_calculation_service.dart';
import '../domain/services/project_totals_service.dart';

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
  late Project _project;
  List<Client> _clients = const [];
  List<Location> _locations = const [];
  List<PowerPreset> _powerPresets = const [];
  var _view = _ProjectEditorView.equipment;
  var _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadProjectReferences();
  }

  @override
  Widget build(BuildContext context) {
    const totalsService = ProjectTotalsService();
    const powerService = PowerCalculationService();
    const validationService = PatchValidationService();
    final totals = totalsService.calculate(_project);
    final powerLoads = powerService.calculateProjectLoads(_project);
    final patchValidation = validationService.validate(_project);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_hasChanges);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_project.name)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProjectMetadataCard(
              project: _project,
              clients: _clients,
              locations: _locations,
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
                    label: 'Prad',
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
            SegmentedButton<_ProjectEditorView>(
              segments: const [
                ButtonSegment(
                  value: _ProjectEditorView.equipment,
                  icon: Icon(Icons.view_list_outlined),
                  label: Text('Sprzet'),
                ),
                ButtonSegment(
                  value: _ProjectEditorView.patcher,
                  icon: Icon(Icons.cable),
                  label: Text('Patcher'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (selection) {
                setState(() => _view = selection.single);
              },
            ),
            const SizedBox(height: 16),
            if (_view == _ProjectEditorView.equipment) ...[
              GreenCrewSectionHeader(
                title: 'Grupy',
                action: GreenCrewButton(
                  label: 'Dodaj grupe',
                  icon: Icons.add,
                  onPressed: _openAddGroupDialog,
                  secondary: true,
                ),
              ),
              const SizedBox(height: 12),
              if (_project.groups.isEmpty)
                const GreenCrewCard(
                  child: Text('Brak grup. Dodaj pierwsza grupe urzadzen.'),
                )
              else
                for (final group in _project.groups) ...[
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
            ] else ...[
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
              if (_project.distros.isEmpty)
                const GreenCrewCard(
                  child: Text('Brak rozdzielnic w projekcie.'),
                )
              else
                for (final distro in _project.distros) ...[
                  _DistroCard(
                    distro: distro,
                    isPowerSource: !_project.connections.any(
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
                  ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 16),
              GreenCrewSectionHeader(
                title: 'Polaczenia',
                action: GreenCrewButton(
                  label: 'Polacz',
                  icon: Icons.cable,
                  onPressed: _canCreateConnection
                      ? _openAddConnectionDialog
                      : null,
                  secondary: true,
                ),
              ),
              const SizedBox(height: 12),
              if (_project.connections.isEmpty)
                const GreenCrewCard(
                  child: Text('Brak polaczen grup z rozdzielnicami.'),
                )
              else
                for (final connection in _project.connections) ...[
                  _ConnectionCard(
                    connection: connection,
                    project: _project,
                    patchValidation: patchValidation,
                    onDelete: () => _deleteConnection(connection),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ],
        ),
      ),
    );
  }

  bool get _canCreateConnection {
    return (_project.groups.isNotEmpty || _project.distros.length > 1) &&
        _project.distros.any((distro) => distro.outlets.isNotEmpty);
  }

  Future<void> _loadProjectReferences() async {
    final database = AppDatabaseProvider.instance;
    final clients = await DriftClientRepository(database).getClients();
    final locations = await DriftLocationRepository(database).getLocations();
    final powerPresetRepository = DriftPowerPresetRepository(database);
    await powerPresetRepository.ensureSeedData();
    final powerPresets = await powerPresetRepository.getPresets();

    if (!mounted) {
      return;
    }

    setState(() {
      _clients = clients;
      _locations = locations;
      _powerPresets = powerPresets;
    });
  }

  Future<void> _openProjectMetadataDialog() async {
    final result = await showDialog<_ProjectMetadataResult>(
      context: context,
      builder: (context) => _ProjectMetadataDialog(
        project: _project,
        clients: _clients,
        locations: _locations,
      ),
    );

    if (result == null) {
      return;
    }

    await _saveProject(
      _project.copyWith(
        name: result.name,
        clientId: result.clientId,
        locationId: result.locationId,
        clearClientId: result.clientId == null,
        clearLocationId: result.locationId == null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _openAddDistroMenu() async {
    final projectLocation = _locations
        .where((location) => location.id == _project.locationId)
        .firstOrNull;
    final result = await showDialog<_DistroCreateResult>(
      context: context,
      builder: (context) => _DistroCreateDialog(
        presets: _powerPresets,
        location: projectLocation,
      ),
    );

    if (result == null) {
      return;
    }

    await _addDistro(
      name: result.name,
      sourceType: result.sourceType,
      presetId: result.preset?.id,
      locationConnectorGroupId: result.locationConnectorGroupId,
      inputConnectorTypeId: result.inputConnectorTypeId,
      outletTemplates: result.outlets,
    );
  }

  Future<void> _addDistro({
    required String name,
    required ProjectDistroSourceType sourceType,
    required String? inputConnectorTypeId,
    required List<PowerOutletTemplate> outletTemplates,
    String? presetId,
    String? locationConnectorGroupId,
  }) async {
    final now = DateTime.now();
    final distroId = 'distro_${now.microsecondsSinceEpoch}';
    final outlets = <ProjectOutlet>[];

    for (final (index, outletTemplate) in outletTemplates.indexed) {
      final connector = ConnectorTypes.findById(outletTemplate.connectorTypeId);
      outlets.add(
        ProjectOutlet(
          id: 'outlet_${now.microsecondsSinceEpoch}_$index',
          templateOutletId: outletTemplate.id,
          name: outletTemplate.name,
          connectorTypeId: outletTemplate.connectorTypeId,
          phase: outletTemplate.phase,
          maxCurrentA: connector?.maxCurrentA ?? 0,
        ),
      );
    }

    final distro = ProjectDistro(
      id: distroId,
      phaseId: _project.phaseId,
      name: name,
      sourceType: sourceType,
      presetId: presetId,
      locationConnectorGroupId: locationConnectorGroupId,
      inputConnectorTypeId: inputConnectorTypeId,
      isRootPowerSource: _project.distros.isEmpty,
      outlets: outlets,
    );

    await _saveProject(
      _project.copyWith(distros: [..._project.distros, distro], updatedAt: now),
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

    final now = DateTime.now();
    final distros = _project.distros.map((candidate) {
      if (candidate.id != distro.id) {
        return candidate;
      }

      return ProjectDistro(
        id: candidate.id,
        phaseId: candidate.phaseId,
        name: result.name,
        sourceType: ProjectDistroSourceType.manual,
        catalogDeviceId: candidate.catalogDeviceId,
        locationConnectorGroupId: candidate.locationConnectorGroupId,
        presetId: candidate.presetId,
        inputConnectorTypeId: result.inputConnectorTypeId,
        isRootPowerSource: candidate.isRootPowerSource,
        outlets: result.outlets,
      );
    }).toList();
    final outletIds = result.outlets.map((outlet) => outlet.id).toSet();

    await _saveProject(
      _project.copyWith(
        distros: distros,
        connections: _project.connections
            .where(
              (connection) =>
                  connection.sourceDistroId != distro.id ||
                  outletIds.contains(connection.sourceOutletId),
            )
            .toList(),
        updatedAt: now,
      ),
    );
  }

  Future<void> _deleteDistro(ProjectDistro distro) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunac rozdzielnice?'),
        content: Text('"${distro.name}" zostanie usunieta lokalnie.'),
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

    final now = DateTime.now();
    await _saveProject(
      _project.copyWith(
        distros: _project.distros
            .where((candidate) => candidate.id != distro.id)
            .toList(),
        connections: _project.connections
            .where(
              (connection) =>
                  connection.sourceDistroId != distro.id &&
                  connection.targetDistroId != distro.id,
            )
            .toList(),
        updatedAt: now,
      ),
    );
  }

  Future<void> _openAddConnectionDialog() async {
    final result = await showDialog<_ConnectionResult>(
      context: context,
      builder: (context) => _ConnectionDialog(project: _project),
    );

    if (result == null) {
      return;
    }

    final now = DateTime.now();
    final connections = [
      for (final source in result.sources.indexed)
        PowerConnection(
          id: 'connection_${now.microsecondsSinceEpoch}_${source.$1}',
          phaseId: _project.phaseId,
          sourceDistroId: source.$2.sourceDistroId,
          sourceOutletId: source.$2.sourceOutletId,
          targetType: result.targetType,
          targetGroupId: result.targetGroupId,
          targetDistroId: result.targetDistroId,
          selectedPhases: result.selectedPhases,
        ),
    ];

    await _saveProject(
      _project.copyWith(
        distros: result.targetType == PowerConnectionTargetType.distro
            ? _project.distros
                  .map(
                    (distro) => distro.id == result.targetDistroId
                        ? _copyDistro(distro, isRootPowerSource: false)
                        : distro,
                  )
                  .toList()
            : _project.distros,
        connections: [..._project.connections, ...connections],
        updatedAt: now,
      ),
    );
  }

  Future<void> _deleteConnection(PowerConnection connection) async {
    final now = DateTime.now();
    await _saveProject(
      _project.copyWith(
        connections: _project.connections
            .where((candidate) => candidate.id != connection.id)
            .toList(),
        updatedAt: now,
      ),
    );
  }

  Future<void> _openAddGroupDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _GroupNameDialog(
        title: 'Dodaj grupe',
        confirmLabel: 'Dodaj',
        initialName: 'Nowa grupa',
      ),
    );

    final trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final group = ProjectGroup(
      id: 'group_${now.microsecondsSinceEpoch}',
      name: trimmedName,
      items: const [],
    );

    await _saveProject(
      _project.copyWith(groups: [..._project.groups, group], updatedAt: now),
    );
  }

  Future<void> _openEditGroupDialog(ProjectGroup group) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _GroupNameDialog(
        title: 'Edytuj grupe',
        confirmLabel: 'Zapisz',
        initialName: group.name,
      ),
    );

    final trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final groups = _project.groups.map((candidate) {
      if (candidate.id != group.id) {
        return candidate;
      }
      return candidate.copyWith(name: trimmedName);
    }).toList();

    await _saveProject(_project.copyWith(groups: groups, updatedAt: now));
  }

  Future<void> _deleteGroup(ProjectGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunac grupe?'),
        content: Text(
          'Grupa "${group.name}" i jej pozycje zostana usuniete lokalnie.',
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

    final now = DateTime.now();
    final groups = _project.groups
        .where((candidate) => candidate.id != group.id)
        .toList();

    await _saveProject(_project.copyWith(groups: groups, updatedAt: now));
  }

  Future<void> _openAddItemDialog(ProjectGroup group) async {
    final result = await showDialog<_ItemFormResult>(
      context: context,
      builder: (context) =>
          const _ItemDialog(title: 'Dodaj pozycje', confirmLabel: 'Dodaj'),
    );

    if (result == null) {
      return;
    }

    final now = DateTime.now();
    final item = ProjectItem(
      id: 'item_${now.microsecondsSinceEpoch}',
      nameSnapshot: result.name,
      quantity: result.quantity,
      powerWSnapshot: result.powerW,
      currentASnapshot: result.currentA,
      weightKgSnapshot: result.weightKg,
    );

    final groups = _project.groups.map((candidate) {
      if (candidate.id != group.id) {
        return candidate;
      }
      return candidate.copyWith(items: [...candidate.items, item]);
    }).toList();

    await _saveProject(_project.copyWith(groups: groups, updatedAt: now));
  }

  Future<void> _openAddCatalogItemDialog(ProjectGroup group) async {
    final repository = DriftCatalogRepository(AppDatabaseProvider.instance);
    await repository.ensureSeedData();
    final devices = await repository.getDevices();

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

    final now = DateTime.now();
    final device = result.device;
    final item = ProjectItem(
      id: 'item_${now.microsecondsSinceEpoch}',
      catalogDeviceId: device.id,
      nameSnapshot: device.name,
      manufacturerSnapshot: device.manufacturer,
      quantity: result.quantity,
      powerWSnapshot: device.powerW,
      currentASnapshot: device.currentA,
      weightKgSnapshot: device.weightKg,
      unit: _mapCatalogUnit(device.quantityUnit),
    );

    final groups = _project.groups.map((candidate) {
      if (candidate.id != group.id) {
        return candidate;
      }
      return candidate.copyWith(items: [...candidate.items, item]);
    }).toList();

    await _saveProject(_project.copyWith(groups: groups, updatedAt: now));
  }

  Future<void> _openEditItemDialog(ProjectGroup group, ProjectItem item) async {
    final result = await showDialog<_ItemFormResult>(
      context: context,
      builder: (context) => _ItemDialog(
        title: 'Edytuj pozycje',
        confirmLabel: 'Zapisz',
        item: item,
      ),
    );

    if (result == null) {
      return;
    }

    final now = DateTime.now();
    final updatedItem = item.copyWith(
      nameSnapshot: result.name,
      quantity: result.quantity,
      powerWSnapshot: result.powerW,
      currentASnapshot: result.currentA,
      weightKgSnapshot: result.weightKg,
    );

    final groups = _project.groups.map((candidate) {
      if (candidate.id != group.id) {
        return candidate;
      }

      final items = candidate.items.map((candidateItem) {
        if (candidateItem.id != item.id) {
          return candidateItem;
        }
        return updatedItem;
      }).toList();

      return candidate.copyWith(items: items);
    }).toList();

    await _saveProject(_project.copyWith(groups: groups, updatedAt: now));
  }

  Future<void> _deleteItem(ProjectGroup group, ProjectItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunac pozycje?'),
        content: Text('"${item.nameSnapshot}" zostanie usunieta z grupy.'),
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

    final now = DateTime.now();
    final groups = _project.groups.map((candidate) {
      if (candidate.id != group.id) {
        return candidate;
      }

      return candidate.copyWith(
        items: candidate.items
            .where((candidateItem) => candidateItem.id != item.id)
            .toList(),
      );
    }).toList();

    await _saveProject(_project.copyWith(groups: groups, updatedAt: now));
  }

  Future<void> _saveProject(Project project) async {
    await widget.repository.saveProject(project);

    if (!mounted) {
      return;
    }

    setState(() {
      _project = project;
      _hasChanges = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Projekt zapisany lokalnie')));
  }

  ProjectItemUnit _mapCatalogUnit(CatalogQuantityUnit unit) {
    return switch (unit) {
      CatalogQuantityUnit.pcs => ProjectItemUnit.pcs,
      CatalogQuantityUnit.meters => ProjectItemUnit.meters,
    };
  }
}

enum _ProjectEditorView { equipment, patcher }

class _ProjectMetadataCard extends StatelessWidget {
  const _ProjectMetadataCard({
    required this.project,
    required this.clients,
    required this.locations,
    required this.onEdit,
  });

  final Project project;
  final List<Client> clients;
  final List<Location> locations;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final clientName = clients
        .where((client) => client.id == project.clientId)
        .firstOrNull
        ?.name;
    final client = clients
        .where((client) => client.id == project.clientId)
        .firstOrNull;
    final locationName = locations
        .where((location) => location.id == project.locationId)
        .firstOrNull
        ?.name;
    final location = locations
        .where((location) => location.id == project.locationId)
        .firstOrNull;

    return GreenCrewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dane projektu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Edytuj dane projektu',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(project.name),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.badge_outlined, size: 16),
                label: Text(clientName ?? 'Bez klienta'),
                onPressed: client == null
                    ? null
                    : () => _showClientSummary(context, client),
              ),
              ActionChip(
                avatar: const Icon(Icons.location_city_outlined, size: 16),
                label: Text(locationName ?? 'Bez lokacji'),
                onPressed: location == null
                    ? null
                    : () => _showLocationSummary(context, location),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClientSummary(BuildContext context, Client client) {
    showDialog<void>(
      context: context,
      builder: (context) => _InfoSummaryDialog(
        title: client.name,
        icon: Icons.badge_outlined,
        rows: [
          _InfoRow('Kontakt', client.contactPerson),
          _InfoRow('Telefon', client.phone),
          _InfoRow('Email', client.email),
          _InfoRow('NIP', client.nip),
          _InfoRow('Adres', client.address),
          _InfoRow('Notatki', client.notes),
        ],
      ),
    );
  }

  void _showLocationSummary(BuildContext context, Location location) {
    showDialog<void>(
      context: context,
      builder: (context) => _InfoSummaryDialog(
        title: location.name,
        icon: Icons.location_city_outlined,
        rows: [
          _InfoRow('Adres', location.address),
          _InfoRow(
            'Pojemnosc',
            location.capacity == null ? null : '${location.capacity}',
          ),
          _InfoRow('Kontakt', location.contactName),
          _InfoRow('Telefon', location.contactPhone),
          _InfoRow('Email', location.contactEmail),
          _InfoRow('Notatki', location.notes),
        ],
      ),
    );
  }
}

class _InfoSummaryDialog extends StatelessWidget {
  const _InfoSummaryDialog({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows
        .where((row) => row.value != null && row.value!.trim().isNotEmpty)
        .toList();

    return AlertDialog(
      title: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: visibleRows.isEmpty
          ? const Text('Brak dodatkowych danych.')
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final row in visibleRows) ...[
                  Text(
                    row.label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(row.value!),
                  const SizedBox(height: 10),
                ],
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zamknij'),
        ),
      ],
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;
}

class _ProjectMetadataDialog extends StatefulWidget {
  const _ProjectMetadataDialog({
    required this.project,
    required this.clients,
    required this.locations,
  });

  final Project project;
  final List<Client> clients;
  final List<Location> locations;

  @override
  State<_ProjectMetadataDialog> createState() => _ProjectMetadataDialogState();
}

class _ProjectMetadataDialogState extends State<_ProjectMetadataDialog> {
  late final TextEditingController _nameController;
  String? _clientId;
  String? _locationId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _clientId = widget.project.clientId;
    _locationId = widget.project.locationId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edytuj dane projektu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nazwa projektu'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _clientId,
              decoration: const InputDecoration(labelText: 'Klient'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Bez klienta'),
                ),
                for (final client in widget.clients)
                  DropdownMenuItem<String?>(
                    value: client.id,
                    child: Text(client.name),
                  ),
              ],
              onChanged: (value) => setState(() => _clientId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _locationId,
              decoration: const InputDecoration(labelText: 'Lokacja'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Bez lokacji'),
                ),
                for (final location in widget.locations)
                  DropdownMenuItem<String?>(
                    value: location.id,
                    child: Text(location.name),
                  ),
              ],
              onChanged: (value) => setState(() => _locationId = value),
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

    Navigator.of(context).pop(
      _ProjectMetadataResult(
        name: name,
        clientId: _clientId,
        locationId: _locationId,
      ),
    );
  }
}

class _ProjectMetadataResult {
  const _ProjectMetadataResult({
    required this.name,
    required this.clientId,
    required this.locationId,
  });

  final String name;
  final String? clientId;
  final String? locationId;
}

class _DistroCard extends StatelessWidget {
  const _DistroCard({
    required this.distro,
    required this.isPowerSource,
    required this.outletLoads,
    required this.patchValidation,
    required this.onEdit,
    required this.onDelete,
    this.phaseLoad,
    this.distroLoad,
  });

  final ProjectDistro distro;
  final bool isPowerSource;
  final PowerPhaseLoad? phaseLoad;
  final DistroPowerLoad? distroLoad;
  final Map<String, OutletPowerLoad> outletLoads;
  final PatchValidationResult patchValidation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GreenCrewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  distro.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (isPowerSource)
                const Chip(
                  avatar: Icon(Icons.power, size: 16),
                  label: Text('Zrodlo'),
                ),
              IconButton(
                tooltip: 'Edytuj rozdzielnice',
                onPressed: onEdit,
                icon: const Icon(Icons.tune),
              ),
              IconButton(
                tooltip: 'Usun rozdzielnice',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.input, size: 16),
                label: Text(_connectorLabel(distro.inputConnectorTypeId)),
              ),
              if (distro.sourceType == ProjectDistroSourceType.location)
                const Chip(
                  avatar: Icon(Icons.location_city_outlined, size: 16),
                  label: Text('Lokacja'),
                ),
              if ((distroLoad?.isInputOverloaded ?? false) ||
                  (distroLoad?.isInputNearLimit ?? false))
                _StatusChip(
                  label:
                      'Wejscie ${distroLoad!.maxLoadedPhaseA.toStringAsFixed(1)}/'
                      '${distroLoad!.inputMaxCurrentA.toStringAsFixed(0)} A',
                  isError: distroLoad!.isInputOverloaded,
                  isWarning: distroLoad!.isInputNearLimit,
                ),
              Chip(
                avatar: const Icon(Icons.power, size: 16),
                label: Text('${distro.outlets.length} gniazd'),
              ),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LoadChip(
                label: 'L1',
                value: phaseLoad?.l1A ?? 0,
                maxValue: distroLoad?.inputMaxCurrentA ?? 0,
                isOverloaded:
                    distroLoad?.isPhaseOverloaded(PowerPhase.l1) ?? false,
                isNearLimit:
                    distroLoad?.isPhaseNearLimit(PowerPhase.l1) ?? false,
              ),
              _LoadChip(
                label: 'L2',
                value: phaseLoad?.l2A ?? 0,
                maxValue: distroLoad?.inputMaxCurrentA ?? 0,
                isOverloaded:
                    distroLoad?.isPhaseOverloaded(PowerPhase.l2) ?? false,
                isNearLimit:
                    distroLoad?.isPhaseNearLimit(PowerPhase.l2) ?? false,
              ),
              _LoadChip(
                label: 'L3',
                value: phaseLoad?.l3A ?? 0,
                maxValue: distroLoad?.inputMaxCurrentA ?? 0,
                isOverloaded:
                    distroLoad?.isPhaseOverloaded(PowerPhase.l3) ?? false,
                isNearLimit:
                    distroLoad?.isPhaseNearLimit(PowerPhase.l3) ?? false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final outlet in distro.outlets)
                _OutletLoadChip(
                  outlet: outlet,
                  load: outletLoads[outlet.id],
                  isDuplicated: patchValidation.isOutletDuplicated(outlet.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadChip extends StatelessWidget {
  const _LoadChip({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.isOverloaded,
    required this.isNearLimit,
  });

  final String label;
  final double value;
  final double maxValue;
  final bool isOverloaded;
  final bool isNearLimit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final valueText = maxValue > 0
        ? '${value.toStringAsFixed(1)}/${maxValue.toStringAsFixed(0)} A'
        : '${value.toStringAsFixed(1)} A';

    return Chip(
      avatar: Icon(
        isOverloaded || isNearLimit ? Icons.warning_amber : Icons.bolt,
        size: 16,
      ),
      backgroundColor: isOverloaded
          ? colorScheme.errorContainer
          : isNearLimit
          ? Colors.amber.shade700
          : null,
      label: Text('$label $valueText'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isError,
    required this.isWarning,
  });

  final String label;
  final bool isError;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: const Icon(Icons.warning_amber, size: 16),
      backgroundColor: isError
          ? colorScheme.errorContainer
          : isWarning
          ? Colors.amber.shade700
          : null,
      label: Text(label),
    );
  }
}

class _OutletLoadChip extends StatelessWidget {
  const _OutletLoadChip({
    required this.outlet,
    required this.isDuplicated,
    this.load,
  });

  final ProjectOutlet outlet;
  final bool isDuplicated;
  final OutletPowerLoad? load;

  @override
  Widget build(BuildContext context) {
    final outletLoad = load;
    final isOverloaded = outletLoad?.isOverloaded ?? false;
    final isNearLimit = outletLoad?.isNearLimit ?? false;
    final hasLoad = outletLoad?.hasLoad ?? false;
    final colorScheme = Theme.of(context).colorScheme;
    final phaseLoad = outletLoad?.maxLoadedPhaseA ?? 0;

    return Chip(
      avatar: Icon(
        isDuplicated
            ? Icons.link_off
            : isOverloaded || isNearLimit
            ? Icons.warning_amber
            : hasLoad
            ? Icons.bolt
            : Icons.power_outlined,
        size: 16,
      ),
      backgroundColor: isDuplicated || isOverloaded
          ? colorScheme.errorContainer
          : isNearLimit
          ? Colors.amber.shade700
          : hasLoad
          ? colorScheme.primaryContainer
          : null,
      label: Text(
        '${outlet.name} ${_phaseLabel(outlet.phase)} '
        '${phaseLoad.toStringAsFixed(1)}/${outlet.maxCurrentA.toStringAsFixed(0)} A',
      ),
    );
  }
}

class _DistroCreateDialog extends StatefulWidget {
  const _DistroCreateDialog({required this.presets, required this.location});

  final List<PowerPreset> presets;
  final Location? location;

  @override
  State<_DistroCreateDialog> createState() => _DistroCreateDialogState();
}

class _DistroCreateDialogState extends State<_DistroCreateDialog> {
  late final TextEditingController _nameController;
  _DistroCreateMode _mode = _DistroCreateMode.quick;
  _QuickDistroTemplate _quickTemplate = _QuickDistroTemplate.schukoSingle;
  String? _customInputConnectorTypeId = 'cee_32a_5p';
  List<_CustomOutletGroup> _customOutletGroups = const [
    _CustomOutletGroup(
      id: 'default_schuko',
      label: 'Schuko',
      connectorTypeId: 'schuko_16a',
      count: 6,
      phaseMode: _CustomDistroPhaseMode.balanced,
    ),
  ];
  PowerPreset? _selectedPreset;
  LocationPowerConnector? _selectedLocationConnector;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.presets.firstOrNull;
    _selectedLocationConnector = widget.location?.powerConnectors.firstOrNull;
    _nameController = TextEditingController(text: _quickTemplate.label);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPreset = _selectedPreset;
    final selectedOutlets = _selectedOutlets;
    final inputConnectorTypeId = _inputConnectorTypeId;

    return AlertDialog(
      title: const Text('Dodaj rozdzielnice'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<_DistroCreateMode>(
              segments: const [
                ButtonSegment(
                  value: _DistroCreateMode.quick,
                  icon: Icon(Icons.flash_on),
                  label: Text('Szybka'),
                ),
                ButtonSegment(
                  value: _DistroCreateMode.preset,
                  icon: Icon(Icons.inventory_2_outlined),
                  label: Text('Preset'),
                ),
                ButtonSegment(
                  value: _DistroCreateMode.custom,
                  icon: Icon(Icons.tune),
                  label: Text('Custom'),
                ),
                ButtonSegment(
                  value: _DistroCreateMode.location,
                  icon: Icon(Icons.location_city_outlined),
                  label: Text('Lokacja'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() {
                  _mode = selection.single;
                  _nameController.text = switch (_mode) {
                    _DistroCreateMode.quick => _quickTemplate.label,
                    _DistroCreateMode.custom => 'Rozdzielnica custom',
                    _DistroCreateMode.location =>
                      _selectedLocationConnector == null
                          ? 'Zasilanie z lokacji'
                          : '${widget.location?.name ?? 'Lokacja'} / ${_selectedLocationConnector!.name}',
                    _DistroCreateMode.preset =>
                      _selectedPreset?.name ?? 'Nowa rozdzielnica',
                  };
                });
              },
            ),
            const SizedBox(height: 12),
            if (_mode == _DistroCreateMode.quick)
              DropdownButtonFormField<_QuickDistroTemplate>(
                initialValue: _quickTemplate,
                decoration: const InputDecoration(labelText: 'Typ'),
                items: _QuickDistroTemplate.values
                    .map(
                      (template) => DropdownMenuItem(
                        value: template,
                        child: Text(template.label),
                      ),
                    )
                    .toList(),
                onChanged: (template) {
                  if (template != null) {
                    setState(() {
                      _quickTemplate = template;
                      _nameController.text = template.label;
                    });
                  }
                },
              )
            else if (_mode == _DistroCreateMode.custom) ...[
              _connectorDropdown(
                label: 'Wejscie',
                value: _customInputConnectorTypeId,
                allowEmpty: true,
                onChanged: (value) {
                  setState(() {
                    _customInputConnectorTypeId = value;
                    _customOutletGroups = _normalizeCustomOutletGroups(
                      _customOutletGroups,
                      value,
                    );
                  });
                },
              ),
              const SizedBox(height: 12),
              _OutletGroupsEditor(
                groups: _customOutletGroups,
                inputConnectorTypeId: _customInputConnectorTypeId,
                onChanged: (groups) {
                  setState(() {
                    _customOutletGroups = _normalizeCustomOutletGroups(
                      groups,
                      _customInputConnectorTypeId,
                    );
                  });
                },
              ),
            ] else if (_mode == _DistroCreateMode.location) ...[
              if (widget.location == null)
                const Text('Projekt nie ma przypisanej lokacji.')
              else if (widget.location!.powerConnectors.isEmpty)
                const Text('Lokacja nie ma zapisanych grup zlaczy.')
              else
                DropdownButtonFormField<LocationPowerConnector>(
                  initialValue: _selectedLocationConnector,
                  decoration: const InputDecoration(labelText: 'Grupa zlaczy'),
                  items: widget.location!.powerConnectors
                      .map(
                        (connector) => DropdownMenuItem(
                          value: connector,
                          child: Text(
                            '${connector.name} / ${connector.quantity}x '
                            '${_connectorLabel(connector.connectorTypeId)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (connector) {
                    if (connector != null) {
                      setState(() {
                        _selectedLocationConnector = connector;
                        _nameController.text =
                            '${widget.location!.name} / ${connector.name}';
                      });
                    }
                  },
                ),
            ] else if (widget.presets.isEmpty)
              const Text('Brak presetow rozdzielnic.')
            else
              DropdownButtonFormField<PowerPreset>(
                initialValue: selectedPreset,
                decoration: const InputDecoration(labelText: 'Preset'),
                items: widget.presets
                    .map(
                      (preset) => DropdownMenuItem(
                        value: preset,
                        child: Text(preset.name),
                      ),
                    )
                    .toList(),
                onChanged: (preset) {
                  setState(() {
                    _selectedPreset = preset;
                    if (preset != null) {
                      _nameController.text = preset.name;
                    }
                  });
                },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nazwa'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.input, size: 16),
                    label: Text(_connectorLabel(inputConnectorTypeId)),
                  ),
                  Chip(
                    avatar: const Icon(Icons.power, size: 16),
                    label: Text('${selectedOutlets.length} gniazd'),
                  ),
                  for (final outlet in selectedOutlets)
                    Chip(
                      label: Text(
                        '${outlet.name} ${_connectorLabel(outlet.connectorTypeId)}',
                      ),
                    ),
                ],
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
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Dodaj'),
        ),
      ],
    );
  }

  bool get _canSubmit {
    if (_nameController.text.trim().isEmpty) {
      return false;
    }
    if (_mode == _DistroCreateMode.preset) {
      return _selectedPreset != null;
    }
    if (_mode == _DistroCreateMode.custom) {
      return _customOutletGroups.any((group) => group.count > 0);
    }
    if (_mode == _DistroCreateMode.location) {
      return _selectedLocationConnector != null;
    }
    return true;
  }

  String? get _inputConnectorTypeId {
    return switch (_mode) {
      _DistroCreateMode.quick => _quickTemplate.inputConnectorTypeId,
      _DistroCreateMode.preset => _selectedPreset?.inputConnectorTypeId,
      _DistroCreateMode.custom => _customInputConnectorTypeId,
      _DistroCreateMode.location => null,
    };
  }

  List<PowerOutletTemplate> get _selectedOutlets {
    return switch (_mode) {
      _DistroCreateMode.quick => _quickTemplate.outlets,
      _DistroCreateMode.preset =>
        _selectedPreset?.outlets ?? const <PowerOutletTemplate>[],
      _DistroCreateMode.custom => _customOutlets,
      _DistroCreateMode.location => _locationOutlets,
    };
  }

  List<PowerOutletTemplate> get _locationOutlets {
    final connector = _selectedLocationConnector;
    if (connector == null) {
      return const [];
    }

    final count = connector.quantity.clamp(0, 96).toInt();
    return [
      for (var index = 0; index < count; index++)
        PowerOutletTemplate(
          id: 'location_${connector.id}_$index',
          name: _defaultOutletName(
            label: connector.name,
            connectorTypeId: connector.connectorTypeId,
            phase: _phaseForLocationConnector(connector, index, count),
            index: index,
          ),
          connectorTypeId: connector.connectorTypeId,
          phase: _phaseForLocationConnector(connector, index, count),
        ),
    ];
  }

  List<PowerOutletTemplate> get _customOutlets {
    var globalIndex = 0;
    return [
      for (final group in _normalizeCustomOutletGroups(
        _customOutletGroups,
        _customInputConnectorTypeId,
      ))
        for (var index = 0; index < group.count.clamp(0, 48).toInt(); index++)
          PowerOutletTemplate(
            id: 'custom_${globalIndex++}',
            name: _defaultOutletName(
              label: group.label,
              connectorTypeId: group.connectorTypeId,
              phase: group.phaseMode.phaseForIndex(
                index,
                count: group.count.clamp(0, 48).toInt(),
              ),
              index: index,
            ),
            connectorTypeId: group.connectorTypeId,
            phase: group.phaseMode.phaseForIndex(
              index,
              count: group.count.clamp(0, 48).toInt(),
            ),
          ),
    ];
  }

  Widget _connectorDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool allowEmpty = false,
  }) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        if (allowEmpty)
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
      onChanged: onChanged,
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    if (_mode == _DistroCreateMode.preset) {
      final preset = _selectedPreset;
      if (preset == null) {
        return;
      }
      Navigator.of(context).pop(
        _DistroCreateResult(
          name: name,
          sourceType: ProjectDistroSourceType.preset,
          inputConnectorTypeId: preset.inputConnectorTypeId,
          outlets: preset.outlets,
          preset: preset,
        ),
      );
      return;
    }

    if (_mode == _DistroCreateMode.custom) {
      Navigator.of(context).pop(
        _DistroCreateResult(
          name: name,
          sourceType: ProjectDistroSourceType.manual,
          inputConnectorTypeId: _customInputConnectorTypeId,
          outlets: _customOutlets,
        ),
      );
      return;
    }

    if (_mode == _DistroCreateMode.location) {
      final connector = _selectedLocationConnector;
      if (connector == null) {
        return;
      }
      Navigator.of(context).pop(
        _DistroCreateResult(
          name: name,
          sourceType: ProjectDistroSourceType.location,
          inputConnectorTypeId: null,
          outlets: _locationOutlets,
          locationConnectorGroupId: connector.id,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _DistroCreateResult(
        name: name,
        sourceType: ProjectDistroSourceType.quick,
        inputConnectorTypeId: _quickTemplate.inputConnectorTypeId,
        outlets: _quickTemplate.outlets,
      ),
    );
  }
}

enum _DistroCreateMode { quick, preset, custom, location }

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

enum _QuickDistroTemplate {
  schukoSingle,
  schukoQuad,
  cee32SixSchuko,
  cee32Thru,
}

extension _QuickDistroTemplateData on _QuickDistroTemplate {
  String get label {
    return switch (this) {
      _QuickDistroTemplate.schukoSingle => 'Gniazdo 16 A',
      _QuickDistroTemplate.schukoQuad => 'Listwa 4x16 A',
      _QuickDistroTemplate.cee32SixSchuko => 'Rozdzielnia 32 A / 6x Schuko',
      _QuickDistroTemplate.cee32Thru => 'Przedluzka 32 A CEE',
    };
  }

  String? get inputConnectorTypeId {
    return switch (this) {
      _QuickDistroTemplate.schukoSingle => 'schuko_16a',
      _QuickDistroTemplate.schukoQuad => 'schuko_16a',
      _QuickDistroTemplate.cee32SixSchuko => 'cee_32a_5p',
      _QuickDistroTemplate.cee32Thru => 'cee_32a_5p',
    };
  }

  List<PowerOutletTemplate> get outlets {
    return switch (this) {
      _QuickDistroTemplate.schukoSingle => const [
        PowerOutletTemplate(
          id: 'quick_schuko_single',
          name: 'Schuko L1.1',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
      ],
      _QuickDistroTemplate.schukoQuad => const [
        PowerOutletTemplate(
          id: 'quick_schuko_quad_1',
          name: 'Schuko L1.1',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
        PowerOutletTemplate(
          id: 'quick_schuko_quad_2',
          name: 'Schuko L1.2',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
        PowerOutletTemplate(
          id: 'quick_schuko_quad_3',
          name: 'Schuko L1.3',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
        PowerOutletTemplate(
          id: 'quick_schuko_quad_4',
          name: 'Schuko L1.4',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
      ],
      _QuickDistroTemplate.cee32SixSchuko => const [
        PowerOutletTemplate(
          id: 'quick_32a_l1_a',
          name: 'Schuko L1.1',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
        PowerOutletTemplate(
          id: 'quick_32a_l1_b',
          name: 'Schuko L1.2',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l1,
        ),
        PowerOutletTemplate(
          id: 'quick_32a_l2_a',
          name: 'Schuko L2.1',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l2,
        ),
        PowerOutletTemplate(
          id: 'quick_32a_l2_b',
          name: 'Schuko L2.2',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l2,
        ),
        PowerOutletTemplate(
          id: 'quick_32a_l3_a',
          name: 'Schuko L3.1',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l3,
        ),
        PowerOutletTemplate(
          id: 'quick_32a_l3_b',
          name: 'Schuko L3.2',
          connectorTypeId: 'schuko_16a',
          phase: PowerPhase.l3,
        ),
      ],
      _QuickDistroTemplate.cee32Thru => const [
        PowerOutletTemplate(
          id: 'quick_32a_thru',
          name: 'CEE 32A OUT',
          connectorTypeId: 'cee_32a_5p',
          phase: PowerPhase.all,
        ),
      ],
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
                'Sekcje wyjsc',
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
            child: Text('Brak sekcji wyjsc.'),
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
                    tooltip: 'Edytuj sekcje',
                    onPressed: () => _editGroup(context, group),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Usun sekcje',
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
      title: const Text('Sekcja wyjsc'),
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
              decoration: const InputDecoration(labelText: 'Ilosc'),
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
              DropdownButtonFormField<_CustomDistroPhaseMode>(
                initialValue: _phaseMode,
                decoration: const InputDecoration(labelText: 'Rozklad faz'),
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

String _defaultConnectorName(String connectorTypeId) {
  final connector = ConnectorTypes.findById(connectorTypeId);
  return switch (connector?.id) {
    'schuko_16a' => 'Schuko',
    'cee_16a_3p' => 'CEE 16A',
    'cee_16a_5p' => 'CEE 16A',
    'cee_32a_5p' => 'CEE 32A',
    'cee_63a_5p' => 'CEE 63A',
    'cee_125a_5p' => 'CEE 125A',
    'powerlock_200a' => 'Powerlock 200A',
    'powerlock_400a' => 'Powerlock 400A',
    _ => connector?.label ?? connectorTypeId,
  };
}

String _defaultOutletName({
  String? label,
  required String connectorTypeId,
  required PowerPhase phase,
  required int index,
}) {
  final base = label == null || label.trim().isEmpty
      ? _defaultConnectorName(connectorTypeId)
      : label.trim();

  if (phase == PowerPhase.all) {
    return '$base ${index + 1}';
  }

  return '$base ${_phaseLabel(phase)}.${index + 1}';
}

class _DistroCreateResult {
  const _DistroCreateResult({
    required this.name,
    required this.sourceType,
    required this.inputConnectorTypeId,
    required this.outlets,
    this.preset,
    this.locationConnectorGroupId,
  });

  final String name;
  final ProjectDistroSourceType sourceType;
  final String? inputConnectorTypeId;
  final List<PowerOutletTemplate> outlets;
  final PowerPreset? preset;
  final String? locationConnectorGroupId;
}

PowerPhase _phaseForLocationConnector(
  LocationPowerConnector connector,
  int index,
  int count,
) {
  final type = ConnectorTypes.findById(connector.connectorTypeId);
  if (type?.phaseCount == 3) {
    return PowerPhase.all;
  }
  return _phaseByGroupedIndex(index, count);
}

ProjectDistro _copyDistro(
  ProjectDistro distro, {
  String? name,
  ProjectDistroSourceType? sourceType,
  String? inputConnectorTypeId,
  bool? isRootPowerSource,
  List<ProjectOutlet>? outlets,
}) {
  return ProjectDistro(
    id: distro.id,
    phaseId: distro.phaseId,
    name: name ?? distro.name,
    sourceType: sourceType ?? distro.sourceType,
    catalogDeviceId: distro.catalogDeviceId,
    locationConnectorGroupId: distro.locationConnectorGroupId,
    presetId: distro.presetId,
    inputConnectorTypeId: inputConnectorTypeId ?? distro.inputConnectorTypeId,
    isRootPowerSource: isRootPowerSource ?? distro.isRootPowerSource,
    outlets: outlets ?? distro.outlets,
  );
}

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

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.connection,
    required this.project,
    required this.patchValidation,
    required this.onDelete,
  });

  final PowerConnection connection;
  final Project project;
  final PatchValidationResult patchValidation;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final group = project.groups
        .where((candidate) => candidate.id == connection.targetGroupId)
        .firstOrNull;
    final targetDistro = project.distros
        .where((candidate) => candidate.id == connection.targetDistroId)
        .firstOrNull;
    final distro = project.distros
        .where((candidate) => candidate.id == connection.sourceDistroId)
        .firstOrNull;
    final outlet = distro?.outlets
        .where((candidate) => candidate.id == connection.sourceOutletId)
        .firstOrNull;
    final duplicated = patchValidation.isOutletDuplicated(
      connection.sourceOutletId,
    );

    return GreenCrewCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group?.name ??
                      targetDistro?.name ??
                      'Nieznany cel polaczenia',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${distro?.name ?? 'Brak rozdzielnicy'} / ${outlet?.name ?? 'Brak gniazda'}'
                  ' -> ${connection.targetType == PowerConnectionTargetType.distro ? 'rozdzielnica' : 'grupa'}',
                ),
                if (duplicated) ...[
                  const SizedBox(height: 8),
                  const Chip(
                    avatar: Icon(Icons.link_off, size: 16),
                    label: Text('Gniazdo uzyte wiele razy'),
                  ),
                ],
                if (connection.selectedPhases.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final phase in connection.selectedPhases)
                        Chip(label: Text(_phaseLabel(phase))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Usun polaczenie',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _ConnectionDialog extends StatefulWidget {
  const _ConnectionDialog({required this.project});

  final Project project;

  @override
  State<_ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<_ConnectionDialog> {
  late PowerConnectionTargetType _targetType;
  String? _groupId;
  String? _targetDistroId;
  String? _outletKey;
  final Set<String> _selectedOutletKeys = {};
  final Set<PowerPhase> _selectedPhases = {PowerPhase.l1};
  var _allowOccupiedOutlet = false;

  @override
  void initState() {
    super.initState();
    _targetType = widget.project.groups.isNotEmpty
        ? PowerConnectionTargetType.group
        : PowerConnectionTargetType.distro;
    _groupId = widget.project.groups.firstOrNull?.id;
    _targetDistroId = _availableTargetDistros.firstOrNull?.id;
    _selectFirstAvailableOutlet();
  }

  @override
  Widget build(BuildContext context) {
    final outletOptions = _outletOptions;
    final selectedOutletOptions = _selectedOutletOptions;
    final hasOccupiedOutlet = _matchingOutletOptions.any(
      (option) => _isOutletOccupied(option.outlet.id),
    );
    final showPhaseSelector =
        _targetType == PowerConnectionTargetType.group &&
        selectedOutletOptions.any(
          (option) => option.outlet.phase == PowerPhase.all,
        );
    final canSubmit = _hasValidTarget && selectedOutletOptions.isNotEmpty;

    return AlertDialog(
      title: const Text('Polacz'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<PowerConnectionTargetType>(
              segments: const [
                ButtonSegment(
                  value: PowerConnectionTargetType.group,
                  icon: Icon(Icons.view_module_outlined),
                  label: Text('Grupa'),
                ),
                ButtonSegment(
                  value: PowerConnectionTargetType.distro,
                  icon: Icon(Icons.electrical_services),
                  label: Text('Rozdzielnica'),
                ),
              ],
              selected: {_targetType},
              onSelectionChanged: (selection) {
                setState(() {
                  _targetType = selection.single;
                  _selectFirstAvailableOutlet();
                });
              },
            ),
            const SizedBox(height: 12),
            if (_targetType == PowerConnectionTargetType.group)
              DropdownButtonFormField<String>(
                initialValue: _groupId,
                decoration: const InputDecoration(labelText: 'Grupa'),
                items: widget.project.groups
                    .map(
                      (group) => DropdownMenuItem(
                        value: group.id,
                        child: Text(group.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _groupId = value;
                      _selectFirstAvailableOutlet();
                    });
                  }
                },
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _targetDistroId,
                decoration: const InputDecoration(
                  labelText: 'Rozdzielnica podrzedna',
                ),
                items: _availableTargetDistros
                    .map(
                      (distro) => DropdownMenuItem(
                        value: distro.id,
                        child: Text(
                          '${distro.name} / wejscie ${_connectorLabel(distro.inputConnectorTypeId)}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _targetDistroId = value;
                      _selectFirstAvailableOutlet();
                    });
                  }
                },
              ),
            const SizedBox(height: 12),
            if (hasOccupiedOutlet) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _allowOccupiedOutlet,
                title: const Text('Pokaz uzyte zlacza'),
                subtitle: const Text('Pozwala nadpisac istniejace polaczenie.'),
                onChanged: (value) {
                  setState(() {
                    _allowOccupiedOutlet = value;
                    _selectFirstAvailableOutlet();
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            if (outletOptions.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Brak pasujacych wolnych gniazd.'),
              )
            else if (_targetType == PowerConnectionTargetType.group) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gniazda',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedOutletKeys
                          ..clear()
                          ..addAll(outletOptions.map((option) => option.key));
                      });
                    },
                    child: const Text('Wybierz wszystkie'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedOutletKeys.clear());
                    },
                    child: const Text('Wyczysc'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (final option in outletOptions)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _selectedOutletKeys.contains(option.key),
                  title: Text(
                    '${option.distro.name} / ${option.outlet.name} '
                    '${_phaseLabel(option.outlet.phase)}'
                    '${_isOutletOccupied(option.outlet.id) ? ' zajete' : ''}',
                  ),
                  onChanged: (selected) {
                    setState(() {
                      if (selected ?? false) {
                        _selectedOutletKeys.add(option.key);
                      } else {
                        _selectedOutletKeys.remove(option.key);
                      }
                    });
                  },
                ),
            ] else
              DropdownButtonFormField<String>(
                initialValue: _outletKey,
                decoration: const InputDecoration(labelText: 'Gniazdo'),
                items: [
                  for (final option in outletOptions)
                    DropdownMenuItem(
                      value: option.key,
                      child: Text(
                        '${option.distro.name} / ${option.outlet.name} '
                        '${_phaseLabel(option.outlet.phase)}'
                        '${_isOutletOccupied(option.outlet.id) ? ' zajete' : ''}',
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _outletKey = value);
                  }
                },
              ),
            if (showPhaseSelector) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final phase in [
                      PowerPhase.l1,
                      PowerPhase.l2,
                      PowerPhase.l3,
                    ])
                      FilterChip(
                        label: Text(_phaseLabel(phase)),
                        selected: _selectedPhases.contains(phase),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPhases.add(phase);
                            } else if (_selectedPhases.length > 1) {
                              _selectedPhases.remove(phase);
                            }
                          });
                        },
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
          onPressed: canSubmit ? _submit : null,
          child: const Text('Polacz'),
        ),
      ],
    );
  }

  bool get _hasValidTarget {
    return switch (_targetType) {
      PowerConnectionTargetType.group => _groupId != null,
      PowerConnectionTargetType.distro => _targetDistroId != null,
    };
  }

  List<ProjectDistro> get _availableTargetDistros {
    return widget.project.distros
        .where((distro) => distro.inputConnectorTypeId != null)
        .toList();
  }

  List<_OutletOption> get _outletOptions {
    final options = _matchingOutletOptions;
    if (_allowOccupiedOutlet) {
      return options;
    }
    return options
        .where((option) => !_isOutletOccupied(option.outlet.id))
        .toList();
  }

  List<_OutletOption> get _matchingOutletOptions {
    final targetDistroId = _targetDistroId;
    final targetDistro = targetDistroId == null
        ? null
        : widget.project.distros
              .where((distro) => distro.id == targetDistroId)
              .firstOrNull;
    final requiredConnectorTypeId =
        _targetType == PowerConnectionTargetType.distro
        ? targetDistro?.inputConnectorTypeId
        : null;
    final options = <_OutletOption>[];

    for (final distro in widget.project.distros) {
      if (_targetType == PowerConnectionTargetType.distro &&
          distro.id == targetDistroId) {
        continue;
      }
      for (final outlet in distro.outlets) {
        if (requiredConnectorTypeId != null &&
            outlet.connectorTypeId != requiredConnectorTypeId) {
          continue;
        }
        options.add(_OutletOption(distro: distro, outlet: outlet));
      }
    }

    return options;
  }

  void _selectFirstAvailableOutlet() {
    final options = _outletOptions;
    if (options.isEmpty) {
      _outletKey = null;
      _selectedOutletKeys.clear();
      return;
    }

    if (_targetType == PowerConnectionTargetType.group) {
      final validKeys = options.map((option) => option.key).toSet();
      _selectedOutletKeys.removeWhere((key) => !validKeys.contains(key));
      if (_selectedOutletKeys.isEmpty) {
        _selectedOutletKeys.add(options.first.key);
      }
      _outletKey = null;
      return;
    }

    _selectedOutletKeys.clear();
    if (_outletKey != null &&
        options.any((option) => option.key == _outletKey)) {
      return;
    }

    _outletKey = options.first.key;
  }

  bool _isOutletOccupied(String outletId) {
    return widget.project.connections.any(
      (connection) => connection.sourceOutletId == outletId,
    );
  }

  List<_OutletOption> get _selectedOutletOptions {
    if (_targetType == PowerConnectionTargetType.group) {
      return _outletOptions
          .where((option) => _selectedOutletKeys.contains(option.key))
          .toList();
    }

    final outletKey = _outletKey;
    if (outletKey == null) {
      return const [];
    }
    final option = _outletOptions
        .where((candidate) => candidate.key == outletKey)
        .firstOrNull;
    return option == null ? const [] : [option];
  }

  void _submit() {
    final selectedOptions = _selectedOutletOptions;
    if (selectedOptions.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _ConnectionResult(
        targetType: _targetType,
        targetGroupId: _targetType == PowerConnectionTargetType.group
            ? _groupId
            : null,
        targetDistroId: _targetType == PowerConnectionTargetType.distro
            ? _targetDistroId
            : null,
        sources: [
          for (final option in selectedOptions)
            _ConnectionSourceResult(
              sourceDistroId: option.distro.id,
              sourceOutletId: option.outlet.id,
            ),
        ],
        selectedPhases:
            _targetType == PowerConnectionTargetType.group &&
                selectedOptions.any(
                  (option) => option.outlet.phase == PowerPhase.all,
                )
            ? _selectedPhases.toList()
            : const [],
      ),
    );
  }
}

class _OutletOption {
  const _OutletOption({required this.distro, required this.outlet});

  final ProjectDistro distro;
  final ProjectOutlet outlet;

  String get key => '${distro.id}|${outlet.id}';
}

class _ConnectionResult {
  const _ConnectionResult({
    required this.targetType,
    required this.sources,
    required this.selectedPhases,
    this.targetGroupId,
    this.targetDistroId,
  });

  final PowerConnectionTargetType targetType;
  final String? targetGroupId;
  final String? targetDistroId;
  final List<_ConnectionSourceResult> sources;
  final List<PowerPhase> selectedPhases;
}

class _ConnectionSourceResult {
  const _ConnectionSourceResult({
    required this.sourceDistroId,
    required this.sourceOutletId,
  });

  final String sourceDistroId;
  final String sourceOutletId;
}

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
                      child: Text('Brak wynikow.'),
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
                      labelText: 'Ilosc',
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
                            label: 'Prad',
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
      CatalogDeviceCategory.device => 'Urzadzenie',
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

String _connectorLabel(String? connectorTypeId) {
  if (connectorTypeId == null) {
    return 'Bez wejscia';
  }

  return ConnectorTypes.all
          .where((type) => type.id == connectorTypeId)
          .firstOrNull
          ?.label ??
      connectorTypeId;
}

bool _isThreePhaseConnector(String connectorTypeId) {
  return ConnectorTypes.findById(connectorTypeId)?.phaseCount == 3;
}

PowerPhase _phaseByGroupedIndex(int index, int count) {
  final normalizedCount = count <= 0 ? 1 : count;
  final phaseBlockSize = (normalizedCount / 3).ceil();
  final phaseSlot = index ~/ phaseBlockSize;
  if (phaseSlot <= 0) {
    return PowerPhase.l1;
  }
  if (phaseSlot == 1) {
    return PowerPhase.l2;
  }
  return PowerPhase.l3;
}

bool _isSinglePhaseConnector(String? connectorTypeId) {
  if (connectorTypeId == null) {
    return false;
  }
  return ConnectorTypes.findById(connectorTypeId)?.phaseCount == 1;
}

PowerPhase _normalizedOutletPhase({
  required String connectorTypeId,
  required PowerPhase phase,
  required String? inputConnectorTypeId,
}) {
  if (_isThreePhaseConnector(connectorTypeId)) {
    return PowerPhase.all;
  }
  if (_isSinglePhaseConnector(inputConnectorTypeId) ||
      phase == PowerPhase.all) {
    return PowerPhase.l1;
  }
  return phase;
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

String _phaseLabel(PowerPhase phase) {
  return switch (phase) {
    PowerPhase.l1 => 'L1',
    PowerPhase.l2 => 'L2',
    PowerPhase.l3 => 'L3',
    PowerPhase.all => 'All',
  };
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      avatar: const Icon(Icons.bolt, size: 16),
    );
  }
}
