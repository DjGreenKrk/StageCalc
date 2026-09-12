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
