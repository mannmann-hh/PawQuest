import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/daily_quest_provider.dart';
import '../../providers/step_provider.dart';
import 'tablet_dashboard_screen.dart';

class TabletOverviewPage extends StatefulWidget {
  const TabletOverviewPage({super.key});

  @override
  State<TabletOverviewPage> createState() => _TabletOverviewPageState();
}

class _TabletOverviewPageState extends State<TabletOverviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final steps = context.read<StepProvider>().todaySteps;
      context.read<DailyQuestProvider>().loadTodayQuest(steps);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final stepProvider = context.watch<StepProvider>();
    final questProvider = context.watch<DailyQuestProvider>();

    if (user == null) {
      return const _TabletPageShell(
        title: 'PawQuest Companion',
        child: Center(child: Text('Login to view your dashboard.')),
      );
    }

    return _TabletPageShell(
      title: 'PawQuest Companion',
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return const _StateText('Failed to load user data.');
          }
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = userSnapshot.data!.data() ?? {};
          final nickname = data['nickname']?.toString() ??
              user.displayName ??
              'PawQuest Player';
          final totalSteps =
              (data['currentStep'] as num?)?.toInt() ?? stepProvider.steps;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('cities')
                .orderBy('order')
                .snapshots(),
            builder: (context, citySnapshot) {
              if (citySnapshot.hasError) {
                return const _StateText('Failed to load route progress.');
              }
              if (!citySnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final cities = citySnapshot.data!.docs;
              final unlocked = cities.where((doc) {
                final required =
                    (doc.data()['stepRequired'] as num?)?.toInt() ?? 0;
                return totalSteps >= required;
              }).toList();
              final currentCity = unlocked.isEmpty ? null : unlocked.last;
              QueryDocumentSnapshot<Map<String, dynamic>>? nextCity;
              for (final city in cities) {
                final required =
                    (city.data()['stepRequired'] as num?)?.toInt() ?? 0;
                if (totalSteps < required) {
                  nextCity = city;
                  break;
                }
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 1200 ? 3 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    childAspectRatio: width >= 1200 ? 1.35 : 1.55,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _StepProgressCard(
                        nickname: nickname,
                        todaySteps: stepProvider.todaySteps,
                        totalSteps: totalSteps,
                        currentCity: currentCity?.data()['name']?.toString(),
                        nextCity: nextCity?.data()['name']?.toString(),
                        nextRequired:
                            (nextCity?.data()['stepRequired'] as num?)?.toInt(),
                      ),
                      _QuestCard(provider: questProvider),
                      _WeatherCard(provider: questProvider),
                      _BadgeSummaryCard(
                        unlocked: unlocked,
                        total: cities.length,
                      ),
                      const _LatestPostsCard(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StepProgressCard extends StatelessWidget {
  final String nickname;
  final int todaySteps;
  final int totalSteps;
  final String? currentCity;
  final String? nextCity;
  final int? nextRequired;

  const _StepProgressCard({
    required this.nickname,
    required this.todaySteps,
    required this.totalSteps,
    this.currentCity,
    this.nextCity,
    this.nextRequired,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = nextRequired == null
        ? null
        : (nextRequired! - totalSteps).clamp(0, nextRequired!);

    return _InfoCard(
      title: 'Step Progress',
      icon: Icons.route,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hi, $nickname', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            '$todaySteps',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const Text('steps today'),
          const SizedBox(height: 10),
          Text('Total route steps: $totalSteps'),
          Text('Current city: ${currentCity ?? 'Not unlocked yet'}'),
          Text(
            nextCity == null
                ? 'All cities unlocked'
                : 'Next: $nextCity · $remaining steps remaining',
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final DailyQuestProvider provider;

  const _QuestCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final quest = provider.quest;
    if (provider.isLoading && quest == null) {
      return const _InfoCard(
        title: 'Daily Quest',
        icon: Icons.flag,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (quest == null) {
      return const _InfoCard(
        title: 'Daily Quest',
        icon: Icons.flag,
        child: Text('No quest available yet.'),
      );
    }

    final progress =
        quest.goalSteps == 0 ? 0.0 : quest.currentSteps / quest.goalSteps;

    return _InfoCard(
      title: 'Daily Quest',
      icon: Icons.flag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(quest.questTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(quest.questDescription,
              maxLines: 3, overflow: TextOverflow.ellipsis),
          const Spacer(),
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 8),
          Text('${quest.currentSteps} / ${quest.goalSteps} steps'),
          Text(
            quest.completed ? 'Completed' : 'In progress',
            style: TextStyle(
              color: quest.completed ? Colors.green : Colors.brown,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final DailyQuestProvider provider;

  const _WeatherCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final weather = provider.weather;
    final quest = provider.quest;

    return _InfoCard(
      title: 'Weather',
      icon: Icons.cloud,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weather?.locationName ?? quest?.locationName ?? 'Current location',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            weather == null
                ? '-- °C'
                : '${weather.temperature.toStringAsFixed(1)} °C',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          Text(weather?.weatherMain ?? quest?.weatherMain ?? 'Unavailable'),
          if (weather?.description != null) Text(weather!.description),
          const Spacer(),
          Text(weather?.walkingAdvice ?? 'Weather fallback task is active.'),
        ],
      ),
    );
  }
}

class _BadgeSummaryCard extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> unlocked;
  final int total;

  const _BadgeSummaryCard({
    required this.unlocked,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final latest = unlocked.isEmpty ? null : unlocked.last.data();
    final latestBadge = latest?['badge']?.toString();

    return _InfoCard(
      title: 'Badge Summary',
      icon: Icons.emoji_events,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${unlocked.length} / $total unlocked',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (latest != null) ...[
            const SizedBox(height: 8),
            Text('Latest: ${latest['name']}'),
            if (latestBadge != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset('assets/images/badges/$latestBadge'),
                ),
              ),
          ] else
            const Text('No badges unlocked yet.'),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const TabletDashboardScreen(initialIndex: 1),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Open Badges'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestPostsCard extends StatelessWidget {
  const _LatestPostsCard();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Community Preview',
      icon: Icons.forum,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .limit(3)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text('Failed to load posts.');
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!.docs;
          if (posts.isEmpty) return const Text('No posts yet.');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: posts.map((doc) {
              final post = doc.data();
              final likes = post['likes'] ?? post['likeCount'];
              final comments = post['comments'] ?? post['commentCount'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${post['authorName'] ?? 'Anonymous'}: ${post['content'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (likes != null || comments != null)
                      Text(
                        '${likes ?? 0} likes · ${comments ?? 0} comments',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _TabletPageShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _TabletPageShell({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFF77F42)),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _StateText extends StatelessWidget {
  final String text;

  const _StateText(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text));
  }
}
