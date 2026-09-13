import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;
import 'package:stagecalc/infrastructure/sync/sync_coordinator.dart';

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('refuses to sync when nobody is logged in, without making any network '
      'calls (ADR-028)', () async {
    // A PocketBase pointed at an address nothing is listening on: if
    // syncAll() tried to reach the network before checking auth, this
    // would hang/throw instead of returning cleanly.
    final pb = PocketBase('http://127.0.0.1:1');

    final summary = await SyncCoordinator(pb, database).syncAll();

    expect(summary.pushed, 0);
    expect(summary.pulled, 0);
    expect(summary.hasErrors, isTrue);
    expect(summary.errors.single, contains('Zaloguj'));
  });
}
