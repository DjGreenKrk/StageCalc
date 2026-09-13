import 'package:pocketbase/pocketbase.dart';

import '../local_database/app_database_provider.dart';
import '../sync/drift_app_sync_settings_repository.dart';

/// Temporary hardcoded LAN address of the StageCalc PocketBase instance
/// (LXC 113, `stagecalc`). Not yet configurable from the UI - a real
/// settings/backend-URL screen would replace this.
///
/// The client's [PocketBase.authStore] persists across app restarts
/// (ADR-028) via `package:pocketbase`'s own `AsyncAuthStore`, backed by the
/// local `AppSettings` row - so [initialize] must run once, and complete,
/// before anything reads [instance] and expects a restored login session
/// (both `main()` and `flutter test` setup already do this).
class PocketBaseClientProvider {
  const PocketBaseClientProvider._();

  static PocketBase instance = PocketBase('http://192.168.0.113');

  static Future<void> initialize() async {
    final database = AppDatabaseProvider.instance;
    final settingsRepository = DriftAppSyncSettingsRepository(database);
    final settings = await settingsRepository.getSettings();

    instance = PocketBase(
      'http://192.168.0.113',
      authStore: AsyncAuthStore(
        initial: settings.authSessionData,
        save: (data) => settingsRepository.setAuthSessionData(data),
        clear: () => settingsRepository.setAuthSessionData(null),
      ),
    );
  }
}
