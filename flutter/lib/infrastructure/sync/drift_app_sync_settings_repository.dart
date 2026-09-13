import 'package:drift/drift.dart';

import '../local_database/app_database.dart' as db;
import 'app_sync_settings.dart';

/// Reads/writes the single [AppSyncSettings] row (`id = 'app'`).
///
/// Every write reads the current row first and writes the full merged row
/// back - `insertOnConflictUpdate` with a partial companion would otherwise
/// reset the columns it doesn't mention to their defaults on conflict
/// (SQLite's `excluded.col` reflects the attempted insert, not the existing
/// row), which would silently wipe out whichever field wasn't being changed.
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

  Future<void> _writeRow(AppSyncSettings settings) {
    return _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          db.AppSettingsCompanion(
            id: const Value(_rowId),
            autoSyncEnabled: Value(settings.autoSyncEnabled),
            lastSyncedAt: Value(settings.lastSyncedAt),
          ),
        );
  }
}
