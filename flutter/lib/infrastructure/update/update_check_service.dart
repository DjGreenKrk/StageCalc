import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_metadata.dart';

/// A release on GitHub newer than [AppMetadata.version].
class AvailableUpdate {
  const AvailableUpdate({required this.version, required this.releaseUrl});

  /// `"0.7.0"` - no leading `v`, no build-number suffix.
  final String version;

  /// The release's page on GitHub (`html_url`), to open with `url_launcher`.
  final String releaseUrl;
}

/// Checks GitHub Releases for a version newer than the one currently
/// running, entirely silently: any failure (no network, GitHub down,
/// unexpected response shape) resolves to `null` rather than throwing,
/// matching the same "background check that never bothers the user on
/// failure" philosophy as the auto-sync check in `app.dart`.
///
/// Deliberately reads `GET /repos/{slug}/releases/latest`, which GitHub
/// defines as the latest release that is **not** a prerelease - as long as
/// releases cut from the `beta` branch are published with `--prerelease`,
/// this means the check only ever offers a genuinely stable upgrade,
/// without needing any release-channel logic here.
class UpdateCheckService {
  UpdateCheckService([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AvailableUpdate?> checkForUpdate() async {
    try {
      final response = await _client.get(
        Uri.https(
          'api.github.com',
          '/repos/${AppMetadata.repositorySlug}/releases/latest',
        ),
        headers: const {'Accept': 'application/vnd.github+json'},
      );
      if (response.statusCode != 200) {
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return null;
      }

      final tagName = body['tag_name'];
      final releaseUrl = body['html_url'];
      if (tagName is! String || releaseUrl is! String) {
        return null;
      }

      if (!isNewer(tagName, AppMetadata.version)) {
        return null;
      }

      return AvailableUpdate(
        version: _stripTag(tagName),
        releaseUrl: releaseUrl,
      );
    } catch (_) {
      return null;
    }
  }

  /// Whether [latestTag] (e.g. `"v0.7.0+1"`) is a newer `X.Y.Z` than
  /// [currentVersion] (e.g. `"0.6.0"`). Only compares the three numeric
  /// parts - build numbers in this project have never meaningfully
  /// incremented release over release, so they're not worth tracking here.
  /// Returns `false` (never throws) for anything that doesn't parse as
  /// `X.Y.Z`, so a malformed or unexpected tag is silently ignored rather
  /// than mistaken for an update.
  static bool isNewer(String latestTag, String currentVersion) {
    final latest = _parseVersion(_stripTag(latestTag));
    final current = _parseVersion(currentVersion);
    if (latest == null || current == null) {
      return false;
    }

    for (var i = 0; i < 3; i++) {
      if (latest[i] != current[i]) {
        return latest[i] > current[i];
      }
    }
    return false;
  }

  static String _stripTag(String tag) {
    final withoutV = tag.startsWith('v') ? tag.substring(1) : tag;
    final plusIndex = withoutV.indexOf('+');
    return plusIndex == -1 ? withoutV : withoutV.substring(0, plusIndex);
  }

  static List<int>? _parseVersion(String version) {
    final parts = version.split('.');
    if (parts.length != 3) {
      return null;
    }
    final numbers = <int>[];
    for (final part in parts) {
      final number = int.tryParse(part);
      if (number == null) {
        return null;
      }
      numbers.add(number);
    }
    return numbers;
  }
}
