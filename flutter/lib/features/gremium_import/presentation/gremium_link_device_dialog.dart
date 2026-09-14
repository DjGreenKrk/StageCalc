import 'package:flutter/material.dart';

import '../../catalog/domain/entities/catalog_device.dart';

/// Lightweight search dialog for the "Połącz z istniejącym" action in the
/// Gremium import review panel (ADR-034) - lets the user pick a device
/// already in their catalog instead of letting the import create a
/// duplicate. Deliberately a separate, smaller dialog rather than reusing
/// `_CatalogSelectionDialog` (which is private to the project editor and
/// also collects a quantity, which this flow does not need).
class GremiumLinkDeviceDialog extends StatefulWidget {
  const GremiumLinkDeviceDialog({required this.devices, super.key});

  final List<CatalogDevice> devices;

  @override
  State<GremiumLinkDeviceDialog> createState() =>
      _GremiumLinkDeviceDialogState();
}

class _GremiumLinkDeviceDialogState extends State<GremiumLinkDeviceDialog> {
  final _searchController = TextEditingController();

  List<CatalogDevice> get _filteredDevices {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.devices;
    }
    return widget.devices.where((device) {
      final manufacturer = device.manufacturer ?? '';
      return device.name.toLowerCase().contains(query) ||
          manufacturer.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDevices = _filteredDevices;

    return AlertDialog(
      title: const Text('Połącz z istniejącym urządzeniem'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Szukaj w katalogu',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (widget.devices.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Katalog jest pusty.'),
              )
            else if (filteredDevices.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Brak wyników.'),
              )
            else
              SizedBox(
                height: 260,
                child: ListView.separated(
                  itemCount: filteredDevices.length,
                  separatorBuilder: (context, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = filteredDevices[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(device.name),
                      subtitle: device.manufacturer == null
                          ? null
                          : Text(device.manufacturer!),
                      onTap: () => Navigator.of(context).pop(device),
                    );
                  },
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
      ],
    );
  }
}
