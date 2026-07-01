import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawquest/services/wiki_city_service.dart';

void main() {
  test('parses a Wikipedia summary including image and page URL', () {
    final summary = WikiSummary.fromJson({
      'title': 'Rome',
      'extract': 'Capital city of Italy.',
      'thumbnail': {'source': 'https://example.com/rome.jpg'},
      'content_urls': {
        'desktop': {'page': 'https://en.wikipedia.org/wiki/Rome'},
      },
    });

    expect(summary.title, 'Rome');
    expect(summary.extract, 'Capital city of Italy.');
    expect(summary.imageUrl, 'https://example.com/rome.jpg');
    expect(summary.pageUrl, 'https://en.wikipedia.org/wiki/Rome');
  });

  test('fetches mapped city, landmark, and history summaries', () async {
    final requestedPaths = <String>[];
    final service = WikiCityService(
      client: MockClient((request) async {
        requestedPaths.add(request.url.path);
        final title = Uri.decodeComponent(request.url.pathSegments.last);
        return http.Response(
          jsonEncode({'title': title, 'extract': '$title summary'}),
          200,
        );
      }),
    );

    final info = await service.fetchCityInfo('Rome');

    expect(info.city.title, 'Rome');
    expect(info.landmark?.title, 'Colosseum');
    expect(info.history?.title, 'History of Rome');
    expect(requestedPaths, hasLength(3));
  });

  test('keeps city data when an optional landmark request fails', () async {
    final service = WikiCityService(
      client: MockClient((request) async {
        final title = Uri.decodeComponent(request.url.pathSegments.last);
        if (title == 'Colosseum') return http.Response('', 404);
        return http.Response(
          jsonEncode({'title': title, 'extract': 'summary'}),
          200,
        );
      }),
    );

    final info = await service.fetchCityInfo('Rome');

    expect(info.city.title, 'Rome');
    expect(info.landmark, isNull);
    expect(info.history?.title, 'History of Rome');
  });

  test('fails when the required main city request fails', () async {
    final service = WikiCityService(
      client: MockClient((_) async => http.Response('', 503)),
    );

    expect(
      () => service.fetchCityInfo('Rome'),
      throwsA(isA<Exception>()),
    );
  });
}
