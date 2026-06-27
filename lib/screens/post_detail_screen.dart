import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawquest/services/forum_service.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  final String authorName;
  final String content;
  final Timestamp timestamp;

  PostDetailScreen({
    required this.postId,
    required this.authorName,
    required this.content,
    required this.timestamp,
  });

  final TextEditingController _commentController = TextEditingController();
  final ForumService _forum = ForumService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Post Detail"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/forum_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.white.withOpacity(0.85),
            child: Column(
              children: [
                // 显示原帖内容
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          authorName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(content),
                        SizedBox(height: 4),
                        Text(
                          timestamp.toDate().toString().substring(0, 16),
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .snapshots(),
                          builder: (context, snap) {
                            final data =
                                snap.data?.data() as Map<String, dynamic>?;
                            final liked = data != null &&
                                _forum.isLikedBy(data, user?.uid);
                            final likes =
                                data != null ? _forum.likeCount(data) : 0;
                            return Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        liked ? Colors.redAccent : Colors.grey,
                                  ),
                                  onPressed: user == null
                                      ? null
                                      : () => _forum.togglePostLike(postId),
                                ),
                                const SizedBox(width: 4),
                                Text('$likes'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(),

                // 显示评论列表
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final comments = snapshot.data!.docs;

                      if (comments.isEmpty) {
                        return Center(child: Text('No Comments'));
                      }

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final commentDoc = comments[index];
                          final comment = commentDoc.data() as Map<String, dynamic>;
                          final isAuthor = user != null && user.uid == comment['authorId'];

                          return GestureDetector(
                            onLongPress: isAuthor
                                ? () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Delete'),
                                        content: Text('Delete this comment?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('posts')
                                          .doc(postId)
                                          .collection('comments')
                                          .doc(commentDoc.id)
                                          .delete();
                                    }
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        comment['authorName'] ?? 'Unknown User',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        comment['timestamp'] != null
                                            ? comment['timestamp']
                                                .toDate()
                                                .toString()
                                                .substring(5, 16)
                                            : '',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(comment['content'] ?? ''),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // 添加评论输入框
              Container(
  margin: const EdgeInsets.only(bottom: 50), // 👈 往上移动 20px
  child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Start a conversation...',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () async {
            final text = _commentController.text.trim();
            if (text.isNotEmpty && user != null) {
              await _forum.addComment(postId, text);
              _commentController.clear();
            }
          },
        ),
      ],
    ),
  ),
),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
