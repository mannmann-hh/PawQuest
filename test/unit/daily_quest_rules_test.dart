import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/models/weather_model.dart';
import 'package:pawquest/services/daily_quest_service.dart';

void main() {
  WeatherModel weather(String main, double temperature) => WeatherModel(
        weatherMain: main,
        description: '',
        temperature: temperature,
        locationName: 'Test city',
        latitude: 0,
        longitude: 0,
      );

  test('generates the expected task for every weather category', () {
    final cases = <({String main, double temp, String title, int goal})>[
      (main: 'Clear', temp: 30, title: 'Hot Weather Walk', goal: 3000),
      (main: 'Clouds', temp: 5, title: 'Cold Weather Walk', goal: 2500),
      (main: 'Clear', temp: 20, title: 'Outdoor Walk', goal: 5000),
      (main: 'Rain', temp: 20, title: 'Indoor Steps', goal: 2500),
      (main: 'Drizzle', temp: 20, title: 'Indoor Steps', goal: 2500),
      (main: 'Thunderstorm', temp: 20, title: 'Indoor Steps', goal: 2500),
      (main: 'Snow', temp: 10, title: 'Safe Winter Walk', goal: 2000),
      (main: 'Fog', temp: 10, title: 'Careful Walk', goal: 3000),
      (main: 'Unknown', temp: 10, title: 'Daily Walk', goal: 4000),
    ];

    for (final item in cases) {
      final quest = DailyQuestService.buildQuestForWeather(
        date: '2026-07-01',
        currentSteps: 0,
        weather: weather(item.main, item.temp),
      );
      expect(quest.questTitle, item.title, reason: item.main);
      expect(quest.goalSteps, item.goal, reason: item.main);
    }
  });

  test('marks a regenerated task complete when its goal is already reached',
      () {
    final quest = DailyQuestService.buildQuestForWeather(
      date: '2026-07-01',
      currentSteps: 5000,
      weather: weather('Clear', 20),
    );

    expect(quest.completed, isTrue);
  });
}
