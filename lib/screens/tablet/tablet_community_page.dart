import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/responsive.dart';

class TabletCommunityPage extends StatefulWidget {
  const TabletCommunityPage({super.key});

  @override
  State<TabletCommunityPage> createState() => _TabletCommunityPageState();
}

class _TabletCommunityPageState extends State<TabletCommunityPage> {
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedPost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Community Talk',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load posts.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snapshot.data!.docs;
                if (posts.isEmpty) {
                  return const Center(child: Text('No posts yet.'));
                }

                final selected = _selectedPost;
                final landscape = Responsive.isLandscape(context);

                return Row(
                  children: [
                    SizedBox(
                      width: 340,
                      child: Card(
                        child: ListView.separated(
                          itemCount: posts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            final data = post.data();
                            final isSelected = post.id == selected?.id;
                            return ListTile(
                              selected: isSelected,
                              title: Text(data['authorName'] ?? 'Anonymous'),
                              subtitle: Text(
                                data['content'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                setState(() => _selectedPost = post);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: selected == null
                          ? const Card(
                              child: Center(
                                child: Text('Select a post to view details.'),
                              ),
                            )
                          : landscape
                              ? _CommentsPanel(post: selected)
                              : _PostPreview(post: selected),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPostPanel extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> post;

  const _SelectedPostPanel({required this.post});

  @override
  Widget build(BuildContext context) {
    final data = post.data();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['authorName'] ?? 'Anonymous user',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  data['content'] ?? '',
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostPreview extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> post;

  const _PostPreview({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _SelectedPostPanel(post: post)),
            const Divider(height: 32),
            Text('Comments', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(flex: 3, child: _CommentsList(postId: post.id, limit: 8)),
          ],
        ),
      ),
    );
  }
}

class _CommentsPanel extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> post;

  const _CommentsPanel({required this.post});

  @override
  Widget build(BuildContext context) {
    final data = post.data();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comments', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '${data['authorName'] ?? 'Anonymous user'}: ${data['content'] ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8A715B)),
            ),
            const SizedBox(height: 12),
            Expanded(child: _CommentsList(postId: post.id)),
          ],
        ),
      ),
    );
  }
}

class _CommentsList extends StatelessWidget {
  final String postId;
  final int? limit;

  const _CommentsList({
    required this.postId,
    this.limit,
  });

  @override
  Widget build(BuildContext context) {
    var query = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit!);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Failed to load comments.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final comments = snapshot.data!.docs;
        if (comments.isEmpty) {
          return const Text('No comments yet.');
        }

        return ListView.separated(
          itemCount: comments.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final comment = comments[index].data();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(comment['authorName'] ?? 'Unknown user'),
              subtitle: Text(comment['content'] ?? ''),
            );
          },
        );
      },
    );
  }
}
