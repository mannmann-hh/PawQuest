import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WatchService {
  WatchService._();
  static final WatchService instance = WatchService._();

  static const MethodChannel _channel = MethodChannel('pawquest/watch');
  String? _lastPayload;

  Future<void> sync(Map<String, dynamic> data) async {
    final encoded = jsonEncode(data);
    if (encoded == _lastPayload) return;
    _lastPayload = encoded;
    debugPrint('PawQuest watch: sync steps=${data['steps']} theme=${data['themeBg']}');
    try {
      final res = await _channel.invokeMethod('updateContext', data);
      debugPrint('PawQuest watch: native -> $res');
    } catch (e) {
      debugPrint('PawQuest watch: channel error -> $e');
    }
  }

  static String hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
