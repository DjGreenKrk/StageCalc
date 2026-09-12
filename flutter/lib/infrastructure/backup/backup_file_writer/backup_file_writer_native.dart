import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> writeBackupFile(String fileName, String content) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final backupDir = Directory(
    p.join(documentsDir.path, 'StageCalc', 'backups'),
  );

  if (!await backupDir.exists()) {
    await backupDir.create(recursive: true);
  }

  final file = File(p.join(backupDir.path, fileName));
  await file.writeAsString(content);
  return file.path;
}
