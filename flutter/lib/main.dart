import 'package:flutter/material.dart';

import 'app/app.dart';
import 'infrastructure/remote/pocketbase_client_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Restoring the PocketBase session touches the local database and, on
    // some Android devices, spawning Drift's background isolate can be slow
    // or fail outright - this must never be able to stop the app from
    // launching at all (ADR-028: local work is unaffected by sync/login
    // state). A broken/slow restore just falls back to the default,
    // unauthenticated client; sync will ask the user to log in again.
    await PocketBaseClientProvider.initialize().timeout(
      const Duration(seconds: 5),
    );
  } catch (_) {
    // Deliberately swallowed - see above.
  }
  runApp(const StageCalcApp());
}
