import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;

/// Regression test for a real bug hit on a user's device: `onUpgrade` tried
/// to `ADD COLUMN "rigging_points"` (the `from < 11` migration step) and
/// crashed with `SqliteException: duplicate column name: rigging_points`,
/// even though the column already physically existed in the file - the
/// tracked schema version (`PRAGMA user_version`) had somehow fallen out of
/// sync with the actual table shape. Because every screen shares this one
/// database, that single thrown exception broke every "Dodaj" action in the
/// whole app with no error shown anywhere (see `ClientsScreen` and its three
/// counterparts' `_ensureRepository`), until the exception was captured from
/// the app's own error banner and reported.
///
/// This reproduces that exact desync on a real on-disk file: create a fresh
/// database (so every table/column physically exists at the current
/// version), then roll back *only* `user_version` with a separate raw
/// connection - not the schema - before reopening through `AppDatabase`,
/// which forces `onUpgrade` to run migration steps whose columns/tables are
/// already there.
///
/// Uses `NativeDatabase.createInBackground` - the exact executor
/// `connection_native.dart` uses in the real app, not the plain, same-isolate
/// `NativeDatabase(File(...))`. That distinction matters a lot here: the
/// first version of this fix passed against the same-isolate executor but
/// still failed live, because errors crossing the background isolate used by
/// `createInBackground` get wrapped in `DriftRemoteException` - a same-isolate
/// test would never have caught that.
void main() {
  test(
    'onUpgrade tolerates a stale user_version whose columns/tables already '
    'exist, instead of crashing on "duplicate column name"/"already exists"',
    () async {
      final dir = await Directory.systemTemp.createTemp('stagecalc_migration');
      final path = p.join(dir.path, 'stagecalc.sqlite');
      addTearDown(() => dir.delete(recursive: true));

      // 1. Fresh database: onCreate() builds every table/column at the
      // current schema and Drift records user_version = schemaVersion.
      final fresh = db.AppDatabase.forTesting(
        NativeDatabase.createInBackground(File(path)),
      );
      await fresh.customStatement('SELECT 1');
      await fresh.close();

      // 2. Roll back *only* the tracked version, via a separate raw
      // connection, leaving the physical schema untouched - reproducing the
      // exact desync from the field report.
      final raw = sqlite3.sqlite3.open(path);
      raw.execute('PRAGMA user_version = 10');
      raw.close();

      // 3. Reopen through AppDatabase: this must run onUpgrade(from: 10,
      // to: 16) against a file whose columns/tables from steps 11-16
      // already exist. Before the _addColumnIfMissing/_createTableIfMissing
      // fix, this threw SqliteException on the very first such step.
      final reopened = db.AppDatabase.forTesting(
        NativeDatabase.createInBackground(File(path)),
      );
      await expectLater(reopened.customStatement('SELECT 1'), completes);

      final version = await reopened
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data.values.single, 16);

      await reopened.close();
    },
  );
}
