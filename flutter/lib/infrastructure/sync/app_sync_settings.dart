/// The user's sync preferences, the app's own record of when it last
/// synced, and the persisted PocketBase login session (ADR-026, ADR-028) -
/// all backed by the same single `AppSettings` row, so they live in one
/// class: every write to that row must include every column, or
/// `insertOnConflictUpdate` resets the columns it doesn't mention back to
/// their defaults on conflict (see `DriftAppSyncSettingsRepository`).
class AppSyncSettings {
  const AppSyncSettings({
    required this.autoSyncEnabled,
    this.lastSyncedAt,
    this.authSessionData,
  });

  final bool autoSyncEnabled;
  final DateTime? lastSyncedAt;

  /// Raw JSON blob `package:pocketbase`'s `AsyncAuthStore` persists (token +
  /// logged-in user record) - see `PocketBaseClientProvider`. `null` means
  /// nobody has ever logged in on this device.
  final String? authSessionData;

  static const AppSyncSettings initial = AppSyncSettings(
    autoSyncEnabled: false,
  );

  AppSyncSettings copyWith({bool? autoSyncEnabled, DateTime? lastSyncedAt}) {
    return AppSyncSettings(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      authSessionData: authSessionData,
    );
  }

  /// Returns a copy with the persisted auth session replaced - unlike
  /// [copyWith], this can actually clear it (pass `null` to log out), since
  /// `copyWith`'s `??` merge can never set a field back to null.
  AppSyncSettings withAuthSessionData(String? authSessionData) {
    return AppSyncSettings(
      autoSyncEnabled: autoSyncEnabled,
      lastSyncedAt: lastSyncedAt,
      authSessionData: authSessionData,
    );
  }
}
