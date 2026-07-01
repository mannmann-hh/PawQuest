import 'package:flutter/material.dart';

import '../models/daily_quest_model.dart';
import '../models/weather_model.dart';
import '../services/daily_quest_service.dart';
import '../services/weather_service.dart';

class DailyQuestProvider with ChangeNotifier {
  final DailyQuestRepository _dailyQuestService;
  final WeatherRepository _weatherService;

  DailyQuestProvider({
    DailyQuestRepository? dailyQuestService,
    WeatherRepository? weatherService,
  })  : _dailyQuestService = dailyQuestService ?? DailyQuestService(),
        _weatherService = weatherService ?? WeatherService();

  DailyQuestModel? _quest;
  WeatherModel? _weather;
  bool _isLoading = false;
  String? _errorMessage;
  double? _manualLatitude;
  double? _manualLongitude;

  DailyQuestModel? get quest => _quest;
  WeatherModel? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get usesManualLocation =>
      _manualLatitude != null && _manualLongitude != null;
  double? get manualLatitude => _manualLatitude;
  double? get manualLongitude => _manualLongitude;

  Future<void> loadTodayQuest(int currentSteps) async {
    _setLoading(true);
    try {
      WeatherModel? weather;
      String? weatherError;

      try {
        weather = await _fetchSelectedWeather();
      } catch (error) {
        weatherError = error.toString();
      }

      _weather = weather;
      _quest = await _dailyQuestService.getOrCreateTodayQuest(
        currentSteps: currentSteps,
        weather: weather,
      );
      _errorMessage = weatherError;
    } catch (error) {
      _quest = _dailyQuestService.buildDefaultQuest(
        currentSteps: currentSteps,
      );
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh(int currentSteps) async {
    await loadTodayQuest(currentSteps);
  }

  Future<void> useManualLocation({
    required double latitude,
    required double longitude,
    required int currentSteps,
  }) async {
    await _changeLocation(
      latitude: latitude,
      longitude: longitude,
      currentSteps: currentSteps,
    );
  }

  Future<void> useDeviceLocation({required int currentSteps}) async {
    await _changeLocation(currentSteps: currentSteps);
  }

  Future<void> _changeLocation({
    double? latitude,
    double? longitude,
    required int currentSteps,
  }) async {
    _setLoading(true);
    try {
      final weather = latitude == null || longitude == null
          ? await _weatherService.fetchCurrentWeather()
          : await _weatherService.fetchWeatherByCoordinates(
              latitude: latitude,
              longitude: longitude,
            );
      _manualLatitude = latitude;
      _manualLongitude = longitude;
      _weather = weather;
      _quest = await _dailyQuestService.replaceTodayQuest(
        currentSteps: currentSteps,
        weather: weather,
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<WeatherModel> _fetchSelectedWeather() {
    if (usesManualLocation) {
      return _weatherService.fetchWeatherByCoordinates(
        latitude: _manualLatitude!,
        longitude: _manualLongitude!,
      );
    }
    return _weatherService.fetchCurrentWeather();
  }

  Future<void> syncSteps(int currentSteps) async {
    try {
      _quest = await _dailyQuestService.updateTodayProgress(
        currentSteps,
        existingQuest: _quest,
      );
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
