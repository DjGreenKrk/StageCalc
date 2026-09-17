import 'package:drift/drift.dart';

import '../local_database/app_database.dart' as db;
import 'app_sync_settings.dart';

/// Reads/writes the single [AppSyncSettings] row (`id = 'app'`).
///
/// Every write reads the current row first, applies one change to the whole
/// in-memory [AppSyncSettings], and writes it back in full (correction:
/// Drift's `insertOnConflictUpdate` already leaves columns absent from the
/// companion untouched on conflict, so this isn't working around that as an
/// earlier version of this comment claimed - it's just simpler to reason
/// about a single "read the whole row, change one thing, write the whole
/// row back" path than to track which column each setter is allowed to
/// touch, especially once [AppSyncSettings.copyWith]'s `??` merge is in the
/// picture: passing an explicit `null` through it is indistinguishable from
/// not passing anything, which is exactly why [withAuthSessionData] exists
/// as a separate, non-defaulting path for clearing a field).
class DriftAppSyncSettingsRepository {
  const DriftAppSyncSettingsRepository(this._database);

  final db.AppDatabase _database;

  static const _rowId = 'app';

  Future<AppSyncSettings> getSettings() async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((row) => row.id.equals(_rowId))).getSingleOrNull();

    if (row == null) {
      return AppSyncSettings.initial;
    }

    return AppSyncSettings(
      autoSyncEnabled: row.autoSyncEnabled,
      lastSyncedAt: row.lastSyncedAt,
      authSessionData: row.authSessionData,
      dismissedUpdateVersion: row.dismissedUpdateVersion,
    );
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    final current = await getSettings();
    await _writeRow(current.copyWith(autoSyncEnabled: enabled));
  }

  Future<void> setLastSyncedAt(DateTime value) async {
    final current = await getSettings();
    await _writeRow(current.copyWith(lastSyncedAt: value));
  }

  Future<void> setAuthSessionData(String? data) async {
    final current = await getSettings();
    await _writeRow(current.withAuthSessionData(data));
  }

  Future<void> setDismissedUpdateVersion(String? version) async {
    final current = await getSettings();
    await _writeRow(current.withDismissedUpdateVersion(version));
  }

  Future<void> _writeRow(AppSyncSettings settings) {
    return _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          db.AppSettingsCompanion(
            id: const Value(_rowId),
            autoSyncEnabled: Value(settings.autoSyncEnabled),
            lastSyncedAt: Value(settings.lastSyncedAt),
            authSessionData: Value(settings.authSessionData),
            dismissedUpdateVersion: Value(settings.dismissedUpdateVersion),
          ),
        );
  }
}
