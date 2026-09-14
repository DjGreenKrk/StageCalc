import 'dart:io';

Future<String> readLocalTextFile(String path) async {
  final file = File(path.trim());
  if (!await file.exists()) {
    throw ArgumentError('Plik nie istnieje: $path');
  }
  return file.readAsString();
}
