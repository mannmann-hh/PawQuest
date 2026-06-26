import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/step_provider.dart';
import '../../services/wiki_city_service.dart';

class TabletBadgePage extends StatefulWidget {
  const TabletBadgePage({super.key});

  @override
  State<TabletBadgePage> createState() => _TabletBadgePageState();
}

class _TabletBadgePageState extends State<TabletBadgePage> {
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedCity;

  @override
  Widget build(BuildContext context) {
    final totalSteps = context.watch<StepProvider>().steps;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Badge Wall', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('cities')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load badges.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final cities = snapshot.data!.docs;
                if (cities.isEmpty) {
                  return const Center(child: Text('No badges configured.'));
                }

                final selected = _selectedCity;

                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 720 ? 4 : 3;
                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              childAspectRatio: 0.9,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                            ),
                            itemCount: cities.length,
                            itemBuilder: (context, index) {
                              final doc = cities[index];
                              final city = doc.data();
                              final required =
                                  (city['stepRequired'] as num?)?.toInt() ?? 0;
                              final unlocked = totalSteps >= required;
                              final name =
                                  city['name']?.toString() ?? 'Unknown';
                              final badge = city['badge']?.toString() ?? '';
                              final isSelected = selected?.id == doc.id;

                              return InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () =>
                                    setState(() => _selectedCity = doc),
                                child: Card(
                                  color: isSelected
                                      ? const Color(0xFFFFF1D6)
                                      : Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Opacity(
                                            opacity: unlocked ? 1 : 0.22,
                                            child: Image.asset(
                                              'assets/images/badges/$badge',
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.emoji_events,
                                                size: 60,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          unlocked
                                              ? 'Unlocked'
                                              : '$required steps',
                                          style: TextStyle(
                                            color: unlocked
                                                ? Colors.green
                                                : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 2,
                      child: _BadgeDetailPanel(
                        selectedCity: selected,
                        totalSteps: totalSteps,
                      ),
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

class _BadgeDetailPanel extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>>? selectedCity;
  final int totalSteps;

  const _BadgeDetailPanel({
    required this.selectedCity,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCity == null) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Select a badge to view city details.'),
          ),
        ),
      );
    }

    final city = selectedCity!.data();
    final name = city['name']?.toString() ?? 'Unknown';
    final badge = city['badge']?.toString() ?? '';
    final required = (city['stepRequired'] as num?)?.toInt() ?? 0;
    final unlocked = totalSteps >= required;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Opacity(
                opacity: unlocked ? 1 : 0.28,
                child: Image.asset(
                  'assets/images/badges/$badge',
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '$name Explorer',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(unlocked ? 'Unlocked' : 'Locked until $required steps'),
            const Divider(height: 28),
            Expanded(
              child: unlocked
                  ? FutureBuilder<WikiCityInfo>(
                      future: WikiCityService().fetchCityInfo(name),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text(
                            'City knowledge is temporarily unavailable.',
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final info = snapshot.data!;
                        return ListView(
                          children: [
                            if (info.city.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  info.city.imageUrl!,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 14),
                            Text(
                              info.city.extract,
                              style: const TextStyle(height: 1.35),
                            ),
                            if (info.landmark != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                'Landmark: ${info.landmark!.title}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                info.landmark!.extract,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        );
                      },
                    )
                  : Text(
                      'Keep walking to unlock the $name badge and reveal its city story.',
                      style: const TextStyle(height: 1.4),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
