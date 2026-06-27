import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawquest/services/forum_service.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatelessWidget {
  CommunityScreen({super.key});

  final ForumService _forum = ForumService();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          /// 固定背景图
          Positioned.fill(
            child: Image.asset(
              "assets/images/talk_bg.jpeg",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Image.asset(
                  "assets/images/title/talk.png",
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final posts = snapshot.data?.docs ?? [];

                      if (posts.isEmpty) {
                        return const Center(
                          child: Text(
                            'No posts yet — be the first to share!',
                            style: TextStyle(
                              color: Color(0xFF6B4F3A),
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final doc = posts[index];
                          final postData = doc.data() as Map<String, dynamic>;
                          return _PostCard(
                            postId: doc.id,
                            postData: postData,
                            currentUid: currentUser?.uid,
                            forum: _forum,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: Colors.amberAccent,
          child: const Icon(Icons.add, color: Colors.brown),
          onPressed: () => _showPostDialog(context),
        ),
      ),
    );
  }

  void _showPostDialog(BuildContext context) {
    final controller = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Post'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          minLines: 1,
          decoration: const InputDecoration(hintText: 'Share something...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = controller.text.trim();
              if (content.isNotEmpty && user != null) {
                final nickname = await _forum.resolveNickname(user.uid);
                await FirebaseFirestore.instance.collection('posts').add({
                  'authorId': user.uid,
                  'authorName': nickname,
                  'content': content,
                  'likes': 0,
                  'likedBy': <String>[],
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.postId,
    required this.postData,
    required this.currentUid,
    required this.forum,
  });

  final String postId;
  final Map<String, dynamic> postData;
  final String? currentUid;
  final ForumService forum;

  @override
  Widget build(BuildContext context) {
    final isAuthor = currentUid != null && currentUid == postData['authorId'];
    final liked = forum.isLikedBy(postData, currentUid);
    final likes = forum.likeCount(postData);
    final ts = postData['timestamp'];
    final timeLabel = ts is Timestamp
        ? ts.toDate().toString().substring(0, 16)
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white.withOpacity(0.92),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              postId: postId,
              authorName: postData['authorName'] ?? 'Anonymous user',
              content: postData['content'] ?? '',
              timestamp: ts is Timestamp ? ts : Timestamp.now(),
            ),
          ),
        ),
        onLongPress: isAuthor ? () => _confirmDelete(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      postData['authorName'] ?? 'Anonymous user',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B4F3A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    timeLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                postData['content'] ?? '',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? Colors.redAccent : Colors.grey,
                      size: 22,
                    ),
                    onPressed: currentUid == null
                        ? null
                        : () => forum.togglePostLike(postId),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$likes',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B4F3A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Do you really want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    }
  }
}
