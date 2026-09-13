/// What a single record reconciliation should do, decided purely from the
/// two sides' `updatedAt` timestamps ("last write wins" - ADR-026): whichever
/// side changed more recently overwrites the other. Neither side is treated
/// as more authoritative by default - a record that exists on only one side
/// is always copied to the other, regardless of direction.
enum SyncDirection {
  /// Copy the local record to the remote (create or overwrite there).
  push,

  /// Copy the remote record to the local database (create or overwrite it).
  pull,

  /// Both sides already agree - nothing to do.
  none,
}

/// Decides [SyncDirection] for one record from its local/remote `updatedAt`.
///
/// `null` means "does not exist on that side yet". Equal timestamps count as
/// already in sync ([SyncDirection.none]) rather than picking a side, since
/// re-pushing/re-pulling an identical timestamp cannot change anything.
SyncDirection decideSyncDirection({
  required DateTime? localUpdatedAt,
  required DateTime? remoteUpdatedAt,
}) {
  if (localUpdatedAt == null && remoteUpdatedAt == null) {
    return SyncDirection.none;
  }
  if (localUpdatedAt == null) {
    return SyncDirection.pull;
  }
  if (remoteUpdatedAt == null) {
    return SyncDirection.push;
  }
  if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
    return SyncDirection.push;
  }
  if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
    return SyncDirection.pull;
  }
  return SyncDirection.none;
}
