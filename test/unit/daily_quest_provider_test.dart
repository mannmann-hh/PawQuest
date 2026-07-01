import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/models/daily_quest_model.dart';
import 'package:pawquest/models/weather_model.dart';
import 'package:pawquest/providers/daily_quest_provider.dart';
import 'package:pawquest/services/daily_quest_service.dart';
import 'package:pawquest/services/weather_service.dart';

void main() {
  const milan = WeatherModel(
    weatherMain: 'Clear',
    description: 'clear sky',
    temperature: 22,
    locationName: 'Milan',
    latitude: 45.4642,
    longitude: 9.19,
  );
  const rome = WeatherModel(
    weatherMain: 'Rain',
    description: 'rain',
    temperature: 18,
    locationName: 'Rome',
    latitude: 41.9028,
    longitude: 12.4964,
  );

  test('loads weather and daily quest while exposing loading changes',
      () async {
    final weather = _FakeWeatherRepository(current: milan);
    final quests = _FakeQuestRepository();
    final provider = DailyQuestProvider(
      weatherService: weather,
      dailyQuestService: quests,
    );
    final loadingStates = <bool>[];
    provider.addListener(() => loadingStates.add(provider.isLoading));

    await provider.loadTodayQuest(800);

    expect(provider.weather, milan);
    expect(provider.quest?.locationName, 'Milan');
    expect(provider.errorMessage, isNull);
    expect(loadingStates, containsAllInOrder([true, false]));
  });

  test('keeps a default quest and exposes weather failures', () async {
    final provider = DailyQuestProvider(
      weatherService: _FakeWeatherRepository(error: Exception('offline')),
      dailyQuestService: _FakeQuestRepository(),
    );

    await provider.loadTodayQuest(200);

    expect(provider.weather, isNull);
    expect(provider.quest, isNotNull);
    expect(provider.errorMessage, contains('offline'));
  });

  test('manual coordinates rebuild the task for the selected place', () async {
    final weather = _FakeWeatherRepository(current: milan, manual: rome);
    final quests = _FakeQuestRepository();
    final provider = DailyQuestProvider(
      weatherService: weather,
      dailyQuestService: quests,
    );

    await provider.useManualLocation(
      latitude: 41.9028,
      longitude: 12.4964,
      currentSteps: 1200,
    );

    expect(provider.usesManualLocation, isTrue);
    expect(provider.manualLatitude, 41.9028);
    expect(provider.weather, rome);
    expect(provider.quest?.locationName, 'Rome');
    expect(quests.replaceCalls, 1);
  });

  test('switching back to device location clears manual coordinates', () async {
    final weather = _FakeWeatherRepository(current: milan, manual: rome);
    final provider = DailyQuestProvider(
      weatherService: weather,
      dailyQuestService: _FakeQuestRepository(),
    );
    await provider.useManualLocation(
      latitude: 41.9028,
      longitude: 12.4964,
      currentSteps: 0,
    );

    await provider.useDeviceLocation(currentSteps: 0);

    expect(provider.usesManualLocation, isFalse);
    expect(provider.manualLatitude, isNull);
    expect(provider.weather, milan);
  });

  test('refresh uses the currently selected manual coordinates', () async {
    final weather = _FakeWeatherRepository(current: milan, manual: rome);
    final provider = DailyQuestProvider(
      weatherService: weather,
      dailyQuestService: _FakeQuestRepository(),
    );
    await provider.useManualLocation(
      latitude: 41.9028,
      longitude: 12.4964,
      currentSteps: 0,
    );

    await provider.refresh(500);

    expect(weather.manualCalls, 2);
    expect(provider.weather, rome);
  });
}

class _FakeWeatherRepository implements WeatherRepository {
  final WeatherModel? current;
  final WeatherModel? manual;
  final Object? error;
  int manualCalls = 0;

  _FakeWeatherRepository({this.current, this.manual, this.error});

  @override
  Future<WeatherModel> fetchCurrentWeather() async {
    if (error != null) throw error!;
    return current!;
  }

  @override
  Future<WeatherModel> fetchWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    manualCalls++;
    if (error != null) throw error!;
    return manual!;
  }
}

class _FakeQuestRepository implements DailyQuestRepository {
  int replaceCalls = 0;

  DailyQuestModel _quest(int steps, WeatherModel? weather) {
    return DailyQuestService.buildQuestForWeather(
      date: '2026-07-01',
      currentSteps: steps,
      weather: weather,
    );
  }

  @override
  DailyQuestModel buildDefaultQuest({
    required int currentSteps,
    String? errorLocation,
  }) =>
      _quest(currentSteps, null);

  @override
  Future<DailyQuestModel> getOrCreateTodayQuest({
    required int currentSteps,
    WeatherModel? weather,
  }) async =>
      _quest(currentSteps, weather);

  @override
  Future<DailyQuestModel> replaceTodayQuest({
    required int currentSteps,
    required WeatherModel weather,
  }) async {
    replaceCalls++;
    return _quest(currentSteps, weather);
  }

  @override
  Future<DailyQuestModel> updateTodayProgress(
    int currentSteps, {
    DailyQuestModel? existingQuest,
  }) async =>
      existingQuest ?? _quest(currentSteps, null);
}
