import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> writeLocalFile({
  required String subfolder,
  required String fileName,
  required String content,
}) async {
  final file = await _targetFile(subfolder, fileName);
  await file.writeAsString(content);
  return file.path;
}

Future<String> writeLocalBytesFile({
  required String subfolder,
  required String fileName,
  required Uint8List bytes,
}) async {
  final file = await _targetFile(subfolder, fileName);
  await file.writeAsBytes(bytes);
  return file.path;
}

Future<File> _targetFile(String subfolder, String fileName) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final targetDir = Directory(
    p.join(documentsDir.path, 'StageCalc', subfolder),
  );

  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  return File(p.join(targetDir.path, fileName));
}
