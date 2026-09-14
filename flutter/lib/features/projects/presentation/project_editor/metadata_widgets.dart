part of '../project_editor_screen.dart';

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
            'Pojemność',
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
