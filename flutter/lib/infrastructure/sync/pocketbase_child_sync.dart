import 'package:pocketbase/pocketbase.dart';

/// Upserts every child in [bodies] (each a full push payload for one child,
/// keyed by its own `local_id`) into [collection] under [remoteParentId].
///
/// Never deletes a remote record - this app soft-deletes everywhere
/// (`deletedAt`/`deleted_at` is just another field, see ADR-011/ADR-026), so
/// a child the user removed locally is still present in [bodies] with its
/// deleted flag set, exactly like every root aggregate. There is nothing to
/// reconcile as "no longer present": every child that ever existed keeps
/// being upserted, soft-deleted or not.
Future<void> upsertRemoteChildren(
  PocketBase pb, {
  required String collection,
  required String parentField,
  required String remoteParentId,
  required List<Map<String, Object?>> bodies,
}) async {
  final existing = await pb
      .collection(collection)
      .getFullList(
        filter: pb.filter('$parentField = {:id}', {'id': remoteParentId}),
      );
  final existingByLocalId = {
    for (final record in existing) record.getStringValue('local_id'): record,
  };

  for (final body in bodies) {
    final existingRecord = existingByLocalId[body['local_id']];
    if (existingRecord != null) {
      await pb.collection(collection).update(existingRecord.id, body: body);
    } else {
      await pb.collection(collection).create(body: body);
    }
  }
}
