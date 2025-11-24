import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class StepProvider with ChangeNotifier {

  
  int _currentStep = 0;
  int get steps => _currentStep;

  StreamSubscription<StepCount>? _subscription;
  int? _initialSensorSteps;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Load current step from Firestore
  Future<void> loadSavedSteps() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();

    if (doc.exists && doc.data()?['currentStep'] != null) {
      _currentStep = doc.data()!['currentStep'];
      notifyListeners();
    }
  }

  /// Start listening to step sensor (REAL DEVICE)
  void startListening() {
    _subscription = Pedometer.stepCountStream.listen(
      _onStep,
      onError: (error) => print('步数监听错误: $error'),
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
    _initialSensorSteps = event.steps;

    notifyListeners();
    await _saveToFirestore();
  }

  /// Debug steps (SIMULATOR)
  void addDebugSteps(int count) async {
    _currentStep += count;
    notifyListeners();
    await _saveToFirestore();
  }

  /// ✅ CORRECT _saveToFirestore — only one version!
 Future<void> _saveToFirestore() async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;

  final now = DateTime.now();
  final dateStr =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

  // 1. 获取昨天的步数
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final yStr =
      "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

  int yesterdayTotal = 0;

  final yDoc = await _firestore
      .collection('users')
      .doc(uid)
      .collection('step_history')
      .doc(yStr)
      .get();

  if (yDoc.exists && yDoc.data()?['total'] != null) {
    yesterdayTotal = yDoc.data()!['total'];
  }

  // 2. 计算今日步数差值
  final dailySteps = _currentStep - yesterdayTotal;

  // 3. 写入 Firestore：总步数 + 今日步数
  await _firestore
      .collection('users')
      .doc(uid)
      .collection('step_history')
      .doc(dateStr)
      .set({
    'total': _currentStep,
    'daily': dailySteps < 0 ? _currentStep : dailySteps, // 防止负数
    'date': dateStr,
    'timestamp': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  print("🔥 Daily steps saved: $dailySteps for $dateStr");
}


  /// Stop listener
  void disposeListener() {
    _subscription?.cancel();
  }

  /// Reset when logout
  void resetSteps() {
    _currentStep = 0;
    notifyListeners();
    
  }

  /// Set steps manually (e.g. after login)
  void setSteps(int newSteps) {
    _currentStep = newSteps;
    notifyListeners();

  }


}
