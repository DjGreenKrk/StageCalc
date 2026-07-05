import 'package:flutter/material.dart';

import '../../../infrastructure/local_database/app_database_provider.dart';
import '../../../shared/models/offline_sync_status.dart';
import '../../../shared/widgets/greencrew_card.dart';
import '../../../shared/widgets/greencrew_empty_state.dart';
import '../../../shared/widgets/greencrew_fab.dart';
import '../../../shared/widgets/greencrew_search_bar.dart';
import '../../../shared/widgets/greencrew_section_header.dart';
import '../data/client_repository.dart';
import '../data/drift_client_repository.dart';
import '../domain/entities/client.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  ClientRepository? _repository;
  List<Client> _clients = const [];
  var _query = '';
  var _isLoading = true;
  String? _error;

  List<Client> get _filteredClients {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _clients;
    }

    return _clients.where((client) {
      return client.name.toLowerCase().contains(query) ||
          (client.contactPerson ?? '').toLowerCase().contains(query) ||
          (client.email ?? '').toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = DriftClientRepository(AppDatabaseProvider.instance);
      final clients = await repository.getClients();

      if (!mounted) {
        return;
      }

      setState(() {
        _repository = repository;
        _clients = clients;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Nie udalo sie wczytac klientow. Dane lokalne pozostaly bez zmian.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = _filteredClients;

    return Scaffold(
      floatingActionButton: GreenCrewFab(
        label: 'Dodaj klienta',
        icon: Icons.add,
        onPressed: _isLoading ? null : () => _openClientDialog(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GreenCrewSectionHeader(title: 'Klienci'),
          const SizedBox(height: 12),
          GreenCrewSearchBar(
            hintText: 'Szukaj klienta',
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
                onAction: _loadClients,
              ),
            )
          else if (clients.isEmpty)
            GreenCrewCard(
              child: GreenCrewEmptyState(
                icon: Icons.badge_outlined,
                title: 'Brak klientow',
                message: _query.isEmpty
                    ? 'Dodaj klienta, aby przypisac go do projektu.'
                    : 'Zmien zapytanie albo dodaj nowego klienta.',
                actionLabel: 'Dodaj klienta',
                onAction: () => _openClientDialog(),
              ),
            )
          else
            for (final client in clients) ...[
              _ClientCard(
                client: client,
                onEdit: () => _openClientDialog(client: client),
                onDelete: () => _deleteClient(client),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Future<void> _openClientDialog({Client? client}) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final result = await showDialog<_ClientFormResult>(
      context: context,
      builder: (context) => _ClientDialog(client: client),
    );

    if (result == null) {
      return;
    }

    final now = DateTime.now();
    await repository.saveClient(
      Client(
        id: client?.id ?? 'client_${now.microsecondsSinceEpoch}',
        name: result.name,
        contactPerson: result.contactPerson,
        email: result.email,
        phone: result.phone,
        address: result.address,
        nip: result.nip,
        notes: result.notes,
        createdAt: client?.createdAt ?? now,
        updatedAt: now,
        syncStatus: client?.syncStatus ?? OfflineSyncStatus.localOnly,
      ),
    );

    final clients = await repository.getClients();
    if (!mounted) {
      return;
    }

    setState(() => _clients = clients);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Klient zapisany lokalnie')));
  }

  Future<void> _deleteClient(Client client) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunac klienta?'),
        content: Text('"${client.name}" zostanie usuniety lokalnie.'),
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

    await repository.deleteClient(client.id);
    final clients = await repository.getClients();

    if (!mounted) {
      return;
    }

    setState(() => _clients = clients);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Klient usuniety lokalnie')));
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.onEdit,
    required this.onDelete,
  });

  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final contact = client.contactPerson;
    final phone = client.phone;
    final email = client.email;

    return GreenCrewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  client.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Edytuj klienta',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Usun klienta',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          if (contact != null && contact.isNotEmpty) Text(contact),
          if (phone != null && phone.isNotEmpty) Text(phone),
          if (email != null && email.isNotEmpty) Text(email),
        ],
      ),
    );
  }
}

class _ClientDialog extends StatefulWidget {
  const _ClientDialog({this.client});

  final Client? client;

  @override
  State<_ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends State<_ClientDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _nipController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    _nameController = TextEditingController(text: client?.name ?? '');
    _contactController = TextEditingController(
      text: client?.contactPerson ?? '',
    );
    _emailController = TextEditingController(text: client?.email ?? '');
    _phoneController = TextEditingController(text: client?.phone ?? '');
    _addressController = TextEditingController(text: client?.address ?? '');
    _nipController = TextEditingController(text: client?.nip ?? '');
    _notesController = TextEditingController(text: client?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.client == null ? 'Dodaj klienta' : 'Edytuj klienta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_nameController, 'Nazwa', autofocus: true),
            _field(_contactController, 'Osoba kontaktowa'),
            _field(_emailController, 'Email'),
            _field(_phoneController, 'Telefon'),
            _field(_addressController, 'Adres'),
            _field(_nipController, 'NIP'),
            _field(_notesController, 'Notatki', maxLines: 3),
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

  Widget _field(
    TextEditingController controller,
    String label, {
    bool autofocus = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _ClientFormResult(
        name: name,
        contactPerson: _emptyToNull(_contactController.text),
        email: _emptyToNull(_emailController.text),
        phone: _emptyToNull(_phoneController.text),
        address: _emptyToNull(_addressController.text),
        nip: _emptyToNull(_nipController.text),
        notes: _emptyToNull(_notesController.text),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _ClientFormResult {
  const _ClientFormResult({
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.nip,
    this.notes,
  });

  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? nip;
  final String? notes;
}
