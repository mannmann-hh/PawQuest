import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawquest/services/forum_service.dart';
import 'post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ForumService _forum = ForumService();

  @override
  void initState() {
    super.initState();
    // Clear the red dot as soon as the user opens this screen.
    _forum.markAllNotificationsRead();
  }

  Future<void> _openPost(BuildContext context, String postId) async {
    final doc =
        await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    if (!doc.exists || !context.mounted) return;
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['timestamp'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          postId: postId,
          authorName: data['authorName'] ?? 'Anonymous user',
          content: data['content'] ?? '',
          timestamp: ts is Timestamp ? ts : Timestamp.now(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _forum.notificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifs = snapshot.data?.docs ?? [];
          if (notifs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = notifs[index].data() as Map<String, dynamic>;
              final type = data['type'] ?? 'like';
              final actor = data['actorName'] ?? 'Someone';
              final preview = data['postPreview'] ?? '';
              final ts = data['timestamp'];
              final timeLabel =
                  ts is Timestamp ? ts.toDate().toString().substring(0, 16) : '';

              final isLike = type == 'like';
              final title = isLike
                  ? '$actor liked your post'
                  : '$actor commented on your post';
              final subtitle = isLike
                  ? '“$preview”'
                  : '“${data['commentText'] ?? ''}”';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isLike ? Colors.red.shade50 : Colors.blue.shade50,
                  child: Icon(
                    isLike ? Icons.favorite : Icons.mode_comment_outlined,
                    color: isLike ? Colors.redAccent : Colors.blueAccent,
                    size: 20,
                  ),
                ),
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(timeLabel,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                onTap: () => _openPost(context, data['postId'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
