import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'daily_quest_provider.dart';
import '../services/health_service.dart';
import '../utils/step_math.dart';

class StepProvider with ChangeNotifier {
  int _currentStep = 0;
  int _todaySteps = 0;
  int get steps => _currentStep;
  int get todaySteps => _todaySteps;

  final HealthService _health = HealthService();

  StreamSubscription<StepCount>? _subscription;
  int? _initialSensorSteps;
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
    if (_subscription != null) return;

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

    final delta = StepMath.sensorDelta(
      previousReading: _initialSensorSteps!,
      currentReading: event.steps,
    );
    if (delta == 0) return;

    _initialSensorSteps = event.steps;
    await _saveToFirestore(delta);
  }

  /// Request Apple Health authorization (iOS). Safe no-op elsewhere.
  Future<bool> requestHealthAccess() => _health.requestAuthorization();

  /// Read today's steps from Apple Health and reconcile with local state.
  /// Only adds the positive difference so we never double-count against the
  /// pedometer stream. Safe to call on launch and on app resume.
  Future<void> syncFromHealth() async {
    final healthToday = await _health.todaySteps();
    if (healthToday == null) return;
    if (healthToday > _todaySteps) {
      final delta = healthToday - _todaySteps;
      _currentStep += delta;
      _todaySteps = healthToday;
      notifyListeners();
      await _saveToFirestore(delta);
    }
  }

  /// Debug steps (SIMULATOR)
  Future<void> addDebugSteps(int count) async {
    await _saveToFirestore(count);
  }

  /// ✅ CORRECT _saveToFirestore — only one version!
  Future<void> _saveToFirestore(int deltaSteps) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _currentStep = StepMath.nonNegative(_currentStep + deltaSteps);
      _todaySteps = StepMath.nonNegative(_todaySteps + deltaSteps);
      notifyListeners();
      return;
    }

    final dateStr = _todayDateKey();
    final userRef = _firestore.collection('users').doc(uid);
    final historyRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('step_history')
        .doc(dateStr);

    final saved =
        await _firestore.runTransaction<(int, int)>((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final historySnapshot = await transaction.get(historyRef);
      final serverTotal =
          (userSnapshot.data()?['currentStep'] as num?)?.toInt() ?? 0;
      final serverDaily =
          (historySnapshot.data()?['daily'] as num?)?.toInt() ?? 0;
      final newTotal = StepMath.nonNegative(serverTotal + deltaSteps);
      final newDaily = StepMath.nonNegative(serverDaily + deltaSteps);

      transaction.set(
        userRef,
        {
          'currentStep': newTotal,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      transaction.set(
        historyRef,
        {
          'total': newTotal,
          'daily': newDaily,
          'date': dateStr,
          'timestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return (newTotal, newDaily);
    });

    _currentStep = saved.$1;
    _todaySteps = saved.$2;
    notifyListeners();

    await _dailyQuestProvider?.syncSteps(_todaySteps);

    debugPrint("🔥 Daily steps saved: $_todaySteps for $dateStr");
  }

  /// Stop listener
  void disposeListener() {
    _subscription?.cancel();
    _subscription = null;
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
