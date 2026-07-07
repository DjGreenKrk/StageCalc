import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../infrastructure/local_database/app_database_provider.dart';
import '../../../shared/models/offline_sync_status.dart';
import '../../../shared/widgets/greencrew_card.dart';
import '../../../shared/widgets/greencrew_empty_state.dart';
import '../../../shared/widgets/greencrew_fab.dart';
import '../../../shared/widgets/greencrew_search_bar.dart';
import '../../../shared/widgets/greencrew_section_header.dart';
import '../../projects/domain/entities/power_models.dart';
import '../data/drift_location_repository.dart';
import '../data/location_repository.dart';
import '../domain/entities/location.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  LocationRepository? _repository;
  List<Location> _locations = const [];
  var _query = '';
  var _isLoading = true;
  String? _error;

  List<Location> get _filteredLocations {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _locations;
    }

    return _locations.where((location) {
      return location.name.toLowerCase().contains(query) ||
          (location.address ?? '').toLowerCase().contains(query) ||
          location.effectiveContacts.any(
            (contact) =>
                contact.name.toLowerCase().contains(query) ||
                contact.role.toLowerCase().contains(query),
          );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = DriftLocationRepository(AppDatabaseProvider.instance);
      final locations = await repository.getLocations();

      if (!mounted) {
        return;
      }

      setState(() {
        _repository = repository;
        _locations = locations;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Nie udalo sie wczytac lokacji. Dane lokalne pozostaly bez zmian.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locations = _filteredLocations;

    return Scaffold(
      floatingActionButton: GreenCrewFab(
        label: 'Dodaj lokacje',
        icon: Icons.add,
        onPressed: _isLoading ? null : () => _openLocationDialog(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GreenCrewSectionHeader(title: 'Lokacje'),
          const SizedBox(height: 12),
          GreenCrewSearchBar(
            hintText: 'Szukaj lokacji',
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
                onAction: _loadLocations,
              ),
            )
          else if (locations.isEmpty)
            GreenCrewCard(
              child: GreenCrewEmptyState(
                icon: Icons.location_city_outlined,
                title: 'Brak lokacji',
                message: _query.isEmpty
                    ? 'Dodaj obiekt, aby zapisac jego przylacza i kontakty techniczne.'
                    : 'Zmien zapytanie albo dodaj nowa lokacje.',
                actionLabel: 'Dodaj lokacje',
                onAction: () => _openLocationDialog(),
              ),
            )
          else
            for (final location in locations) ...[
              _LocationCard(
                location: location,
                onOpen: () => _openLocationDetails(location),
                onEdit: () => _openLocationDialog(location: location),
                onDelete: () => _deleteLocation(location),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Future<void> _openLocationDialog({Location? location}) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final result = await showDialog<_LocationFormResult>(
      context: context,
      builder: (context) => _LocationDialog(location: location),
    );

    if (result == null) {
      return;
    }

    final now = DateTime.now();
    await repository.saveLocation(
      Location(
        id: location?.id ?? 'location_${now.microsecondsSinceEpoch}',
        name: result.name,
        address: result.address,
        capacity: result.capacity,
        contactName: result.contacts.firstOrNull?.name,
        contactPhone: result.contacts.firstOrNull?.phone,
        contactEmail: result.contacts.firstOrNull?.email,
        notes: result.notes,
        contacts: result.contacts,
        powerConnectors: result.powerConnectors,
        createdAt: location?.createdAt ?? now,
        updatedAt: now,
        syncStatus: location?.syncStatus ?? OfflineSyncStatus.localOnly,
      ),
    );

    final locations = await repository.getLocations();
    if (!mounted) {
      return;
    }

    setState(() => _locations = locations);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lokacja zapisana lokalnie')));
  }

  Future<void> _openLocationDetails(Location location) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _LocationDetailsScreen(location: location),
      ),
    );
  }

  Future<void> _deleteLocation(Location location) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunac lokacje?'),
        content: Text('"${location.name}" zostanie usunieta lokalnie.'),
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

    await repository.deleteLocation(location.id);
    final locations = await repository.getLocations();

    if (!mounted) {
      return;
    }

    setState(() => _locations = locations);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lokacja usunieta lokalnie')));
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Location location;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final address = location.address;
    final primaryContact = location.effectiveContacts.firstOrNull;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(8),
      child: GreenCrewCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    location.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Edytuj lokacje',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Usun lokacje',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (address != null && address.isNotEmpty) Text(address),
            if (primaryContact != null)
              Text('${primaryContact.role}: ${primaryContact.name}'),
            if ((primaryContact?.phone ?? '').isNotEmpty)
              Text(primaryContact!.phone!),
            if (location.capacity != null)
              Text('Pojemnosc: ${location.capacity}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.electrical_services, size: 16),
                  label: Text(
                    'Moc obiektu ${location.totalAvailablePowerKw.toStringAsFixed(1)} kW',
                  ),
                ),
                for (final connector in location.powerConnectors)
                  Chip(
                    label: Text(
                      '${connector.name}: ${connector.quantity}x '
                      '${_connectorLabel(connector.connectorTypeId)}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationDetailsScreen extends StatelessWidget {
  const _LocationDetailsScreen({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final address = location.address?.trim();
    final notes = location.notes?.trim();
    final contacts = location.effectiveContacts;

    return Scaffold(
      appBar: AppBar(title: Text(location.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailSection(
            title: 'Obiekt',
            icon: Icons.location_city_outlined,
            children: [
              _DetailRow(label: 'Nazwa', value: location.name),
              if (address != null && address.isNotEmpty)
                _DetailRow(
                  label: 'Adres',
                  value: address,
                  actions: [
                    TextButton.icon(
                      onPressed: () => _openMap(context, address),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Mapa'),
                    ),
                  ],
                ),
              if (location.capacity != null)
                _DetailRow(label: 'Pojemnosc', value: '${location.capacity}'),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Kontakty',
            icon: Icons.contact_phone_outlined,
            children: [
              if (contacts.isEmpty)
                const Text('Brak kontaktow.')
              else
                for (final contact in contacts)
                  _DetailRow(
                    label: contact.role,
                    value: contact.name,
                    actions: [
                      if ((contact.phone ?? '').trim().isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _launchExternalUri(
                            context,
                            Uri(scheme: 'tel', path: contact.phone!.trim()),
                          ),
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Zadzwon'),
                        ),
                      if ((contact.email ?? '').trim().isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _launchExternalUri(
                            context,
                            Uri(scheme: 'mailto', path: contact.email!.trim()),
                          ),
                          icon: const Icon(Icons.mail_outline),
                          label: const Text('Email'),
                        ),
                    ],
                  ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Zasilanie',
            icon: Icons.electrical_services,
            children: [
              _DetailRow(
                label: 'Moc obiektu',
                value:
                    '${location.totalAvailablePowerKw.toStringAsFixed(1)} kW',
              ),
              if (location.powerConnectors.isEmpty)
                const Text('Brak grup zlaczy.')
              else
                for (final connector in location.powerConnectors)
                  _DetailRow(
                    label: connector.name,
                    value:
                        '${connector.quantity}x ${_connectorLabel(connector.connectorTypeId)} / '
                        '${connector.availablePowerKw.toStringAsFixed(1)} kW',
                  ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Notatki',
              icon: Icons.notes_outlined,
              children: [Text(notes)],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GreenCrewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.actions = const [],
  });

  final String label;
  final String value;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(spacing: 8, runSpacing: 4, children: actions),
          ],
        ],
      ),
    );
  }
}

Future<void> _openMap(BuildContext context, String address) {
  return _launchExternalUri(
    context,
    Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    }),
  );
}

Future<void> _launchExternalUri(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
  if (!launched) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nie udalo sie otworzyc linku.')),
    );
  }
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({this.location});

  final Location? location;

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _capacityController;
  late final TextEditingController _notesController;
  late List<LocationPowerConnector> _powerConnectors;
  late List<LocationContact> _contacts;

  @override
  void initState() {
    super.initState();
    final location = widget.location;
    _nameController = TextEditingController(text: location?.name ?? '');
    _addressController = TextEditingController(text: location?.address ?? '');
    _capacityController = TextEditingController(
      text: location?.capacity?.toString() ?? '',
    );
    _notesController = TextEditingController(text: location?.notes ?? '');
    _powerConnectors = [...location?.powerConnectors ?? const []];
    _contacts = [...location?.effectiveContacts ?? const []];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.location == null ? 'Dodaj lokacje' : 'Edytuj lokacje'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _formSection(
              context,
              title: 'Dane obiektu',
              children: [
                _field(_nameController, 'Nazwa', autofocus: true),
                _field(_addressController, 'Adres'),
                _field(_capacityController, 'Pojemnosc'),
              ],
            ),
            _formSection(
              context,
              title: 'Kontakty',
              trailing: TextButton.icon(
                onPressed: _addContact,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj kontakt'),
              ),
              children: [
                if (_contacts.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Brak kontaktow.'),
                  )
                else
                  for (final contact in _contacts)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${contact.role}: ${contact.name}'),
                      subtitle: Text(
                        [
                          if ((contact.phone ?? '').isNotEmpty) contact.phone!,
                          if ((contact.email ?? '').isNotEmpty) contact.email!,
                        ].join(' / '),
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Edytuj kontakt',
                            onPressed: () => _editContact(contact),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Usun kontakt',
                            onPressed: () {
                              setState(() {
                                _contacts = _contacts
                                    .where(
                                      (candidate) => candidate.id != contact.id,
                                    )
                                    .toList();
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
            _formSection(
              context,
              title: 'Grupy zlaczy',
              trailing: TextButton.icon(
                onPressed: _addPowerConnector,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj grupe'),
              ),
              children: [
                if (_powerConnectors.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Brak grup zlaczy.'),
                  )
                else
                  for (final connector in _powerConnectors)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(connector.name),
                      subtitle: Text(
                        '${connector.quantity}x ${_connectorLabel(connector.connectorTypeId)} / '
                        '${connector.availablePowerKw.toStringAsFixed(1)} kW',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Edytuj grupe zlaczy',
                            onPressed: () => _editPowerConnector(connector),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Usun grupe zlaczy',
                            onPressed: () {
                              setState(() {
                                _powerConnectors = _powerConnectors
                                    .where(
                                      (candidate) =>
                                          candidate.id != connector.id,
                                    )
                                    .toList();
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
            _formSection(
              context,
              title: 'Notatki',
              children: [_field(_notesController, 'Notatki', maxLines: 3)],
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

  Widget _formSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
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
      _LocationFormResult(
        name: name,
        address: _emptyToNull(_addressController.text),
        capacity: int.tryParse(_capacityController.text.trim()),
        notes: _emptyToNull(_notesController.text),
        contacts: _contacts,
        powerConnectors: _powerConnectors,
      ),
    );
  }

  Future<void> _addContact() async {
    final now = DateTime.now();
    final result = await showDialog<LocationContact>(
      context: context,
      builder: (context) => _LocationContactDialog(
        contact: LocationContact(
          id: 'location_contact_${now.microsecondsSinceEpoch}',
          role: 'Techniczny',
          name: '',
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() => _contacts = [..._contacts, result]);
  }

  Future<void> _editContact(LocationContact contact) async {
    final result = await showDialog<LocationContact>(
      context: context,
      builder: (context) => _LocationContactDialog(contact: contact),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _contacts = _contacts
          .map((candidate) => candidate.id == result.id ? result : candidate)
          .toList();
    });
  }

  Future<void> _addPowerConnector() async {
    final now = DateTime.now();
    final result = await showDialog<LocationPowerConnector>(
      context: context,
      builder: (context) => _PowerConnectorDialog(
        connector: LocationPowerConnector(
          id: 'location_connector_${now.microsecondsSinceEpoch}',
          name: 'Grupa zlaczy ${_powerConnectors.length + 1}',
          connectorTypeId: 'cee_32a_5p',
          quantity: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() => _powerConnectors = [..._powerConnectors, result]);
  }

  Future<void> _editPowerConnector(LocationPowerConnector connector) async {
    final result = await showDialog<LocationPowerConnector>(
      context: context,
      builder: (context) => _PowerConnectorDialog(connector: connector),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _powerConnectors = _powerConnectors
          .map((candidate) => candidate.id == result.id ? result : candidate)
          .toList();
    });
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _PowerConnectorDialog extends StatefulWidget {
  const _PowerConnectorDialog({required this.connector});

  final LocationPowerConnector connector;

  @override
  State<_PowerConnectorDialog> createState() => _PowerConnectorDialogState();
}

class _PowerConnectorDialogState extends State<_PowerConnectorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  late String _connectorTypeId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.connector.name);
    _quantityController = TextEditingController(
      text: widget.connector.quantity.toString(),
    );
    _notesController = TextEditingController(
      text: widget.connector.notes ?? '',
    );
    _connectorTypeId = widget.connector.connectorTypeId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grupa zlaczy'),
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
                  setState(() => _connectorTypeId = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ilosc'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notatki'),
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
      LocationPowerConnector(
        id: widget.connector.id,
        name: name,
        connectorTypeId: _connectorTypeId,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        notes: _emptyToNull(_notesController.text),
        createdAt: widget.connector.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _LocationContactDialog extends StatefulWidget {
  const _LocationContactDialog({required this.contact});

  final LocationContact contact;

  @override
  State<_LocationContactDialog> createState() => _LocationContactDialogState();
}

class _LocationContactDialogState extends State<_LocationContactDialog> {
  late final TextEditingController _roleController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _roleController = TextEditingController(text: widget.contact.role);
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneController = TextEditingController(text: widget.contact.phone ?? '');
    _emailController = TextEditingController(text: widget.contact.email ?? '');
    _notesController = TextEditingController(text: widget.contact.notes ?? '');
  }

  @override
  void dispose() {
    _roleController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kontakt lokacji'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _roleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Rola'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Imie i nazwisko'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notatki'),
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
    final role = _roleController.text.trim();
    final name = _nameController.text.trim();
    if (role.isEmpty || name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      LocationContact(
        id: widget.contact.id,
        role: role,
        name: name,
        phone: _emptyToNull(_phoneController.text),
        email: _emptyToNull(_emailController.text),
        notes: _emptyToNull(_notesController.text),
        createdAt: widget.contact.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _LocationFormResult {
  const _LocationFormResult({
    required this.name,
    this.address,
    this.capacity,
    this.notes,
    this.contacts = const [],
    this.powerConnectors = const [],
  });

  final String name;
  final String? address;
  final int? capacity;
  final String? notes;
  final List<LocationContact> contacts;
  final List<LocationPowerConnector> powerConnectors;
}

String _connectorLabel(String connectorTypeId) {
  return ConnectorTypes.findById(connectorTypeId)?.label ?? connectorTypeId;
}
