// Buduje i pakuje artefakty release zgodnie z ADR-012F: `StageCalc-vX_Y_Z-platform.ext`.
// Wersja jest czytana z pubspec.yaml (`version: X.Y.Z+build`), numer builda nie
// trafia do nazwy pliku - tylko X.Y.Z, tak jak w przykladach ADR-012F.
//
// Uzycie:
//   dart run tool/package_release.dart              (Android + Windows)
//   dart run tool/package_release.dart --platform=android
//   dart run tool/package_release.dart --platform=windows
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final platform = _argValue(arguments, '--platform') ?? 'all';
  if (!['all', 'android', 'windows'].contains(platform)) {
    stderr.writeln(
      'Nieznana platforma: $platform (oczekiwano all/android/windows)',
    );
    exitCode = 1;
    return;
  }

  final version = _readPubspecVersion(File('pubspec.yaml').readAsStringSync());
  final distDir = Directory('dist')..createSync(recursive: true);

  // ignore: avoid_print
  print('Pakowanie StageCalc v$version (platforma: $platform)');

  if (platform == 'all' || platform == 'android') {
    await _packageAndroid(version, distDir);
  }
  if (platform == 'all' || platform == 'windows') {
    await _packageWindows(version, distDir);
  }
}

Future<void> _packageAndroid(String version, Directory distDir) async {
  await _run('flutter', ['build', 'apk', '--release']);

  final builtApk = File('build/app/outputs/flutter-apk/app-release.apk');
  if (!builtApk.existsSync()) {
    throw StateError('Nie znaleziono ${builtApk.path} po `flutter build apk`.');
  }

  final target = File('${distDir.path}/StageCalc-v$version-android.apk');
  builtApk.copySync(target.path);
  // ignore: avoid_print
  print('Android: ${target.path}');
}

Future<void> _packageWindows(String version, Directory distDir) async {
  await _run('flutter', ['build', 'windows', '--release']);

  final releaseDir = Directory('build/windows/x64/runner/Release');
  if (!releaseDir.existsSync()) {
    throw StateError(
      'Nie znaleziono ${releaseDir.path} po `flutter build windows`.',
    );
  }

  final targetZip = File('${distDir.path}/StageCalc-v$version-windows.zip');
  if (targetZip.existsSync()) {
    targetZip.deleteSync();
  }

  // `Compress-Archive` zamiast dodawania zaleznosci `archive` tylko dla tego skryptu -
  // pakowanie Windows i tak dziala jedynie na maszynie z Windows (kompilacja .exe).
  await _run('powershell', [
    '-NoProfile',
    '-Command',
    "Compress-Archive -Path '${releaseDir.path}\\*' -DestinationPath '${targetZip.path}'",
  ]);
  // ignore: avoid_print
  print('Windows: ${targetZip.path}');
}

Future<void> _run(String executable, List<String> args) async {
  // ignore: avoid_print
  print('> $executable ${args.join(' ')}');
  final result = await Process.run(executable, args, runInShell: true);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      args,
      'Zakonczylo sie kodem ${result.exitCode}',
    );
  }
}

String _readPubspecVersion(String pubspecContent) {
  final match = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)\+\d+\s*$',
    multiLine: true,
  ).firstMatch(pubspecContent);
  if (match == null) {
    throw FormatException(
      'Nie znaleziono pola `version: X.Y.Z+build` w pubspec.yaml.',
    );
  }
  return match.group(1)!.replaceAll('.', '_');
}

String? _argValue(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith('$prefix=')) {
      return arg.substring(prefix.length + 1);
    }
  }
  return null;
}
