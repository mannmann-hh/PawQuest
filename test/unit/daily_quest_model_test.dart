import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/models/daily_quest_model.dart';

void main() {
  test('creates a daily quest from Firestore data', () {
    final createdAt = Timestamp.fromDate(DateTime.utc(2026, 7, 1));
    final model = DailyQuestModel.fromFirestore({
      'date': '2026-07-01',
      'goalSteps': 2500,
      'currentSteps': 1000,
      'completed': false,
      'rewardClaimed': true,
      'questTitle': 'Indoor Steps',
      'questDescription': 'Walk safely inside.',
      'weatherMain': 'Rain',
      'temperature': 18,
      'locationName': 'Rome',
      'createdAt': createdAt,
    });

    expect(model.goalSteps, 2500);
    expect(model.temperature, 18.0);
    expect(model.locationName, 'Rome');
    expect(model.rewardClaimed, isTrue);
    expect(model.createdAt, createdAt);
  });

  test('uses defaults for legacy or incomplete Firestore data', () {
    final model = DailyQuestModel.fromFirestore(const {});

    expect(model.goalSteps, 4000);
    expect(model.questTitle, 'Daily Walk');
    expect(model.locationName, 'Current location');
    expect(model.completed, isFalse);
  });

  test('copyWith updates progress without changing task identity', () {
    final original = DailyQuestModel.fromFirestore({
      'date': '2026-07-01',
      'goalSteps': 4000,
      'currentSteps': 100,
      'questTitle': 'Daily Walk',
      'locationName': 'Milan',
    });
    final updated = original.copyWith(currentSteps: 4000, completed: true);

    expect(updated.currentSteps, 4000);
    expect(updated.completed, isTrue);
    expect(updated.questTitle, original.questTitle);
    expect(updated.locationName, original.locationName);
  });

  test('serializes all persistent fields', () {
    final model = DailyQuestModel.fromFirestore({
      'date': '2026-07-01',
      'goalSteps': 4000,
      'currentSteps': 100,
    });
    final data = model.toFirestore(includeCreatedAt: false);

    expect(data['date'], '2026-07-01');
    expect(data['goalSteps'], 4000);
    expect(data.containsKey('createdAt'), isFalse);
    expect(data['updatedAt'], isA<FieldValue>());
  });
}
