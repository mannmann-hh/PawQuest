import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'daily_quest_provider.dart';

class StepProvider with ChangeNotifier {
  int _currentStep = 0;
  int _todaySteps = 0;
  int get steps => _currentStep;
  int get todaySteps => _todaySteps;

  StreamSubscription<StepCount>? _subscription;
  int? _initialSensorSteps;
  String? _activeDateKey;
  DailyQuestProvider? _dailyQuestProvider;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void attachDailyQuestProvider(DailyQuestProvider provider) {
    _dailyQuestProvider = provider;
  }

  /// Load current step from Firestore
  Future<void> loadSavedSteps() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateStr = _todayDateKey();
    _activeDateKey = dateStr;

    final doc = await _firestore.collection('users').doc(uid).get();

    if (doc.exists && doc.data()?['currentStep'] != null) {
      _currentStep = doc.data()!['currentStep'];
    }

    final todayDoc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('step_history')
        .doc(dateStr)
        .get();

    if (todayDoc.exists && todayDoc.data()?['daily'] != null) {
      _todaySteps = todayDoc.data()!['daily'];
    } else {
      _todaySteps = 0;
    }

    notifyListeners();
  }

  /// Start listening to step sensor (REAL DEVICE)
  void startListening() {
    _subscription = Pedometer.stepCountStream.listen(
      _onStep,
      onError: (error) => debugPrint('步数监听错误: $error'),
    );
  }

  /// Sensor event handler
  void _onStep(StepCount event) async {
    if (_initialSensorSteps == null) {
      _initialSensorSteps = event.steps;
      return;
    }

    int delta = event.steps - _initialSensorSteps!;
    if (delta <= 0) return;

    _currentStep += delta;
    _todaySteps += delta;
    _initialSensorSteps = event.steps;

    notifyListeners();
    await _saveToFirestore(delta);
  }

  /// Debug steps (SIMULATOR)
  void addDebugSteps(int count) async {
    _currentStep += count;
    _todaySteps += count;
    notifyListeners();
    await _saveToFirestore(count);
  }

  /// ✅ CORRECT _saveToFirestore — only one version!
  Future<void> _saveToFirestore(int deltaSteps) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateStr = _todayDateKey();
    if (_activeDateKey != dateStr) {
      _activeDateKey = dateStr;
      _todaySteps = deltaSteps;
    }

    final safeDailySteps = _todaySteps < 0 ? 0 : _todaySteps;
    notifyListeners();

    // currentStep is the lifetime total. step_history.daily is today's steps.
    await _firestore.collection('users').doc(uid).set({
      'currentStep': _currentStep,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('step_history')
        .doc(dateStr)
        .set({
      'total': _currentStep,
      'daily': safeDailySteps, // 防止负数
      'date': dateStr,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _dailyQuestProvider?.syncSteps(safeDailySteps);

    debugPrint("🔥 Daily steps saved: $safeDailySteps for $dateStr");
  }

  /// Stop listener
  void disposeListener() {
    _subscription?.cancel();
  }

  /// Reset when logout
  void resetSteps() {
    _currentStep = 0;
    _todaySteps = 0;
    notifyListeners();
  }

  /// Set steps manually (e.g. after login)
  void setSteps(int newSteps) {
    _currentStep = newSteps;
    notifyListeners();
  }

  void setTodaySteps(int newSteps) {
    _todaySteps = newSteps;
    notifyListeners();
  }

  String _todayDateKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
}
