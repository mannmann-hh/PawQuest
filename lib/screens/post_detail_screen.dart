import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawquest/services/forum_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String authorName;
  final String content;
  final Timestamp timestamp;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.authorName,
    required this.content,
    required this.timestamp,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ForumService _forum = ForumService();

  // Active reply target; all null = writing a new top-level comment.
  String? _replyingToId; // the comment/reply being answered
  String? _replyingToName;
  String? _replyingToAuthorId;
  String? _replyingRootId; // the thread root (top-level comment id)

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _startReply({
    required String commentId,
    required String name,
    required String authorId,
    required String rootId,
  }) {
    setState(() {
      _replyingToId = commentId;
      _replyingToName = name;
      _replyingToAuthorId = authorId;
      _replyingRootId = rootId;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
      _replyingToAuthorId = null;
      _replyingRootId = null;
    });
  }

  Future<void> _send() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || FirebaseAuth.instance.currentUser == null) return;
    await _forum.addComment(
      widget.postId,
      text,
      parentId: _replyingToId,
      parentAuthorId: _replyingToAuthorId,
      parentName: _replyingToName,
      rootId: _replyingRootId,
    );
    _commentController.clear();
    _cancelReply();
  }

  Future<void> _confirmDelete(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Delete this comment?'),
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
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Detail"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
            color: Colors.white.withValues(alpha: 0.85),
            child: Column(
              children: [
                // ---------------- Original post ----------------
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.content),
                        const SizedBox(height: 4),
                        Text(
                          widget.timestamp.toDate().toString().substring(0, 16),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('posts')
                              .doc(widget.postId)
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
                                      : () =>
                                          _forum.togglePostLike(widget.postId),
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
                const Divider(),

                // ---------------- Comments (threaded) ----------------
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .collection('comments')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text('No Comments'));
                      }

                      // Top-level comments vs. replies grouped by thread root.
                      // Old replies (pre-rootId) fall back to parentId as root.
                      final topLevel = <QueryDocumentSnapshot>[];
                      final repliesByRoot =
                          <String, List<QueryDocumentSnapshot>>{};
                      for (final d in docs) {
                        final data = d.data() as Map<String, dynamic>;
                        final parentId = data['parentId'] as String?;
                        if (parentId == null) {
                          topLevel.add(d);
                        } else {
                          final root =
                              (data['rootId'] as String?) ?? parentId;
                          repliesByRoot.putIfAbsent(root, () => []).add(d);
                        }
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: topLevel.length,
                        itemBuilder: (context, index) {
                          final root = topLevel[index];
                          final replies = repliesByRoot[root.id] ?? const [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildComment(root, user,
                                  isReply: false, rootId: root.id),
                              for (final reply in replies)
                                _buildComment(reply, user,
                                    isReply: true, rootId: root.id),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                // ---------------- Reply banner + input ----------------
                if (_replyingToId != null)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFDEFD6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Replying to ${_replyingToName ?? ''}',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF6B4F3A)),
                          ),
                        ),
                        GestureDetector(
                          onTap: _cancelReply,
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(bottom: 50),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: _replyingToId == null
                                  ? 'Start a conversation...'
                                  : 'Write a reply...',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _send,
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

  Widget _buildComment(
    QueryDocumentSnapshot doc,
    User? user, {
    required bool isReply,
    required String rootId,
  }) {
    final comment = doc.data() as Map<String, dynamic>;
    final authorName = comment['authorName'] ?? 'Unknown User';
    final replyToName = comment['replyToName'] as String?;
    final isAuthor = user != null && user.uid == comment['authorId'];
    final ts = comment['timestamp'];
    final timeLabel =
        ts is Timestamp ? ts.toDate().toString().substring(5, 16) : '';

    return GestureDetector(
      onLongPress: isAuthor ? () => _confirmDelete(doc.id) : null,
      child: Container(
        margin: EdgeInsets.only(left: isReply ? 32 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: isReply
            ? const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFFE0C9A6), width: 2),
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  authorName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  timeLabel,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            // Mention line so people can see who a reply addresses.
            if (isReply && replyToName != null && replyToName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '↳ $replyToName',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9C7B53)),
                ),
              ),
            const SizedBox(height: 4),
            Text(comment['content'] ?? ''),
            // Every comment and reply can be answered, so conversation can
            // continue indefinitely (all kept one level deep under the root).
            if (user != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _startReply(
                    commentId: doc.id,
                    name: authorName,
                    authorId: comment['authorId'] ?? '',
                    rootId: rootId,
                  ),
                  child: const Text('Reply',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFF6B4F3A))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
