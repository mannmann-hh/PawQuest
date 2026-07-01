import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/models/weather_model.dart';
import 'package:pawquest/services/daily_quest_service.dart';

void main() {
  test('rebuilds the daily quest from the newly selected city weather', () {
    const romeWeather = WeatherModel(
      weatherMain: 'Rain',
      description: 'heavy rain',
      temperature: 18,
      locationName: 'Rome',
      latitude: 41.9028,
      longitude: 12.4964,
    );

    final refreshed = DailyQuestService.buildQuestForWeather(
      date: '2026-07-01',
      currentSteps: 1200,
      weather: romeWeather,
      rewardClaimed: true,
    );

    expect(refreshed.locationName, 'Rome');
    expect(refreshed.weatherMain, 'Rain');
    expect(refreshed.questTitle, 'Indoor Steps');
    expect(refreshed.goalSteps, 2500);
    expect(refreshed.currentSteps, 1200);
    expect(refreshed.rewardClaimed, isTrue);
  });
}
