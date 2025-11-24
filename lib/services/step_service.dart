import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepService {
  StreamSubscription<StepCount>? _subscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _initialSteps = 0;
  bool _initialized = false;

  /// 启动步数监听
  void startListening() {
    _subscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepError,
      cancelOnError: true,
    );
  }

  /// 从 Firestore 加载当前用户步数作为基准值
  Future<void> loadStepsFromFirestore() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      int firestoreSteps = userDoc['currentStep'] ?? 0;
      _initialSteps = 0; // 初始化本地步数偏移为 0，等待下一次事件
      _initialized = false; // 重新监听时初始化
      print('✅ 成功从 Firestore 加载 currentStep: $firestoreSteps');
    } catch (e) {
      print('加载步数失败: $e');
    }
  }

  /// 步数更新时调用
  void _onStepCount(StepCount event) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await userRef.get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      int previousStep = userData['currentStep'] ?? 0;

      if (!_initialized) {
        _initialSteps = event.steps;
        _initialized = true;
        return;
      }

      int delta = event.steps - _initialSteps;
      if (delta <= 0) return;

      int newStep = previousStep + delta;
      _initialSteps = event.steps;

      await userRef.update({'currentStep': newStep});
      await _checkAndUnlockCities(userRef, userData, newStep);
    } catch (e) {
      print('步数处理异常: $e');
    }
  }

  /// Check if the step count meets the new city requirement and update the badge and currentCity
  Future<void> _checkAndUnlockCities(DocumentReference userRef,
      Map<String, dynamic> userData, int newStep) async {
    final List<String> badges = List<String>.from(userData['badges'] ?? []);
    final cities = await _loadCitiesConfig();

    for (var city in cities) {
      final String name = city['name'];
      final int requiredSteps = city['step'];

      if (newStep >= requiredSteps && !badges.contains(name)) {
        badges.add(name);
        await userRef.update({
          'badges': badges,
          'currentCity': name,
        });
        print('解锁城市: $name');
      }
    }
  }

  /// 加载城市配置
  Future<List<dynamic>> _loadCitiesConfig() async {
    final String jsonString =
        await rootBundle.loadString('assets/config/cities.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return jsonData['cities'] ?? [];
  }

  /// 错误处理
  void _onStepError(error) {
    print('步数监听错误: $error');
  }

  /// 停止监听
  void dispose() {
    _subscription?.cancel();
  }

  /// 登出时调用，清空本地步数缓存
  void resetSteps() {
    _initialSteps = 0;
    _initialized = false;
    print('步数缓存已重置');
  }
}