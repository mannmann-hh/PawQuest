import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef CityUnlockedCallback = void Function(String cityName, String? badgeUrl);

class RouteManager {
  static final RouteManager _instance = RouteManager._internal();

  factory RouteManager() => _instance;

  RouteManager._internal();

  CityUnlockedCallback? _onCityUnlocked;

  void setOnCityUnlockedCallback(CityUnlockedCallback callback) {
    _onCityUnlocked = callback;
  }

  /// 加载当前用户已解锁的所有城市（根据步数）
  Future<List<Map<String, dynamic>>> loadUnlockedCities(
      int currentSteps) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('cities')
        .orderBy('order')
        .get();

    final List<Map<String, dynamic>> unlocked = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['stepRequired'] <= currentSteps) {
        unlocked.add({
          'name': data['name'],
          'stepRequired': data['stepRequired'],
          'badge': data['badge'],
          'order': data['order'],
          'x': data['x'], // Firestore 中设定的 number 类型
          'y': data['y'],
        });
      }
    }

    return unlocked;
  }

  /// 检查是否达到了新的城市步数要求，触发解锁逻辑（只触发一个）
  Future<void> checkAndUnlockCities(int currentSteps) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('cities')
        .orderBy('order')
        .get();

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final userDoc = await userRef.get();
    final int unlockedOrder = userDoc.data()?['currentCityOrder'] ?? -1;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final int cityOrder = data['order'];
      final int stepRequired = data['stepRequired'];

      if (cityOrder == unlockedOrder + 1 && currentSteps >= stepRequired) {
        // 解锁新城市
        await userRef.set(
          {'currentCityOrder': cityOrder},
          SetOptions(merge: true),
        );
        if (_onCityUnlocked != null) {
          _onCityUnlocked!(data['name'], data['badge']);
        }
        break;
      }
    }
  }
}
