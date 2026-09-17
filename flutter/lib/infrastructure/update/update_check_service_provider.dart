import 'update_check_service.dart';

/// Same override-for-testing pattern as `AppDatabaseProvider` - lets widget
/// tests substitute a service backed by a fake `http.Client` instead of the
/// real one, so `flutter test` never makes a genuine network call. StageCalc
/// is offline-first end to end (ADR-002): that discipline has to hold for
/// how the app is verified too, not just for what happens to a real user
/// without a connection.
class UpdateCheckServiceProvider {
  const UpdateCheckServiceProvider._();

  static UpdateCheckService instance = UpdateCheckService();

  static void overrideForTesting(UpdateCheckService service) {
    instance = service;
  }
}
