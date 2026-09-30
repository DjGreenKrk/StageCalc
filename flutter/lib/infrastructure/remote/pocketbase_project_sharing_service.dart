import 'dart:convert';
import 'dart:math';

import 'package:pocketbase/pocketbase.dart';

/// One row of who a project is shared with - either a team member (`user`
/// set, `email` their account email) or a guest link (`user` null, `email`
/// null, `token`/`label` set instead). See ADR-040.
class ProjectShareEntry {
  const ProjectShareEntry.member({
    required this.userId,
    required this.email,
    required this.isEditor,
  }) : linkId = null,
       token = null,
       label = null;

  const ProjectShareEntry.guestLink({
    required this.linkId,
    required this.token,
    this.label,
  }) : userId = null,
       email = null,
       isEditor = false;

  final String? userId;
  final String? email;
  final bool isEditor;

  final String? linkId;
  final String? token;
  final String? label;

  bool get isGuestLink => linkId != null;
}

/// Manages project sharing (ADR-040): team members as viewer/editor via the
/// `sharedViewers`/`sharedEditors` relation fields on `projects`, and
/// account-less guest read-only links via the `project_guest_links`
/// collection. Talks to PocketBase directly - sharing is inherently an
/// online concept, unlike the rest of the app's offline-first local
/// repositories.
class PocketBaseProjectSharingService {
  const PocketBaseProjectSharingService(this._pb);

  final PocketBase _pb;

  String? get currentUserId => _pb.authStore.record?.id;

  /// Every other account in the team, for the "add person" picker. Requires
  /// the `users.listRule` widened in ADR-040 - every logged-in user can see
  /// every other account's email (deliberate, scoped trade-off, see the
  /// ADR).
  Future<List<RecordModel>> listTeammates() async {
    final all = await _pb.collection('users').getFullList();
    final myId = currentUserId;
    return all.where((record) => record.id != myId).toList();
  }

  Future<List<ProjectShareEntry>> listShares(String remoteProjectId) async {
    final project = await _pb.collection('projects').getOne(remoteProjectId);
    final editorIds = _stringList(project.data['sharedEditors']);
    final viewerIds = _stringList(project.data['sharedViewers']);

    final members = <ProjectShareEntry>[];
    for (final id in editorIds) {
      final email = await _emailFor(id);
      members.add(
        ProjectShareEntry.member(userId: id, email: email, isEditor: true),
      );
    }
    for (final id in viewerIds) {
      final email = await _emailFor(id);
      members.add(
        ProjectShareEntry.member(userId: id, email: email, isEditor: false),
      );
    }

    final links = await _pb
        .collection('project_guest_links')
        .getFullList(filter: _pb.filter('project = {:id}', {'id': remoteProjectId}));
    for (final link in links) {
      members.add(
        ProjectShareEntry.guestLink(
          linkId: link.id,
          token: link.getStringValue('token'),
          label: link.data['label'] as String?,
        ),
      );
    }
    return members;
  }

  Future<void> addMember({
    required String remoteProjectId,
    required String userId,
    required bool asEditor,
  }) async {
    final project = await _pb.collection('projects').getOne(remoteProjectId);
    final editorIds = _stringList(project.data['sharedEditors']).toSet();
    final viewerIds = _stringList(project.data['sharedViewers']).toSet();

    // A person has exactly one role at a time - adding as editor drops any
    // prior viewer share for the same user, and vice versa.
    if (asEditor) {
      viewerIds.remove(userId);
      editorIds.add(userId);
    } else {
      editorIds.remove(userId);
      viewerIds.add(userId);
    }

    await _pb.collection('projects').update(
      remoteProjectId,
      body: {
        'sharedEditors': editorIds.toList(),
        'sharedViewers': viewerIds.toList(),
      },
    );
  }

  Future<void> removeMember({
    required String remoteProjectId,
    required String userId,
  }) async {
    final project = await _pb.collection('projects').getOne(remoteProjectId);
    final editorIds = _stringList(project.data['sharedEditors']).toSet()
      ..remove(userId);
    final viewerIds = _stringList(project.data['sharedViewers']).toSet()
      ..remove(userId);

    await _pb.collection('projects').update(
      remoteProjectId,
      body: {
        'sharedEditors': editorIds.toList(),
        'sharedViewers': viewerIds.toList(),
      },
    );
  }

  /// Creates a new guest read-only link and returns the full, shareable
  /// URL (pointing at the web app's guest viewer route). The token is
  /// generated here, client-side - never derived from [label] or any
  /// email, so it stays a bearer secret even if [label] is just someone's
  /// address written down for the owner's own reference.
  Future<String> createGuestLink({
    required String remoteProjectId,
    String? label,
  }) async {
    final token = _generateToken();
    await _pb.collection('project_guest_links').create(
      body: {
        'project': remoteProjectId,
        'label': label,
        'token': token,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
    return 'https://stagecalc.greencrew.pl/shared/$token';
  }

  Future<void> deleteGuestLink(String linkId) {
    return _pb.collection('project_guest_links').delete(linkId);
  }

  Future<String> _emailFor(String userId) async {
    try {
      final record = await _pb.collection('users').getOne(userId);
      return record.getStringValue('email');
    } catch (_) {
      return userId;
    }
  }

  List<String> _stringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
