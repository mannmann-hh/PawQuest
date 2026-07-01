import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/models/weather_model.dart';

void main() {
  group('WeatherModel.fromJson', () {
    test('parses OpenWeather fields and supplied coordinates', () {
      final model = WeatherModel.fromJson(
        {
          'weather': [
            {'main': 'Clouds', 'description': 'scattered clouds'},
          ],
          'main': {'temp': 21.6},
          'name': 'Milan',
        },
        latitude: 45.4642,
        longitude: 9.19,
      );

      expect(model.weatherMain, 'Clouds');
      expect(model.description, 'scattered clouds');
      expect(model.temperature, 21.6);
      expect(model.locationName, 'Milan');
      expect(model.latitude, 45.4642);
      expect(model.longitude, 9.19);
    });

    test('uses safe defaults when API fields are missing', () {
      final model = WeatherModel.fromJson(
        const {},
        latitude: 0,
        longitude: 0,
      );

      expect(model.weatherMain, 'Unknown');
      expect(model.description, 'No description');
      expect(model.temperature, 0);
      expect(model.locationName, 'Current location');
    });
  });

  group('WeatherModel.walkingAdvice', () {
    WeatherModel weather(String main, double temperature) => WeatherModel(
          weatherMain: main,
          description: '',
          temperature: temperature,
          locationName: 'Test city',
          latitude: 0,
          longitude: 0,
        );

    test('warns about hot and cold temperatures', () {
      expect(weather('Clear', 30).walkingAdvice, contains('hot'));
      expect(weather('Clear', 5).walkingAdvice, contains('cold'));
    });

    test('recommends indoor steps for rain', () {
      expect(weather('Rain', 15).walkingAdvice, contains('Indoor'));
    });

    test('warns about low visibility', () {
      expect(weather('Fog', 15).walkingAdvice, contains('Visibility'));
    });
  });
}
