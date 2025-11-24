import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          /// ⭐ 固定背景图（和 Food Journey 一样）
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

                /// ⭐ 这里替换成你的 talk.png 标题图片
                Image.asset(
                  "assets/images/title/talk.png",
                  height: 120,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 10),

                /// ⭐ 主体内容（帖子列表）
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final posts = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final postData = posts[index].data() as Map<String, dynamic>;
                          final postId = posts[index].id;
                          final isAuthor = currentUser != null &&
                              currentUser.uid == postData['authorId'];

                          return ListTile(
                            title: Text(
                              postData['authorName'] ?? 'Anonymous user',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFF6B4F3A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              postData['content'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: Text(
                              postData['timestamp']?.toDate().toString().substring(0, 16) ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),

                            /// ⭐ 跳转帖子详情
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailScreen(
                                    postId: postId,
                                    authorName: postData['authorName'] ?? 'Anonymous user',
                                    content: postData['content'] ?? '',
                                    timestamp: postData['timestamp'],
                                  ),
                                ),
                              );
                            },

                            /// ⭐ 长按删除（作者可删）
                            onLongPress: isAuthor
                                ? () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirm Delete'),
                                        content: const Text(
                                            'Do you really want to delete this post?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('posts')
                                          .doc(postId)
                                          .delete();
                                    }
                                  }
                                : null,
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

      /// ⭐ 创建帖子按钮（上移以避免挡住导航栏）
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: Colors.amberAccent,
          child: const Icon(Icons.add, color: Colors.brown),
          onPressed: () {
            _showPostDialog(context);
          },
        ),
      ),
    );
  }

  void _showPostDialog(BuildContext context) {
    final _controller = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Post'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: 'Add a comment...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = _controller.text.trim();
              if (content.isNotEmpty && user != null) {
                await FirebaseFirestore.instance.collection('posts').add({
                  'authorId': user.uid,
                  'authorName': user.displayName ?? 'Anonymous user',
                  'content': content,
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }
              
              Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}
