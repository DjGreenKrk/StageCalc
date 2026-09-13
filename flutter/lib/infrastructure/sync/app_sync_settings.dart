/// The user's sync preferences and the app's own record of when it last
/// synced - see ADR-026.
class AppSyncSettings {
  const AppSyncSettings({required this.autoSyncEnabled, this.lastSyncedAt});

  final bool autoSyncEnabled;
  final DateTime? lastSyncedAt;

  static const AppSyncSettings initial = AppSyncSettings(
    autoSyncEnabled: false,
  );

  AppSyncSettings copyWith({bool? autoSyncEnabled, DateTime? lastSyncedAt}) {
    return AppSyncSettings(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
