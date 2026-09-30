import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../infrastructure/remote/pocketbase_client_provider.dart';
import '../../../../infrastructure/remote/pocketbase_project_sharing_service.dart';

/// Dialog for the project owner to manage sharing (ADR-040): add/remove
/// team members as viewer or editor, and create/revoke account-less guest
/// read-only links. Talks to PocketBase directly, not through the local
/// offline-first repositories - sharing only makes sense once the project
/// has synced at least once and only the owner opens this (both already
/// checked by the caller).
class ShareProjectDialog extends StatefulWidget {
  const ShareProjectDialog({
    super.key,
    required this.projectName,
    required this.remoteProjectId,
  });

  final String projectName;
  final String remoteProjectId;

  @override
  State<ShareProjectDialog> createState() => _ShareProjectDialogState();
}

class _ShareProjectDialogState extends State<ShareProjectDialog> {
  late final _service = PocketBaseProjectSharingService(
    PocketBaseClientProvider.instance,
  );

  List<RecordModel> _teammates = const [];
  List<ProjectShareEntry> _shares = const [];
  var _isLoading = true;
  String? _error;

  String? _pickedTeammateId;
  var _addAsEditor = false;
  final _guestLabelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _guestLabelController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final teammates = await _service.listTeammates();
      final shares = await _service.listShares(widget.remoteProjectId);
      if (!mounted) {
        return;
      }
      setState(() {
        _teammates = teammates;
        _shares = shares;
        _isLoading = false;
        final sharedIds = shares.map((share) => share.userId).toSet();
        _pickedTeammateId = teammates
            .map((record) => record.id)
            .firstWhere(
              (id) => !sharedIds.contains(id),
              orElse: () => teammates.firstOrNull?.id ?? '',
            );
        if (_pickedTeammateId?.isEmpty ?? true) {
          _pickedTeammateId = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Nie udało się wczytać udostępnień: $error';
      });
    }
  }

  Future<void> _addMember() async {
    final userId = _pickedTeammateId;
    if (userId == null) {
      return;
    }
    await _service.addMember(
      remoteProjectId: widget.remoteProjectId,
      userId: userId,
      asEditor: _addAsEditor,
    );
    await _load();
  }

  Future<void> _removeMember(String userId) async {
    await _service.removeMember(
      remoteProjectId: widget.remoteProjectId,
      userId: userId,
    );
    await _load();
  }

  Future<void> _createGuestLink() async {
    final label = _guestLabelController.text.trim();
    final url = await _service.createGuestLink(
      remoteProjectId: widget.remoteProjectId,
      label: label.isEmpty ? null : label,
    );
    _guestLabelController.clear();
    await _load();
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Link skopiowany do schowka: $url')),
    );
  }

  Future<void> _deleteGuestLink(String linkId) async {
    await _service.deleteGuestLink(linkId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final memberShares = _shares.where((share) => !share.isGuestLink).toList();
    final guestLinks = _shares.where((share) => share.isGuestLink).toList();
    final alreadySharedIds = memberShares.map((share) => share.userId).toSet();
    final pickableTeammates = _teammates
        .where((record) => !alreadySharedIds.contains(record.id))
        .toList();

    return AlertDialog(
      title: Text('Udostępnij: ${widget.projectName}'),
      content: SizedBox(
        width: 480,
        child: _isLoading
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
            ? Text(_error!)
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Osoby z kontem',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (memberShares.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Nikomu jeszcze nie udostępniono.'),
                      ),
                    for (final share in memberShares)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(share.email ?? share.userId ?? ''),
                        subtitle: Text(share.isEditor ? 'Edytor' : 'Widz'),
                        trailing: IconButton(
                          tooltip: 'Usuń dostęp',
                          icon: const Icon(Icons.close),
                          onPressed: () => _removeMember(share.userId!),
                        ),
                      ),
                    const Divider(),
                    Text(
                      'Dodaj osobę',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (pickableTeammates.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Brak innych kont do wyboru albo wszystkie już mają dostęp.',
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _pickedTeammateId,
                              items: [
                                for (final record in pickableTeammates)
                                  DropdownMenuItem(
                                    value: record.id,
                                    child: Text(
                                      record.getStringValue('email'),
                                    ),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _pickedTeammateId = value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text('Widz')),
                              ButtonSegment(
                                value: true,
                                label: Text('Edytor'),
                              ),
                            ],
                            selected: {_addAsEditor},
                            onSelectionChanged: (selection) => setState(
                              () => _addAsEditor = selection.first,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Dodaj',
                            icon: const Icon(Icons.person_add_outlined),
                            onPressed: _pickedTeammateId == null
                                ? null
                                : _addMember,
                          ),
                        ],
                      ),
                    const Divider(),
                    Text(
                      'Linki dla gości (tylko podgląd)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final link in guestLinks)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(link.label ?? 'Link bez etykiety'),
                        subtitle: const Text('Każdy z linkiem może podglądać'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Kopiuj link',
                              icon: const Icon(Icons.copy),
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(
                                    text:
                                        'https://stagecalc.greencrew.pl/shared/${link.token}',
                                  ),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Link skopiowany'),
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Usuń link',
                              icon: const Icon(Icons.close),
                              onPressed: () => _deleteGuestLink(link.linkId!),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _guestLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Etykieta linku (opcjonalnie)',
                              hintText: 'np. adres e-mail osoby',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Utwórz nowy link',
                          icon: const Icon(Icons.add_link),
                          onPressed: _createGuestLink,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
