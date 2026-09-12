// Proof-of-connection script for ADR-017: pushes the local demo project to
// PocketBase and prints the resulting remote project id.
//
// Run with: dart run tool/push_demo_project.dart
import 'package:pocketbase/pocketbase.dart';
import 'package:stagecalc/features/projects/data/demo_project_factory.dart';
import 'package:stagecalc/features/projects/data/pocketbase_project_sync_service.dart';

Future<void> main() async {
  final pb = PocketBase('http://192.168.0.113');
  final service = PocketBaseProjectSyncService(pb);

  final project = DemoProjectFactory.createDemoProject();
  final remoteId = await service.pushProject(project);

  // ignore: avoid_print
  print('Pushed project "${project.name}" -> PocketBase record $remoteId');
}
