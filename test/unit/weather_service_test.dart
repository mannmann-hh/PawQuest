import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawquest/services/weather_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches current weather for explicitly supplied coordinates', () async {
    dotenv.testLoad(fileInput: 'OPENWEATHER_API_KEY=test-key');
    late Uri requestedUri;
    final service = WeatherService(
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'weather': [
              {'main': 'Clear', 'description': 'clear sky'},
            ],
            'main': {'temp': 27.4},
            'name': 'Rome',
          }),
          200,
        );
      }),
    );

    final weather = await service.fetchWeatherByCoordinates(
      latitude: 41.9028,
      longitude: 12.4964,
    );

    expect(requestedUri.queryParameters['lat'], '41.9028');
    expect(requestedUri.queryParameters['lon'], '12.4964');
    expect(requestedUri.queryParameters['units'], 'metric');
    expect(weather.locationName, 'Rome');
    expect(weather.temperature, 27.4);
    expect(weather.latitude, 41.9028);
    expect(weather.longitude, 12.4964);
  });

  test('throws a readable error when the API key is missing', () async {
    dotenv.testLoad(fileInput: 'OPENWEATHER_API_KEY=');
    final service = WeatherService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    expect(
      () => service.fetchWeatherByCoordinates(latitude: 0, longitude: 0),
      throwsA(
        isA<WeatherException>().having(
          (error) => error.message,
          'message',
          contains('API key is missing'),
        ),
      ),
    );
  });

  test('throws the HTTP status when OpenWeather rejects the request', () async {
    dotenv.testLoad(fileInput: 'OPENWEATHER_API_KEY=test-key');
    final service = WeatherService(
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    expect(
      () => service.fetchWeatherByCoordinates(latitude: 0, longitude: 0),
      throwsA(
        isA<WeatherException>().having(
          (error) => error.message,
          'message',
          contains('401'),
        ),
      ),
    );
  });

  test('rejects invalid and non-finite coordinates before making a request',
      () async {
    dotenv.testLoad(fileInput: 'OPENWEATHER_API_KEY=test-key');
    var requestCount = 0;
    final service = WeatherService(
      client: MockClient((_) async {
        requestCount++;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      service.fetchWeatherByCoordinates(latitude: 91, longitude: 0),
      throwsA(isA<WeatherException>()),
    );
    await expectLater(
      service.fetchWeatherByCoordinates(latitude: 0, longitude: double.nan),
      throwsA(isA<WeatherException>()),
    );
    expect(requestCount, 0);
  });

  test('reports malformed JSON returned by the weather server', () async {
    dotenv.testLoad(fileInput: 'OPENWEATHER_API_KEY=test-key');
    final service = WeatherService(
      client: MockClient((_) async => http.Response('not-json', 200)),
    );

    expect(
      () => service.fetchWeatherByCoordinates(latitude: 0, longitude: 0),
      throwsA(isA<FormatException>()),
    );
  });
}
