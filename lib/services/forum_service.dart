import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralizes all forum-related Firestore writes (likes, comments and the
/// notifications they generate). Keeping this logic out of the widgets makes
/// the UI declarative and the security rules easy to reason about.
class ForumService {
  ForumService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // ---------------------------------------------------------------- helpers

  /// Whether [postData] is currently liked by the signed-in user.
  bool isLikedBy(Map<String, dynamic> postData, String? uid) {
    if (uid == null) return false;
    final likedBy = List<String>.from(postData['likedBy'] ?? const []);
    return likedBy.contains(uid);
  }

  /// Reads the like count defensively (old posts may not have the field yet).
  int likeCount(Map<String, dynamic> postData) {
    final raw = postData['likes'];
    if (raw is int) return raw;
    return List<String>.from(postData['likedBy'] ?? const []).length;
  }

  /// Resolves a user's chosen nickname from their Firestore profile, falling
  /// back to a default. Avoids the always-null Auth displayName.
  Future<String> resolveNickname(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final nickname = (doc.data()?['nickname'] as String?)?.trim();
      if (nickname != null && nickname.isNotEmpty) return nickname;
    } catch (_) {
      // fall through to default
    }
    return 'Anonymous user';
  }

  String _preview(Object? content) {
    final text = (content as String?)?.trim() ?? '';
    if (text.length <= 40) return text;
    return '${text.substring(0, 40)}…';
  }

  // ------------------------------------------------------------------ likes

  /// Toggles the current user's like on a post inside a transaction so the
  /// count can never drift. When a like is *added* (not removed) and the
  /// liker is not the author, a notification is written for the author in the
  /// same atomic transaction.
  ///
  /// Returns the new liked state (true = now liked), or null if not signed in.
  Future<bool?> togglePostLike(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    // Resolve the actor's name up-front (reads must precede writes inside the
    // transaction, and this is cheap to do once).
    final actorName = await resolveNickname(uid);
    final postRef = _db.collection('posts').doc(postId);

    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(postRef);
      if (!snap.exists) return false;

      final data = snap.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? const []);
      final alreadyLiked = likedBy.contains(uid);

      if (alreadyLiked) {
        likedBy.remove(uid);
      } else {
        likedBy.add(uid);
      }

      tx.update(postRef, {'likedBy': likedBy, 'likes': likedBy.length});

      final authorId = data['authorId'] as String?;
      final nowLiked = !alreadyLiked;
      if (nowLiked && authorId != null && authorId != uid) {
        final notifRef = _db
            .collection('users')
            .doc(authorId)
            .collection('notifications')
            .doc();
        tx.set(notifRef, {
          'type': 'like',
          'postId': postId,
          'postPreview': _preview(data['content']),
          'actorId': uid,
          'actorName': actorName,
          'commentText': '',
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      return nowLiked;
    });
  }

  // --------------------------------------------------------------- comments

  /// Adds a comment, or a reply to an existing comment when [parentId] is
  /// given. Stores the author's nickname (not the always-null Auth
  /// displayName) and a `parentId` field (null for top-level comments).
  ///
  /// Notifications:
  /// - a top-level comment notifies the post author
  /// - a reply notifies the author of the comment being replied to
  /// (in both cases only when the actor is not the recipient).
  Future<void> addComment(
    String postId,
    String text, {
    String? parentId,
    String? parentAuthorId,
  }) async {
    final uid = _auth.currentUser?.uid;
    final body = text.trim();
    if (uid == null || body.isEmpty) return;

    final actorName = await resolveNickname(uid);
    final postRef = _db.collection('posts').doc(postId);
    final postSnap = await postRef.get();
    final postData = postSnap.data() as Map<String, dynamic>?;
    final preview = _preview(postData?['content']);

    await postRef.collection('comments').add({
      'authorId': uid,
      'authorName': actorName,
      'content': body,
      'parentId': parentId, // null for top-level comments
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (parentId == null) {
      // Top-level comment -> notify the post author.
      final authorId = postData?['authorId'] as String?;
      if (authorId != null && authorId != uid) {
        await _addNotification(
          toUid: authorId,
          type: 'comment',
          postId: postId,
          postPreview: preview,
          actorId: uid,
          actorName: actorName,
          commentText: body,
        );
      }
    } else if (parentAuthorId != null && parentAuthorId != uid) {
      // Reply -> notify the author of the comment being replied to.
      await _addNotification(
        toUid: parentAuthorId,
        type: 'reply',
        postId: postId,
        postPreview: preview,
        actorId: uid,
        actorName: actorName,
        commentText: body,
      );
    }
  }

  /// Writes a single notification document under the recipient's profile.
  Future<void> _addNotification({
    required String toUid,
    required String type,
    required String postId,
    required String postPreview,
    required String actorId,
    required String actorName,
    required String commentText,
  }) async {
    await _db.collection('users').doc(toUid).collection('notifications').add({
      'type': type,
      'postId': postId,
      'postPreview': postPreview,
      'actorId': actorId,
      'actorName': actorName,
      'commentText': commentText,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------- notifications

  /// Live count of unread notifications for the signed-in user (drives the
  /// red dot on the profile tab).
  Stream<int> unreadNotificationCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream<int>.value(0);
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Live notification feed (newest first) for the signed-in user.
  Stream<QuerySnapshot> notificationsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot>.empty();
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Marks every unread notification as read (called when the user opens the
  /// notifications screen).
  Future<void> markAllNotificationsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final unread = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
