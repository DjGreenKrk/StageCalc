enum OfflineSyncStatus { localOnly, pendingSync, synced, syncError, conflict }

extension OfflineSyncStatusJson on OfflineSyncStatus {
  String toJson() => name;

  static OfflineSyncStatus fromJson(String? value) {
    return OfflineSyncStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OfflineSyncStatus.localOnly,
    );
  }
}
