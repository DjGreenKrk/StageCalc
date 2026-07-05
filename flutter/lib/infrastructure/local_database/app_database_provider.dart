import 'app_database.dart';

class AppDatabaseProvider {
  const AppDatabaseProvider._();

  static AppDatabase instance = AppDatabase();

  static void overrideForTesting(AppDatabase database) {
    instance = database;
  }
}
