import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stagecalc/core/constants/app_metadata.dart';
import 'package:stagecalc/infrastructure/update/update_check_service.dart';

void main() {
  group('isNewer', () {
    test('detects a newer patch/minor/major version', () {
      expect(UpdateCheckService.isNewer('v0.6.1', '0.6.0'), isTrue);
      expect(UpdateCheckService.isNewer('v0.7.0', '0.6.0'), isTrue);
      expect(UpdateCheckService.isNewer('v1.0.0', '0.6.0'), isTrue);
    });

    test('returns false for the same version', () {
      expect(UpdateCheckService.isNewer('v0.6.0', '0.6.0'), isFalse);
    });

    test('returns false for an older version', () {
      expect(UpdateCheckService.isNewer('v0.5.0', '0.6.0'), isFalse);
    });

    test('ignores the build-number suffix on the tag', () {
      expect(UpdateCheckService.isNewer('v0.6.0+1', '0.6.0'), isFalse);
      expect(UpdateCheckService.isNewer('v0.7.0+1', '0.6.0'), isTrue);
    });

    test('returns false instead of throwing for a malformed tag', () {
      expect(UpdateCheckService.isNewer('not-a-version', '0.6.0'), isFalse);
      expect(UpdateCheckService.isNewer('v1.2', '0.6.0'), isFalse);
      expect(UpdateCheckService.isNewer('v1.2.x', '0.6.0'), isFalse);
    });
  });

  group('checkForUpdate', () {
    test('returns an AvailableUpdate when the release API reports a newer '
        'tag', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.github.com/repos/${AppMetadata.repositorySlug}/releases/latest',
        );
        return http.Response(
          '{"tag_name": "v99.0.0+1", "html_url": "https://github.com/example/release"}',
          200,
        );
      });

      final result = await UpdateCheckService(client).checkForUpdate();

      expect(result, isNotNull);
      expect(result!.version, '99.0.0');
      expect(result.releaseUrl, 'https://github.com/example/release');
    });

    test('returns null when the latest release is not newer', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"tag_name": "v0.0.1+1", "html_url": "https://github.com/example/release"}',
          200,
        );
      });

      final result = await UpdateCheckService(client).checkForUpdate();

      expect(result, isNull);
    });

    test('returns null on a non-200 response instead of throwing', () async {
      final client = MockClient((request) async {
        return http.Response('not found', 404);
      });

      final result = await UpdateCheckService(client).checkForUpdate();

      expect(result, isNull);
    });

    test('returns null on malformed JSON instead of throwing', () async {
      final client = MockClient((request) async {
        return http.Response('not json', 200);
      });

      final result = await UpdateCheckService(client).checkForUpdate();

      expect(result, isNull);
    });

    test('returns null when the response is missing expected fields', () async {
      final client = MockClient((request) async {
        return http.Response('{"unexpected": true}', 200);
      });

      final result = await UpdateCheckService(client).checkForUpdate();

      expect(result, isNull);
    });

    test('returns null when the underlying client throws', () async {
      final client = MockClient((request) async {
        throw Exception('no network');
      });

      final result = await UpdateCheckService(client).checkForUpdate();

      expect(result, isNull);
    });
  });
}
