import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/weather_model.dart';

abstract class WeatherRepository {
  Future<WeatherModel> fetchCurrentWeather();

  Future<WeatherModel> fetchWeatherByCoordinates({
    required double latitude,
    required double longitude,
  });
}

class WeatherService implements WeatherRepository {
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<WeatherModel> fetchCurrentWeather() async {
    final position = await _getCurrentPosition();
    return fetchWeatherByCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<WeatherModel> fetchWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw WeatherException('Latitude must be between -90 and 90.');
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw WeatherException('Longitude must be between -180 and 180.');
    }

    final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';

    if (apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw WeatherException(
        'OpenWeather API key is missing. Add it to your .env file.',
      );
    }

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'appid': apiKey,
      'units': 'metric',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw WeatherException('Weather request failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherModel.fromJson(
      json,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw WeatherException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw WeatherException('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw WeatherException(
        'Location permission is permanently denied. Enable it in Settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }
}

class WeatherException implements Exception {
  final String message;

  WeatherException(this.message);

  @override
  String toString() => message;
}
