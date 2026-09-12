import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> writeLocalFile({
  required String subfolder,
  required String fileName,
  required String content,
}) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final targetDir = Directory(
    p.join(documentsDir.path, 'StageCalc', subfolder),
  );

  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final file = File(p.join(targetDir.path, fileName));
  await file.writeAsString(content);
  return file.path;
}
