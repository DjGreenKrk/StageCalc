// Proof-of-connection script for the bidirectional PocketBase sync (ADR-026):
// seeds an in-memory local database with demo data, syncs it against the
// real PocketBase server, then runs the sync a second time to check it is
// idempotent (a second run should report only "unchanged" records, no new
// pushes/pulls and no errors). Replaces the ADR-017 one-way
// `push_demo_project.dart`.
//
// This is not part of the normal `flutter test` run (it lives in `tool/`,
// outside the `test/` directory `flutter test` scans by default, and talks
// to a real server) - run it explicitly with:
//   flutter test tool/sync_demo_data.dart
//
// `flutter test` rather than `dart run` because every sync service touches
// `AppDatabase`, whose native connection (ADR-016) imports `path_provider`,
// which transitively imports `package:flutter` - a plain Dart VM (`dart
// run`) cannot compile that, only the Flutter-aware test/app runners can.
//
// Since ADR-028, every collection requires a logged-in PocketBase user, so
// this needs an existing account's credentials passed via environment
// variables (never hardcode real credentials here):
//   SYNC_DEMO_EMAIL=crew@example.com SYNC_DEMO_PASSWORD=secret \
//     flutter test tool/sync_demo_data.dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:stagecalc/features/catalog/data/demo_catalog_factory.dart';
import 'package:stagecalc/features/catalog/data/drift_catalog_repository.dart';
import 'package:stagecalc/features/catalog/data/pocketbase_catalog_sync_service.dart';
import 'package:stagecalc/features/clients/domain/entities/client.dart';
import 'package:stagecalc/features/clients/data/drift_client_repository.dart';
import 'package:stagecalc/features/clients/data/pocketbase_client_sync_service.dart';
import 'package:stagecalc/features/locations/domain/entities/location.dart';
import 'package:stagecalc/features/locations/data/drift_location_repository.dart';
import 'package:stagecalc/features/locations/data/pocketbase_location_sync_service.dart';
import 'package:stagecalc/features/power_presets/data/demo_power_preset_factory.dart';
import 'package:stagecalc/features/power_presets/data/drift_power_preset_repository.dart';
import 'package:stagecalc/features/power_presets/data/pocketbase_power_preset_sync_service.dart';
import 'package:stagecalc/features/projects/data/demo_project_factory.dart';
import 'package:stagecalc/features/projects/data/drift_project_repository.dart';
import 'package:stagecalc/features/projects/data/pocketbase_project_sync_service.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;
import 'package:stagecalc/infrastructure/sync/sync_summary.dart';

Future<void> _login(PocketBase pb) async {
  final email = Platform.environment['SYNC_DEMO_EMAIL'];
  final password = Platform.environment['SYNC_DEMO_PASSWORD'];
  if (email == null || password == null) {
    throw StateError(
      'Set SYNC_DEMO_EMAIL and SYNC_DEMO_PASSWORD to an existing '
      'PocketBase user account before running this tool (ADR-028: every '
      'collection now requires a logged-in user).',
    );
  }
  await pb.collection('users').authWithPassword(email, password);
}

void main() {
  test('syncs demo data against the real PocketBase server', () async {
    final pb = PocketBase('http://192.168.0.113');
    await _login(pb);
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());

    final catalogRepository = DriftCatalogRepository(database);
    await catalogRepository.ensureSeedData();
    await catalogRepository.saveDevice(
      DemoCatalogFactory.createSeedDevices().first,
    );

    final now = DateTime.now();
    await DriftClientRepository(database).saveClient(
      Client(
        id: 'sync_demo_client',
        name: 'GreenCrew Demo Sp. z o.o.',
        email: 'kontakt@example.com',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await DriftLocationRepository(database).saveLocation(
      Location(
        id: 'sync_demo_location',
        name: 'Hala Demo',
        address: 'ul. Testowa 1',
        createdAt: now,
        updatedAt: now,
        powerConnectors: const [],
        contacts: const [],
      ),
    );

    final powerPresetRepository = DriftPowerPresetRepository(database);
    for (final preset in DemoPowerPresetFactory.createSeedPresets()) {
      await powerPresetRepository.savePreset(preset);
    }

    await DriftProjectRepository(
      database,
    ).saveProject(DemoProjectFactory.createDemoProject());

    final services = <String, Future<SyncSummary> Function()>{
      'clients': () => PocketBaseClientSyncService(pb, database).sync(),
      'locations': () => PocketBaseLocationSyncService(pb, database).sync(),
      'power_presets': () =>
          PocketBasePowerPresetSyncService(pb, database).sync(),
      'catalog_devices': () =>
          PocketBaseCatalogSyncService(pb, database).sync(),
      'projects': () => PocketBaseProjectSyncService(pb, database).sync(),
    };

    for (var pass = 1; pass <= 2; pass++) {
      // ignore: avoid_print
      print('--- pass $pass ---');
      for (final entry in services.entries) {
        final summary = await entry.value();
        // ignore: avoid_print
        print('${entry.key}: $summary');
        for (final error in summary.errors) {
          // ignore: avoid_print
          print('  ! $error');
        }
        if (pass == 2) {
          expect(
            summary.hasErrors,
            isFalse,
            reason: '${entry.key} sync reported errors: ${summary.errors}',
          );
        }
      }
    }

    await database.close();
  });

  test('pulls existing remote data into a brand new local database', () async {
    final pb = PocketBase('http://192.168.0.113');
    await _login(pb);
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());

    final services = <String, Future<SyncSummary> Function()>{
      'clients': () => PocketBaseClientSyncService(pb, database).sync(),
      'locations': () => PocketBaseLocationSyncService(pb, database).sync(),
      'power_presets': () =>
          PocketBasePowerPresetSyncService(pb, database).sync(),
      'catalog_devices': () =>
          PocketBaseCatalogSyncService(pb, database).sync(),
      'projects': () => PocketBaseProjectSyncService(pb, database).sync(),
    };

    for (final entry in services.entries) {
      final summary = await entry.value();
      // ignore: avoid_print
      print('pull ${entry.key}: $summary');
      expect(
        summary.hasErrors,
        isFalse,
        reason: '${entry.key} pull reported errors: ${summary.errors}',
      );
      expect(
        summary.pulled,
        greaterThan(0),
        reason:
            '${entry.key} pulled nothing - run the push test at least once '
            'first so the server actually has data to pull.',
      );
    }

    final client = (await DriftClientRepository(
      database,
    ).getClients()).singleWhere((c) => c.id == 'sync_demo_client');
    expect(client.name, 'GreenCrew Demo Sp. z o.o.');

    final project = (await DriftProjectRepository(
      database,
    ).getProjects()).singleWhere((p) => p.id == 'demo_project');
    expect(project.groups, isNotEmpty);
    expect(
      project.groups.first.items,
      isNotEmpty,
      reason:
          'pulled project is missing its items - group->item pull path '
          'is broken',
    );

    await database.close();
  });
}
