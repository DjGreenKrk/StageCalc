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
import '../../../gremium_import/presentation/gremium_import_entry.dart';
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
      final projects = await repository.getProjects();

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
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Nie udało się wczytać projektów. Dane lokalne pozostały bez zmian.\n$error';
        _isLoading = false;
      });
    }
  }

  /// See `ClientsScreen._ensureRepository` - same reasoning: without this,
  /// a [_repository] that is still null (failed or not-yet-finished
  /// [_loadProjects]) let "Dodaj projekt" open a dialog that then silently
  /// failed to save on submit, with no feedback at all.
  Future<ProjectRepository?> _ensureRepository() async {
    if (_repository != null) {
      return _repository;
    }

    await _loadProjects();
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
    return Scaffold(
      floatingActionButton: GreenCrewFab(
        label: 'Dodaj projekt',
        icon: Icons.add,
        onPressed: _isLoading ? null : _openCreateProjectDialog,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GreenCrewSectionHeader(
            title: 'Projekty',
            action: GremiumImportButton(onImported: _loadProjects),
          ),
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
                title: 'Błąd danych',
                message: _error!,
                actionLabel: 'Spróbuj ponownie',
                onAction: _loadProjects,
              ),
            )
          else if (_projects.isEmpty)
            const SizedBox(
              height: 360,
              child: GreenCrewEmptyState(
                icon: Icons.dashboard_outlined,
                title: 'Brak projektów',
                message: 'Dodaj pierwszy projekt, aby rozpocząć kalkulacje.',
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
                onDelete: () => _deleteProject(project),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Future<void> _openCreateProjectDialog() async {
    final repository = await _ensureRepository();
    if (repository == null || !mounted) {
      return;
    }

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

  Future<void> _deleteProject(Project project) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć projekt?'),
        content: Text(
          '"${project.name}" zostanie usunięty razem ze wszystkimi grupami, '
          'rozdzielniami i kratownicami.',
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

    await repository.deleteProject(project.id);
    final projects = await repository.getProjects();

    if (!mounted) {
      return;
    }

    setState(() => _projects = projects);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Projekt usunięty lokalnie')));
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
    required this.onDelete,
  });

  final Project project;
  final List<Client> clients;
  final List<Location> locations;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
              IconButton(
                tooltip: 'Usuń projekt',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
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
                label: 'Prąd',
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
