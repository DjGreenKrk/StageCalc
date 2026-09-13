import 'package:flutter/material.dart';

import 'app/app.dart';
import 'infrastructure/remote/pocketbase_client_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PocketBaseClientProvider.initialize();
  runApp(const StageCalcApp());
}
