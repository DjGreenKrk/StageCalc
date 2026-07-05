import 'package:flutter/material.dart';

import '../../../infrastructure/local_database/app_database_provider.dart';
import '../../../shared/models/offline_sync_status.dart';
import '../../../shared/widgets/greencrew_card.dart';
import '../../../shared/widgets/greencrew_empty_state.dart';
import '../../../shared/widgets/greencrew_fab.dart';
import '../../../shared/widgets/greencrew_search_bar.dart';
import '../../../shared/widgets/greencrew_section_header.dart';
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
          (location.contactName ?? '').toLowerCase().contains(query);
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
        contactName: result.contactName,
        contactPhone: result.contactPhone,
        contactEmail: result.contactEmail,
        notes: result.notes,
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
    required this.onEdit,
    required this.onDelete,
  });

  final Location location;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final address = location.address;
    final contact = location.contactName;
    final phone = location.contactPhone;

    return GreenCrewCard(
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
          if (contact != null && contact.isNotEmpty) Text(contact),
          if (phone != null && phone.isNotEmpty) Text(phone),
          if (location.capacity != null)
            Text('Pojemnosc: ${location.capacity}'),
        ],
      ),
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
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final location = widget.location;
    _nameController = TextEditingController(text: location?.name ?? '');
    _addressController = TextEditingController(text: location?.address ?? '');
    _capacityController = TextEditingController(
      text: location?.capacity?.toString() ?? '',
    );
    _contactNameController = TextEditingController(
      text: location?.contactName ?? '',
    );
    _contactPhoneController = TextEditingController(
      text: location?.contactPhone ?? '',
    );
    _contactEmailController = TextEditingController(
      text: location?.contactEmail ?? '',
    );
    _notesController = TextEditingController(text: location?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
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
            _field(_nameController, 'Nazwa', autofocus: true),
            _field(_addressController, 'Adres'),
            _field(_capacityController, 'Pojemnosc'),
            _field(_contactNameController, 'Kontakt techniczny'),
            _field(_contactPhoneController, 'Telefon'),
            _field(_contactEmailController, 'Email'),
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
      _LocationFormResult(
        name: name,
        address: _emptyToNull(_addressController.text),
        capacity: int.tryParse(_capacityController.text.trim()),
        contactName: _emptyToNull(_contactNameController.text),
        contactPhone: _emptyToNull(_contactPhoneController.text),
        contactEmail: _emptyToNull(_contactEmailController.text),
        notes: _emptyToNull(_notesController.text),
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
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.notes,
  });

  final String name;
  final String? address;
  final int? capacity;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? notes;
}
