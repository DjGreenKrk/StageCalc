import 'dart:io';
import 'dart:typed_data';

Future<String> readLocalTextFile(String path) async {
  final file = File(path.trim());
  if (!await file.exists()) {
    throw ArgumentError('Plik nie istnieje: $path');
  }
  return file.readAsString();
}

Future<Uint8List> readLocalBytes(String path) async {
  final file = File(path.trim());
  if (!await file.exists()) {
    throw ArgumentError('Plik nie istnieje: $path');
  }
  return file.readAsBytes();
}
