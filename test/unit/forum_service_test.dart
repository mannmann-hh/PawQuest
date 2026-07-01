import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/services/forum_service.dart';

void main() {
  group('ForumService.isLikedBy', () {
    test('returns false when uid is null', () {
      final post = {
        'likedBy': ['u1', 'u2']
      };
      expect(ForumService.isLikedBy(post, null), isFalse);
    });

    test('returns true when the uid is in likedBy', () {
      final post = {
        'likedBy': ['u1', 'u2']
      };
      expect(ForumService.isLikedBy(post, 'u2'), isTrue);
    });

    test('returns false when the uid is not in likedBy', () {
      final post = {
        'likedBy': ['u1', 'u2']
      };
      expect(ForumService.isLikedBy(post, 'u3'), isFalse);
    });

    test('handles posts with no likedBy field (legacy posts)', () {
      expect(ForumService.isLikedBy(<String, dynamic>{}, 'u1'), isFalse);
    });
  });

  group('ForumService.likeCount', () {
    test('reads the integer likes field when present', () {
      expect(ForumService.likeCount({'likes': 5}), 5);
    });

    test('falls back to likedBy length when likes is missing', () {
      final post = {
        'likedBy': ['u1', 'u2', 'u3']
      };
      expect(ForumService.likeCount(post), 3);
    });

    test('returns 0 for a post with neither field', () {
      expect(ForumService.likeCount(<String, dynamic>{}), 0);
    });

    test('prefers the explicit likes field over likedBy length', () {
      final post = {
        'likes': 10,
        'likedBy': ['u1']
      };
      expect(ForumService.likeCount(post), 10);
    });
  });
}
