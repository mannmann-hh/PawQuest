import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/daily_quest_model.dart';
import '../models/weather_model.dart';

abstract class DailyQuestRepository {
  Future<DailyQuestModel> getOrCreateTodayQuest({
    required int currentSteps,
    WeatherModel? weather,
  });

  Future<DailyQuestModel> replaceTodayQuest({
    required int currentSteps,
    required WeatherModel weather,
  });

  Future<DailyQuestModel> updateTodayProgress(
    int currentSteps, {
    DailyQuestModel? existingQuest,
  });

  DailyQuestModel buildDefaultQuest({
    required int currentSteps,
    String? errorLocation,
  });
}

class DailyQuestService implements DailyQuestRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DailyQuestService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  String todayKey() {
    final now = DateTime.now();
    return _dateKey(now);
  }

  @override
  Future<DailyQuestModel> getOrCreateTodayQuest({
    required int currentSteps,
    WeatherModel? weather,
  }) async {
    final uid = _auth.currentUser?.uid;
    final date = todayKey();

    if (uid == null) {
      return _buildQuestFromWeather(
        date: date,
        currentSteps: currentSteps,
        weather: weather,
      );
    }

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('dailyQuests')
        .doc(date);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      final quest = DailyQuestModel.fromFirestore(doc.data()!);
      return updateTodayProgress(currentSteps, existingQuest: quest);
    }

    final quest = _buildQuestFromWeather(
      date: date,
      currentSteps: currentSteps,
      weather: weather,
    );
    await docRef.set(quest.toFirestore());
    return quest;
  }

  @override
  Future<DailyQuestModel> replaceTodayQuest({
    required int currentSteps,
    required WeatherModel weather,
  }) async {
    final uid = _auth.currentUser?.uid;
    final date = todayKey();
    var rewardClaimed = false;

    DocumentReference<Map<String, dynamic>>? docRef;
    if (uid != null) {
      docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('dailyQuests')
          .doc(date);
      final existing = await docRef.get();
      rewardClaimed = existing.data()?['rewardClaimed'] == true;
    }

    final quest = _buildQuestFromWeather(
      date: date,
      currentSteps: currentSteps,
      weather: weather,
      rewardClaimed: rewardClaimed,
    );
    await docRef?.set(quest.toFirestore());
    return quest;
  }

  @override
  Future<DailyQuestModel> updateTodayProgress(
    int currentSteps, {
    DailyQuestModel? existingQuest,
  }) async {
    final uid = _auth.currentUser?.uid;
    final date = todayKey();

    DailyQuestModel? quest = existingQuest;
    if (quest == null && uid != null) {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('dailyQuests')
          .doc(date)
          .get();
      if (doc.exists && doc.data() != null) {
        quest = DailyQuestModel.fromFirestore(doc.data()!);
      }
    }

    if (quest == null) {
      return _buildQuestFromWeather(date: date, currentSteps: currentSteps);
    }

    final updated = quest.copyWith(
      currentSteps: currentSteps,
      completed: currentSteps >= quest.goalSteps,
    );

    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('dailyQuests')
          .doc(date)
          .set({
        'currentSteps': updated.currentSteps,
        'completed': updated.completed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return updated;
  }

  @override
  DailyQuestModel buildDefaultQuest({
    required int currentSteps,
    String? errorLocation,
  }) {
    return _buildQuestFromWeather(
      date: todayKey(),
      currentSteps: currentSteps,
      locationName: errorLocation ?? 'Current location',
    );
  }

  DailyQuestModel _buildQuestFromWeather({
    required String date,
    required int currentSteps,
    WeatherModel? weather,
    String? locationName,
    bool rewardClaimed = false,
  }) {
    return buildQuestForWeather(
      date: date,
      currentSteps: currentSteps,
      weather: weather,
      locationName: locationName,
      rewardClaimed: rewardClaimed,
    );
  }

  static DailyQuestModel buildQuestForWeather({
    required String date,
    required int currentSteps,
    WeatherModel? weather,
    String? locationName,
    bool rewardClaimed = false,
  }) {
    final temperature = weather?.temperature ?? 0;
    final weatherMain = weather?.weatherMain ?? 'Default';
    final quest = _questRule(weatherMain, temperature);

    return DailyQuestModel(
      date: date,
      goalSteps: quest.goalSteps,
      currentSteps: currentSteps,
      completed: currentSteps >= quest.goalSteps,
      rewardClaimed: rewardClaimed,
      questTitle: quest.title,
      questDescription: quest.description,
      weatherMain: weatherMain,
      temperature: temperature,
      locationName: weather?.locationName ?? locationName ?? 'Current location',
    );
  }

  static _QuestRule _questRule(String weatherMain, double temperature) {
    if (temperature >= 30) {
      return const _QuestRule(
        goalSteps: 3000,
        title: 'Hot Weather Walk',
        description:
            'It is hot today. Complete 3000 steps and avoid walking at noon.',
      );
    }

    if (temperature <= 5) {
      return const _QuestRule(
        goalSteps: 2500,
        title: 'Cold Weather Walk',
        description: 'It is cold today. Complete 2500 steps and keep warm.',
      );
    }

    switch (weatherMain) {
      case 'Clear':
      case 'Clouds':
        return const _QuestRule(
          goalSteps: 5000,
          title: 'Outdoor Walk',
          description:
              'The weather is suitable for walking. Complete 5000 steps today.',
        );
      case 'Rain':
      case 'Drizzle':
      case 'Thunderstorm':
        return const _QuestRule(
          goalSteps: 2500,
          title: 'Indoor Steps',
          description: 'It is rainy today. Complete 2500 safe indoor steps.',
        );
      case 'Snow':
        return const _QuestRule(
          goalSteps: 2000,
          title: 'Safe Winter Walk',
          description:
              'It is snowing today. Complete 2000 safe steps and avoid slippery areas.',
        );
      case 'Mist':
      case 'Fog':
      case 'Haze':
      case 'Smoke':
      case 'Dust':
        return const _QuestRule(
          goalSteps: 3000,
          title: 'Careful Walk',
          description:
              'Visibility or air conditions are not ideal. Complete 3000 careful steps.',
        );
      default:
        return const _QuestRule(
          goalSteps: 4000,
          title: 'Daily Walk',
          description: 'Complete 4000 steps today.',
        );
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _QuestRule {
  final int goalSteps;
  final String title;
  final String description;

  const _QuestRule({
    required this.goalSteps,
    required this.title,
    required this.description,
  });
}
