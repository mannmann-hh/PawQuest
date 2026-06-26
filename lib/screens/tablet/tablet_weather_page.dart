import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/daily_quest_provider.dart';
import '../../providers/step_provider.dart';

class TabletWeatherPage extends StatefulWidget {
  const TabletWeatherPage({super.key});

  @override
  State<TabletWeatherPage> createState() => _TabletWeatherPageState();
}

class _TabletWeatherPageState extends State<TabletWeatherPage> {
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
    final steps = context.watch<StepProvider>().todaySteps;
    final provider = context.watch<DailyQuestProvider>();
    final weather = provider.weather;
    final quest = provider.quest;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weather Command Center',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              ElevatedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => context.read<DailyQuestProvider>().refresh(steps),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (provider.errorMessage != null)
            Card(
              color: const Color(0xFFFFF1D6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(provider.errorMessage!),
              ),
            ),
          if (provider.isLoading) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final panels = [
                  _WeatherPanel(
                    locationName: weather?.locationName ?? quest?.locationName,
                    temperature: weather?.temperature ?? quest?.temperature,
                    weatherMain: weather?.weatherMain ?? quest?.weatherMain,
                    description: weather?.description,
                    suggestion: weather?.walkingAdvice,
                  ),
                  _QuestImpactPanel(
                    title: quest?.questTitle,
                    description: quest?.questDescription,
                    currentSteps: quest?.currentSteps,
                    goalSteps: quest?.goalSteps,
                    completed: quest?.completed,
                    weatherMain: quest?.weatherMain,
                    temperature: quest?.temperature,
                  ),
                ];

                if (wide) {
                  return Row(
                    children: [
                      Expanded(child: panels[0]),
                      const SizedBox(width: 16),
                      Expanded(child: panels[1]),
                    ],
                  );
                }

                return ListView(
                  children: [
                    SizedBox(height: 320, child: panels[0]),
                    const SizedBox(height: 16),
                    SizedBox(height: 320, child: panels[1]),
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

class _WeatherPanel extends StatelessWidget {
  final String? locationName;
  final double? temperature;
  final String? weatherMain;
  final String? description;
  final String? suggestion;

  const _WeatherPanel({
    this.locationName,
    this.temperature,
    this.weatherMain,
    this.description,
    this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud, size: 48, color: Color(0xFFF77F42)),
            const SizedBox(height: 18),
            Text(
              locationName ?? 'Current location',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              temperature == null
                  ? '-- °C'
                  : '${temperature!.toStringAsFixed(1)} °C',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Text(
              weatherMain ?? 'Weather unavailable',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (description != null) Text(description!),
            const Spacer(),
            Text(
              suggestion ?? 'Refresh to get local walking advice.',
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestImpactPanel extends StatelessWidget {
  final String? title;
  final String? description;
  final int? currentSteps;
  final int? goalSteps;
  final bool? completed;
  final String? weatherMain;
  final double? temperature;

  const _QuestImpactPanel({
    this.title,
    this.description,
    this.currentSteps,
    this.goalSteps,
    this.completed,
    this.weatherMain,
    this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    if (title == null || goalSteps == null || currentSteps == null) {
      return const Card(
        child: Center(child: Text('Daily Quest is not ready yet.')),
      );
    }

    final progress = goalSteps == 0 ? 0.0 : currentSteps! / goalSteps!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title!, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(description ?? ''),
            const SizedBox(height: 16),
            Text(
              'Generated from: ${weatherMain ?? 'fallback'}'
              '${temperature == null ? '' : ' · ${temperature!.toStringAsFixed(1)} °C'}',
            ),
            const Spacer(),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 16,
            ),
            const SizedBox(height: 12),
            Text('$currentSteps / $goalSteps steps'),
            Text(
              completed == true ? 'Completed' : 'In progress',
              style: TextStyle(
                color: completed == true ? Colors.green : Colors.brown,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
