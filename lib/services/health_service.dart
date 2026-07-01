import 'package:flutter/services.dart';

/// Reads step data from Apple Health (HealthKit) via native code in
/// `AppDelegate.swift`. iOS only; returns null / false elsewhere or when
/// permission is denied.
class HealthService {
  static const MethodChannel _channel = MethodChannel('pawquest/health');

  Future<bool> requestAuthorization() async {
    try {
      final ok = await _channel.invokeMethod<bool>('requestAuthorization');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<int?> todaySteps() async {
    try {
      return await _channel.invokeMethod<int>('todaySteps');
    } catch (_) {
      return null;
    }
  }
}
