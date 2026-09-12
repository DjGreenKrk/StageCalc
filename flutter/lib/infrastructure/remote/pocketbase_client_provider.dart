import 'package:pocketbase/pocketbase.dart';

/// Temporary hardcoded LAN address of the StageCalc PocketBase instance
/// (LXC 113, `stagecalc`). Not yet configurable from the UI — this is the
/// first PocketBase integration (ADR-017), a real sync/settings layer would
/// replace this with a user-configurable backend URL.
class PocketBaseClientProvider {
  const PocketBaseClientProvider._();

  static PocketBase instance = PocketBase('http://192.168.0.113');
}
