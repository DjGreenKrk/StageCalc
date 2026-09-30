import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../shared/widgets/greencrew_card.dart';

/// Account-less, read-only view of a project shared via a guest link
/// (ADR-040). Fetches the flat JSON from the dedicated
/// `pb_hooks/guest_project_share.pb.js` endpoint directly - no PocketBase
/// SDK, no login, no local database. Deliberately a simplified summary
/// (raw `publicExport()` field names, no live power/phase-load
/// recalculation) rather than a read-only clone of the full interactive
/// editor - good enough to read the state of a project, not to work on it.
class GuestProjectViewScreen extends StatefulWidget {
  const GuestProjectViewScreen({super.key, required this.token});

  final String token;

  @override
  State<GuestProjectViewScreen> createState() =>
      _GuestProjectViewScreenState();
}

class _GuestProjectViewScreenState extends State<GuestProjectViewScreen> {
  Map<String, Object?>? _data;
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://stagecalc.greencrew.pl/api/stagecalc/shared/${widget.token}',
        ),
      );
      if (!mounted) {
        return;
      }
      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'Link nieprawidłowy albo został odwołany.';
        });
        return;
      }
      setState(() {
        _data = jsonDecode(response.body) as Map<String, Object?>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Nie udało się wczytać projektu: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final project = data?['project'] as Map<String, Object?>?;

    return Scaffold(
      appBar: AppBar(title: Text(project?['name'] as String? ?? 'StageCalc')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
          : _buildContent(data!),
    );
  }

  Widget _buildContent(Map<String, Object?> data) {
    final client = data['client'] as Map<String, Object?>?;
    final groups = (data['groups'] as List?)?.cast<Map<String, Object?>>() ?? const [];
    final items = (data['items'] as List?)?.cast<Map<String, Object?>>() ?? const [];
    final distros = (data['distros'] as List?)?.cast<Map<String, Object?>>() ?? const [];
    final outlets = (data['outlets'] as List?)?.cast<Map<String, Object?>>() ?? const [];
    final trusses = (data['trusses'] as List?)?.cast<Map<String, Object?>>() ?? const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Tylko podgląd (link gościnny) - obciążenia faz i rozdzielnic '
            'dostępne tylko w pełnym edytorze StageCalc.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        if (client != null)
          GreenCrewCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.badge_outlined),
              title: Text(client['name'] as String? ?? ''),
              subtitle: Text(client['contact_person'] as String? ?? ''),
            ),
          ),
        const SizedBox(height: 16),
        Text('Grupy', style: Theme.of(context).textTheme.titleMedium),
        for (final group in groups)
          GreenCrewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['name'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final item in items.where((i) => i['group'] == group['id']))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${item['quantity']}x ${item['name_snapshot'] ?? ''} - '
                      '${item['power_w_snapshot'] ?? 0} W / '
                      '${item['current_a_snapshot'] ?? 0} A / '
                      '${item['weight_kg_snapshot'] ?? 0} kg',
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text('Rozdzielnice', style: Theme.of(context).textTheme.titleMedium),
        for (final distro in distros)
          GreenCrewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  distro['name'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final outlet in outlets.where((o) => o['distro'] == distro['id']))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${outlet['name']} - faza ${outlet['phase']}, '
                      'max ${outlet['max_current_a']} A',
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text('Kratownice', style: Theme.of(context).textTheme.titleMedium),
        for (final truss in trusses)
          GreenCrewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  truss['name'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${truss['length_m']} m - limit '
                  '${truss['max_total_load_kg'] ?? '-'} kg / '
                  '${truss['max_distributed_load_kg_per_m'] ?? '-'} kg/m',
                ),
              ],
            ),
          ),
      ],
    );
  }
}
