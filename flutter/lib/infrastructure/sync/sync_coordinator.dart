import 'package:pocketbase/pocketbase.dart';

import '../../features/catalog/data/pocketbase_catalog_sync_service.dart';
import '../../features/clients/data/pocketbase_client_sync_service.dart';
import '../../features/locations/data/pocketbase_location_sync_service.dart';
import '../../features/power_presets/data/pocketbase_power_preset_sync_service.dart';
import '../../features/projects/data/pocketbase_project_sync_service.dart';
import '../local_database/app_database.dart' as db;
import 'drift_app_sync_settings_repository.dart';
import 'sync_summary.dart';

/// Runs every collection's two-way sync (ADR-026) in one call and records
/// when it last ran. Order matters a little: clients/locations/power
/// presets/catalog devices go first so that by the time projects sync,
/// their `client`/`location` relations can already be resolved to a remote
/// record (see `PocketBaseProjectSyncService._findRemoteId`).
class SyncCoordinator {
  const SyncCoordinator(this._pb, this._database);

  final PocketBase _pb;
  final db.AppDatabase _database;

  Future<SyncSummary> syncAll() async {
    final summary =
        await PocketBaseClientSyncService(_pb, _database).sync() +
        await PocketBaseLocationSyncService(_pb, _database).sync() +
        await PocketBasePowerPresetSyncService(_pb, _database).sync() +
        await PocketBaseCatalogSyncService(_pb, _database).sync() +
        await PocketBaseProjectSyncService(_pb, _database).sync();

    await DriftAppSyncSettingsRepository(
      _database,
    ).setLastSyncedAt(DateTime.now());

    return summary;
  }
}
