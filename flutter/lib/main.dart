import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app/app.dart';
import 'infrastructure/remote/pocketbase_client_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter's own build-time license collector only picks up LICENSE files
  // bundled inside pub.dev packages - it does not know about fonts added by
  // hand as plain assets, so both bundled fonts need an explicit entry here
  // to actually show up on the "Licencje komponentów zewnętrznych" screen
  // (verified: neither appears in the auto-generated NOTICES otherwise).
  LicenseRegistry.addLicense(() async* {
    final roboto = await rootBundle.loadString('assets/fonts/Roboto-OFL.txt');
    yield LicenseEntryWithLineBreaks(['Roboto'], roboto);
    final materialIcons = await rootBundle.loadString(
      'assets/fonts/MaterialIcons-LICENSE.txt',
    );
    yield LicenseEntryWithLineBreaks(['MaterialIcons'], materialIcons);
  });

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
