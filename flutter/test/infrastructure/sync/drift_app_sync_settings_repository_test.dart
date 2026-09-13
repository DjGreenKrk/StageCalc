import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;
import 'package:stagecalc/infrastructure/sync/drift_app_sync_settings_repository.dart';

void main() {
  late db.AppDatabase database;
  late DriftAppSyncSettingsRepository repository;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftAppSyncSettingsRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('defaults to auto-sync disabled and no last sync time', () async {
    final settings = await repository.getSettings();

    expect(settings.autoSyncEnabled, isFalse);
    expect(settings.lastSyncedAt, isNull);
  });

  test('persists the auto-sync toggle', () async {
    await repository.setAutoSyncEnabled(true);

    expect((await repository.getSettings()).autoSyncEnabled, isTrue);
  });

  test(
    'setting the last sync time does not reset the auto-sync toggle',
    () async {
      await repository.setAutoSyncEnabled(true);
      final now = DateTime(2026, 7, 5, 12);
      await repository.setLastSyncedAt(now);

      final settings = await repository.getSettings();
      expect(settings.autoSyncEnabled, isTrue);
      expect(settings.lastSyncedAt, now);
    },
  );

  test(
    'toggling auto-sync off does not reset an already recorded sync time',
    () async {
      final now = DateTime(2026, 7, 5, 12);
      await repository.setLastSyncedAt(now);
      await repository.setAutoSyncEnabled(true);
      await repository.setAutoSyncEnabled(false);

      final settings = await repository.getSettings();
      expect(settings.autoSyncEnabled, isFalse);
      expect(settings.lastSyncedAt, now);
    },
  );

  test('persists the auth session data (ADR-028)', () async {
    await repository.setAuthSessionData('{"token":"abc"}');

    expect((await repository.getSettings()).authSessionData, '{"token":"abc"}');
  });

  test('setting the auth session does not reset sync settings', () async {
    await repository.setAutoSyncEnabled(true);
    final now = DateTime(2026, 7, 5, 12);
    await repository.setLastSyncedAt(now);

    await repository.setAuthSessionData('{"token":"abc"}');

    final settings = await repository.getSettings();
    expect(settings.autoSyncEnabled, isTrue);
    expect(settings.lastSyncedAt, now);
    expect(settings.authSessionData, '{"token":"abc"}');
  });

  test(
    'clearing the auth session (logout) does not reset sync settings',
    () async {
      await repository.setAutoSyncEnabled(true);
      await repository.setAuthSessionData('{"token":"abc"}');

      await repository.setAuthSessionData(null);

      final settings = await repository.getSettings();
      expect(settings.authSessionData, isNull);
      expect(settings.autoSyncEnabled, isTrue);
    },
  );
}
