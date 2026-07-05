import 'package:flutter/material.dart';

import '../../../../shared/widgets/greencrew_card.dart';
import '../../../../shared/widgets/greencrew_empty_state.dart';
import '../../../../shared/widgets/greencrew_fab.dart';
import '../../../../shared/widgets/greencrew_search_bar.dart';
import '../../../../shared/widgets/greencrew_section_header.dart';
import '../../../../infrastructure/local_database/app_database_provider.dart';
import '../../../clients/data/drift_client_repository.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../locations/data/drift_location_repository.dart';
import '../../../locations/domain/entities/location.dart';
import '../../data/demo_project_factory.dart';
import '../../data/drift_project_repository.dart';
import '../../data/project_repository.dart';
import '../../domain/entities/project_models.dart';
import '../../domain/services/project_totals_service.dart';
import '../project_editor_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  ProjectRepository? _repository;
  List<Project> _projects = const [];
  List<Client> _clients = const [];
  List<Location> _locations = const [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = DriftProjectRepository(AppDatabaseProvider.instance);
      final clients = await DriftClientRepository(
        AppDatabaseProvider.instance,
      ).getClients();
      final locations = await DriftLocationRepository(
        AppDatabaseProvider.instance,
      ).getLocations();
      var projects = await repository.getProjects();

      if (projects.isEmpty) {
        final demo = DemoProjectFactory.createDemoProject();
        await repository.saveProject(demo);
        projects = [demo];
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _repository = repository;
        _projects = projects;
        _clients = clients;
        _locations = locations;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Nie udalo sie wczytac projektow. Dane lokalne pozostaly bez zmian.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: GreenCrewFab(
        label: 'Dodaj projekt',
        icon: Icons.add,
        onPressed: _isLoading ? null : _openCreateProjectDialog,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GreenCrewSectionHeader(title: 'Projekty'),
          const SizedBox(height: 12),
          const GreenCrewSearchBar(hintText: 'Szukaj projektu'),
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
                onAction: _loadProjects,
              ),
            )
          else if (_projects.isEmpty)
            const SizedBox(
              height: 360,
              child: GreenCrewEmptyState(
                icon: Icons.dashboard_outlined,
                title: 'Brak projektow',
                message: 'Dodaj pierwszy projekt, aby rozpoczac kalkulacje.',
                actionLabel: 'Dodaj projekt',
              ),
            )
          else
            for (final project in _projects) ...[
              _ProjectCard(
                project: project,
                clients: _clients,
                locations: _locations,
                onTap: () => _openProject(project),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Future<void> _openCreateProjectDialog() async {
    final result = await showDialog<_CreateProjectResult>(
      context: context,
      builder: (context) =>
          _CreateProjectDialog(clients: _clients, locations: _locations),
    );

    final trimmedName = result?.name.trim();
    if (trimmedName == null || trimmedName.isEmpty) {
      return;
    }

    await _addProject(
      trimmedName,
      clientId: result?.clientId,
      locationId: result?.locationId,
    );
  }

  Future<void> _addProject(
    String name, {
    String? clientId,
    String? locationId,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final now = DateTime.now();
    final project = Project(
      id: 'project_${now.microsecondsSinceEpoch}',
      name: name,
      clientId: clientId,
      locationId: locationId,
      groups: const [],
      createdAt: now,
      updatedAt: now,
    );

    await repository.saveProject(project);
    final projects = await repository.getProjects();

    if (!mounted) {
      return;
    }

    setState(() => _projects = projects);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Projekt zapisany lokalnie')));
  }

  Future<void> _openProject(Project project) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) {
          return ProjectEditorScreen(project: project, repository: repository);
        },
      ),
    );

    if (changed == true) {
      await _loadProjects();
    }
  }
}

class _CreateProjectDialog extends StatefulWidget {
  const _CreateProjectDialog({required this.clients, required this.locations});

  final List<Client> clients;
  final List<Location> locations;

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _controller = TextEditingController(text: 'Nowy projekt');
  String? _clientId;
  String? _locationId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj projekt'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nazwa projektu'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
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
    Navigator.of(context).pop(
      _CreateProjectResult(
        name: _controller.text,
        clientId: _clientId,
        locationId: _locationId,
      ),
    );
  }
}

class _CreateProjectResult {
  const _CreateProjectResult({
    required this.name,
    required this.clientId,
    required this.locationId,
  });

  final String name;
  final String? clientId;
  final String? locationId;
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.clients,
    required this.locations,
    required this.onTap,
  });

  final Project project;
  final List<Client> clients;
  final List<Location> locations;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const totalsService = ProjectTotalsService();
    final totals = totalsService.calculate(project);
    final textTheme = Theme.of(context).textTheme;
    final clientName = clients
        .where((client) => client.id == project.clientId)
        .firstOrNull
        ?.name;
    final locationName = locations
        .where((location) => location.id == project.locationId)
        .firstOrNull
        ?.name;

    return GreenCrewCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(project.name, style: textTheme.titleMedium)),
              const Icon(Icons.chevron_right),
            ],
          ),
          if (clientName != null || locationName != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (clientName != null)
                  Chip(
                    avatar: const Icon(Icons.badge_outlined, size: 16),
                    label: Text(clientName),
                  ),
                if (locationName != null)
                  Chip(
                    avatar: const Icon(Icons.location_city_outlined, size: 16),
                    label: Text(locationName),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }
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
