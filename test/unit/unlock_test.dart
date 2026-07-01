import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/utils/unlock.dart';

void main() {
  group('Unlock.isUnlocked', () {
    test('unlocks exactly at the threshold', () {
      expect(Unlock.isUnlocked(1000, 1000), isTrue);
    });

    test('unlocks above the threshold', () {
      expect(Unlock.isUnlocked(1500, 1000), isTrue);
    });

    test('stays locked below the threshold', () {
      expect(Unlock.isUnlocked(999, 1000), isFalse);
    });

    test('a zero-step city is always unlocked', () {
      expect(Unlock.isUnlocked(0, 0), isTrue);
    });
  });

  group('Unlock.unlockedCount', () {
    // Mirrors the real PawQuest thresholds for the first few cities.
    final thresholds = [0, 1000, 4000, 6000, 10000];

    test('only the free city is unlocked at 0 steps', () {
      expect(Unlock.unlockedCount(0, thresholds), 1);
    });

    test('counts every milestone reached', () {
      expect(Unlock.unlockedCount(6000, thresholds), 4);
    });

    test('counts all when steps exceed the highest threshold', () {
      expect(Unlock.unlockedCount(99999, thresholds), thresholds.length);
    });

    test('returns 0 for an empty threshold list', () {
      expect(Unlock.unlockedCount(5000, const []), 0);
    });
  });
}
