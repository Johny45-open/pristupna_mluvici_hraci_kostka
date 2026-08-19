import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pristupna_mluvici_hraci_kostka/update_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  group('compareVersions', () {
    test('compares plain dotted versions', () {
      expect(compareVersions('1.7.0', '1.7.0'), 0);
      expect(compareVersions('1.7.0', '1.8.0'), lessThan(0));
      expect(compareVersions('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('ignores a leading v', () {
      expect(compareVersions('v2.0.0', '2.0.0'), 0);
      expect(compareVersions('v2.0.0', '1.9.0'), greaterThan(0));
    });

    test('treats missing trailing parts as zero', () {
      expect(compareVersions('1.7', '1.7.0'), 0);
      expect(compareVersions('1.8', '1.7.9'), greaterThan(0));
    });

    test('handles per-part suffixes', () {
      expect(compareVersions('1.8.0-rc.1', '1.8.0'), 0);
      expect(compareVersions('1.7.0+2', '1.7.0'), 0);
    });
  });

  group('GitHubUpdateService', () {
    test('parses the latest release JSON', () async {
      final client = MockClient((request) async {
        expect(request.url.path,
            '/repos/Johny45-open/pristupna_mluvici_hraci_kostka/releases/latest');
        return http.Response(
          jsonEncode({
            'tag_name': 'v2.0.0',
            'name': 'v2.0.0',
            'body': 'Novinky vydání.',
            'html_url': 'https://github.com/owner/repo/releases/tag/v2.0.0',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = GitHubUpdateService(client: client);

      final info = await service.fetchLatest();

      expect(info, isNotNull);
      expect(info!.version, '2.0.0');
      expect(info.title, 'v2.0.0');
      expect(info.notes, 'Novinky vydání.');
      expect(info.url, 'https://github.com/owner/repo/releases/tag/v2.0.0');
    });

    test('returns null when there are no releases (404)', () async {
      final service = GitHubUpdateService(
        client: MockClient((_) async => http.Response('', 404)),
      );

      expect(await service.fetchLatest(), isNull);
    });

    test('throws on other error statuses', () async {
      final service = GitHubUpdateService(
        client: MockClient((_) async => http.Response('', 500)),
      );

      expect(service.fetchLatest(), throwsA(isA<UpdateCheckException>()));
    });

    test('supports a custom repository', () async {
      final service = GitHubUpdateService(
        repo: 'someone/other',
        client: MockClient((request) async {
          expect(request.url.path, '/repos/someone/other/releases/latest');
          return http.Response('{}', 404);
        }),
      );

      expect(await service.fetchLatest(), isNull);
    });
  });

  group('UpdateController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('reports an available update when the release is newer', () async {
      final service = FakeUpdateService(
        latest: const UpdateInfo(
          version: '2.0.0',
          title: 'v2.0.0',
          notes: 'Nové funkce.',
          url: 'https://example.com/release',
        ),
      );
      final controller = makeUpdateController(
        service: service,
        currentVersion: '1.7.0',
      );

      final result = await controller.check();

      expect(result, isA<UpdateAvailable>());
      expect((result as UpdateAvailable).info.version, '2.0.0');
      expect(controller.status, UpdateStatus.updateAvailable);
    });

    test('reports up to date when the release equals the installed version',
        () async {
      final service = FakeUpdateService(
        latest: const UpdateInfo(
          version: '1.7.0',
          title: 'v1.7.0',
          notes: '',
          url: 'https://example.com/release',
        ),
      );
      final controller = makeUpdateController(service: service);

      final result = await controller.check();

      expect(result, isA<UpdateUpToDate>());
      expect(controller.status, UpdateStatus.upToDate);
    });

    test('reports up to date when the release is older', () async {
      final service = FakeUpdateService(
        latest: const UpdateInfo(
          version: '1.6.0',
          title: 'v1.6.0',
          notes: '',
          url: 'https://example.com/release',
        ),
      );
      final controller = makeUpdateController(service: service);

      final result = await controller.check();

      expect(result, isA<UpdateUpToDate>());
    });

    test('reports failure when the service throws', () async {
      final controller = makeUpdateController(
        service: FakeUpdateService(error: StateError('boom')),
      );

      final result = await controller.check();

      expect(result, isA<UpdateCheckFailed>());
      expect(controller.status, UpdateStatus.error);
    });

    test('marks a version as notified', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = makeUpdateController();

      expect(await controller.wasNotified('2.0.0'), isFalse);
      await controller.markNotified('2.0.0');
      expect(await controller.wasNotified('2.0.0'), isTrue);
    });
  });
}