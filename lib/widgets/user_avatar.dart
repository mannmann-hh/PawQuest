import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/providers/theme_provider.dart';
import 'package:pawquest/theme/app_palette.dart';

/// Shows a user's current avatar (uploaded photo if any, otherwise their cat
/// character), resolved live from their user doc. Falls back to the first
/// letter of [fallbackName].
///
/// Results are cached per session with a short time-to-live so a list of posts
/// doesn't trigger a Firestore read per rebuild, while still picking up avatar
/// changes made by other users within [_ttl].
class UserAvatar extends StatefulWidget {
  final String? userId;
  final String? fallbackName;
  final double radius;

  const UserAvatar({
    super.key,
    required this.userId,
    this.fallbackName,
    this.radius = 16,
  });

  static const Duration _ttl = Duration(minutes: 5);

  /// uid -> cached entry
  static final Map<String, _CacheEntry> _cache = {};

  /// Clear a single user's cached avatar (call right after they update their
  /// own profile so their new photo shows everywhere immediately).
  static void invalidate(String uid) {
    _cache.remove(uid);
  }

  /// Clear the whole cache.
  static void invalidateAll() {
    _cache.clear();
  }

  static Future<Map<String, dynamic>?> _load(String uid) async {
    final now = DateTime.now();
    final cached = _cache[uid];
    if (cached != null && now.difference(cached.fetchedAt) < _ttl) {
      return cached.data;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      _cache[uid] = _CacheEntry(now, doc.data());
      return doc.data();
    } catch (_) {
      return cached?.data;
    }
  }

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _CacheEntry {
  final DateTime fetchedAt;
  final Map<String, dynamic>? data;
  _CacheEntry(this.fetchedAt, this.data);
}

class _UserAvatarState extends State<UserAvatar> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _future = _resolve();
    }
  }

  Future<Map<String, dynamic>?> _resolve() {
    final uid = widget.userId;
    if (uid == null || uid.isEmpty) return Future.value(null);
    return UserAvatar._load(uid);
  }

  Widget _circle(ImageProvider? img, String letter, AppPalette p) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: p.accent.withValues(alpha: 0.4),
      backgroundImage: img,
      child: img == null
          ? Text(
              letter,
              style: TextStyle(
                color: p.text,
                fontWeight: FontWeight.bold,
                fontSize: widget.radius * 0.85,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final letter =
        (widget.fallbackName != null && widget.fallbackName!.isNotEmpty)
            ? widget.fallbackName![0].toUpperCase()
            : '?';
    final uid = widget.userId;
    if (uid == null || uid.isEmpty) return _circle(null, letter, p);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        final avatarUrl = data?['avatarUrl'] as String?;
        final cat = data?['cat'] as String?;
        ImageProvider? img;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          img = NetworkImage(avatarUrl);
        } else if (cat != null && cat.isNotEmpty) {
          img = AssetImage('assets/images/cats_profile/$cat.jpeg');
        }
        return _circle(img, letter, p);
      },
    );
  }
}
