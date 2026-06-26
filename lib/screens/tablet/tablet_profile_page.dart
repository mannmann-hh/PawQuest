import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/daily_quest_provider.dart';
import '../../providers/step_provider.dart';
import '../../utils/responsive.dart';

class TabletProfilePage extends StatelessWidget {
  const TabletProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final steps = context.watch<StepProvider>();
    final quest = context.watch<DailyQuestProvider>().quest;
    final isLandscape = Responsive.isLandscape(context);

    if (user == null) {
      return const Center(child: Text('Login to view your profile.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load profile.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() ?? {};
                final nickname = data['nickname']?.toString() ??
                    user.displayName ??
                    'Unnamed';
                final email = data['email']?.toString() ?? user.email ?? '';
                final cat = data['cat']?.toString() ?? 'cat1';

                final profileCard = _ProfileIdentityCard(
                  nickname: nickname,
                  email: email,
                  cat: cat,
                );
                final statsGrid = _ProfileStatsGrid(
                  userId: user.uid,
                  totalSteps: steps.steps,
                  todaySteps: steps.todaySteps,
                  questCompleted: quest?.completed == true,
                );

                if (isLandscape) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 320, child: profileCard),
                      const SizedBox(width: 18),
                      Expanded(child: statsGrid),
                    ],
                  );
                }

                return ListView(
                  children: [
                    SizedBox(height: 360, child: profileCard),
                    const SizedBox(height: 18),
                    SizedBox(height: 620, child: statsGrid),
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

class _ProfileIdentityCard extends StatelessWidget {
  final String nickname;
  final String email;
  final String cat;

  const _ProfileIdentityCard({
    required this.nickname,
    required this.email,
    required this.cat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 64,
              backgroundImage: AssetImage(
                'assets/images/cats_profile/$cat.jpeg',
              ),
            ),
            const SizedBox(height: 18),
            Text(
              nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                context.read<StepProvider>().disposeListener();
                context.read<StepProvider>().resetSteps();
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatsGrid extends StatelessWidget {
  final String userId;
  final int totalSteps;
  final int todaySteps;
  final bool questCompleted;

  const _ProfileStatsGrid({
    required this.userId,
    required this.totalSteps,
    required this.todaySteps,
    required this.questCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        return GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: columns == 1 ? 2.6 : 1.85,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          children: [
            _StatCard(
              label: 'Total Steps',
              value: '$totalSteps',
              icon: Icons.directions_walk,
            ),
            _StatCard(
              label: 'Today Steps',
              value: '$todaySteps',
              icon: Icons.today,
            ),
            _BadgeCountCard(totalSteps: totalSteps),
            _StatCard(
              label: 'Daily Quest',
              value: questCompleted ? 'Completed' : 'In progress',
              icon: Icons.flag,
            ),
            _UserPostCountCard(userId: userId),
            _CompletedQuestCountCard(userId: userId),
          ],
        );
      },
    );
  }
}

class _BadgeCountCard extends StatelessWidget {
  final int totalSteps;

  const _BadgeCountCard({required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('cities').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _StatCard(
            label: 'Unlocked Badges',
            value: '--',
            icon: Icons.emoji_events,
          );
        }
        final docs = snapshot.data?.docs ?? [];
        final unlocked = docs.where((doc) {
          final required = (doc.data()['stepRequired'] as num?)?.toInt() ?? 0;
          return totalSteps >= required;
        }).length;
        return _StatCard(
          label: 'Unlocked Badges',
          value: '$unlocked / ${docs.length}',
          icon: Icons.emoji_events,
        );
      },
    );
  }
}

class _UserPostCountCard extends StatelessWidget {
  final String userId;

  const _UserPostCountCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        return _StatCard(
          label: 'Community Posts',
          value: '${snapshot.data?.docs.length ?? 0}',
          icon: Icons.forum,
        );
      },
    );
  }
}

class _CompletedQuestCountCard extends StatelessWidget {
  final String userId;

  const _CompletedQuestCountCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('dailyQuests')
          .snapshots(),
      builder: (context, snapshot) {
        final completed = snapshot.data?.docs
                .where((doc) => doc.data()['completed'] == true)
                .length ??
            0;
        return _StatCard(
          label: 'Completed Quests',
          value: '$completed',
          icon: Icons.check_circle,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: const Color(0xFFF77F42)),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
