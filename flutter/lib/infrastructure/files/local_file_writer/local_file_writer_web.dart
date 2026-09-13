import 'dart:typed_data';

Future<String> writeLocalFile({
  required String subfolder,
  required String fileName,
  required String content,
}) async {
  throw UnsupportedError(
    'Zapis pliku nie jest jeszcze wspierany w wersji web. '
    'Uzyj aplikacji na Windows lub Android.',
  );
}

Future<String> writeLocalBytesFile({
  required String subfolder,
  required String fileName,
  required Uint8List bytes,
}) async {
  throw UnsupportedError(
    'Zapis pliku nie jest jeszcze wspierany w wersji web. '
    'Uzyj aplikacji na Windows lub Android.',
  );
}
