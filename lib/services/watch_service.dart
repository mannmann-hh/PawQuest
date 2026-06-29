import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pushes the latest app state to a paired Apple Watch.
///
/// On iOS this talks to native code (see `AppDelegate.swift`) which forwards
/// the payload to the watch through `WCSession.updateApplicationContext`.
/// On any other platform, or when no watch is reachable, calls are silently
/// ignored. Identical consecutive payloads are de-duplicated so we don't spam
/// the connectivity session on every widget rebuild.
class WatchService {
  WatchService._();
  static final WatchService instance = WatchService._();

  static const MethodChannel _channel = MethodChannel('pawquest/watch');
  String? _lastPayload;

  Future<void> sync(Map<String, dynamic> data) async {
    final encoded = jsonEncode(data);
    if (encoded == _lastPayload) return;
    _lastPayload = encoded;
    try {
      await _channel.invokeMethod('updateContext', data);
    } catch (_) {
      // Watch not reachable, or not running on iOS — ignore.
    }
  }

  /// "#RRGGBB" string for a Color, for sending the active theme to the watch.
  static String hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
