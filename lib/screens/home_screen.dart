import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/providers/step_provider.dart';
import 'package:pawquest/providers/daily_quest_provider.dart';
import 'world_map_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawquest/screens/step_history_screen.dart';

class City {
  final String name;
  final int stepRequired;
  final String backgroundAsset;

  City({
    required this.name,
    required this.stepRequired,
    required this.backgroundAsset,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'],
      stepRequired: json['stepRequired'],
      backgroundAsset: json['backgroundAsset'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Brand palette
  static const Color _cream = Color(0xFFFFF6EB);
  static const Color _yellow = Color(0xFFF8D66D);
  static const Color _orange = Color(0xFFF77F42);
  static const Color _brown = Color(0xFF6C4A2F);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadStepsAndUpdateProvider(context);
      if (!mounted) return;

      final sp = Provider.of<StepProvider>(context, listen: false);
      sp.startListening();

      // Kick off the weather/location load once so the home chips can fill in.
      final dq = context.read<DailyQuestProvider>();
      if (dq.weather == null && !dq.isLoading) {
        dq.loadTodayQuest(sp.todaySteps);
      }
    });
  }

  Future<List<City>> loadCities(BuildContext context) async {
    final jsonStr = await DefaultAssetBundle.of(context)
        .loadString('assets/config/cities.json');
    final List decoded = jsonDecode(jsonStr);
    return decoded.map((e) => City.fromJson(e)).toList();
  }

  Future<void> _loadStepsAndUpdateProvider(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final stepProvider = Provider.of<StepProvider>(context, listen: false);
    await stepProvider.loadSavedSteps();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _dateLabel() {
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final n = DateTime.now();
    return '${wd[n.weekday - 1]}, ${mo[n.month - 1]} ${n.day}';
  }

  IconData _weatherIcon(String? main) {
    switch (main) {
      case 'Clear':
        return Icons.wb_sunny_rounded;
      case 'Clouds':
        return Icons.cloud_rounded;
      case 'Rain':
      case 'Drizzle':
        return Icons.water_drop_rounded;
      case 'Thunderstorm':
        return Icons.bolt_rounded;
      case 'Snow':
        return Icons.ac_unit_rounded;
      default:
        return Icons.cloud_queue_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = context.watch<StepProvider>().steps;
    final stepProvider = Provider.of<StepProvider>(context, listen: false);
    final weather = context.watch<DailyQuestProvider>().weather;
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<List<City>>(
      future: loadCities(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: _cream,
            body: Center(
                child: CircularProgressIndicator(color: _orange)),
          );
        }

        final cities = snapshot.data!;
        final current = cities.lastWhere(
          (c) => c.stepRequired <= steps,
          orElse: () => cities.first,
        );
        City? next;
        for (final c in cities) {
          if (c.stepRequired > steps) {
            next = c;
            break;
          }
        }

        double progress;
        int remaining;
        if (next == null) {
          progress = 1.0;
          remaining = 0;
        } else {
          final span = next.stepRequired - current.stepRequired;
          progress = span <= 0
              ? 1.0
              : ((steps - current.stepRequired) / span).clamp(0.0, 1.0);
          remaining = next.stepRequired - steps;
        }

        return Scaffold(
          backgroundColor: _cream,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(current.backgroundAsset, fit: BoxFit.cover),
              ),

              // Cat illustration (kept) at the bottom
              if (user != null)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get(),
                  builder: (context, snap) {
                    String catName = 'cat1';
                    if (snap.hasData) {
                      final data = snap.data!.data() as Map<String, dynamic>?;
                      catName = data?['cat'] ?? 'cat1';
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 96),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          'assets/images/cats/$catName.gif',
                          width: 220,
                          height: 220,
                        ),
                      ),
                    );
                  },
                ),

              // Foreground content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      _topBar(context),
                      const SizedBox(height: 12),
                      _infoChips(weather),
                      const SizedBox(height: 18),
                      _heroCard(
                        steps: steps,
                        progress: progress,
                        remaining: remaining,
                        next: next,
                        current: current,
                      ),
                    ],
                  ),
                ),
              ),

              if (kDebugMode)
                Positioned(
                  top: 48,
                  left: 18,
                  child: Opacity(
                    opacity: 0.85,
                    child: TextButton(
                      onPressed: () => stepProvider.addDebugSteps(1000),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text('+1000', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------- pieces

  Widget _topBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _brown,
                  shadows: [
                    Shadow(color: Colors.white70, blurRadius: 6),
                  ],
                ),
              ),
              Text(
                _dateLabel(),
                style: TextStyle(
                  fontSize: 13,
                  color: _brown.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Map entry — compact, rounded button (replaces the big earth image)
        Material(
          color: Colors.white.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          elevation: 3,
          shadowColor: Colors.black26,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorldMapScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/icons/custom_earth.png',
                width: 40,
                height: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoChips(dynamic weather) {
    final location = weather?.locationName ?? 'Locating…';
    final temp =
        weather != null ? '${(weather.temperature as double).round()}°C' : '—';
    return Row(
      children: [
        _chip(Icons.place_rounded, location),
        const SizedBox(width: 10),
        _chip(_weatherIcon(weather?.weatherMain), temp),
      ],
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _orange),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _brown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard({
    required int steps,
    required double progress,
    required int remaining,
    required City? next,
    required City current,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_rounded, size: 16, color: _orange),
              const SizedBox(width: 5),
              Text(
                'Now exploring ${current.name}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _brown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 188,
            height: 188,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 188,
                  height: 188,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    backgroundColor: _cream,
                    valueColor: const AlwaysStoppedAnimation(_orange),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$steps',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: _brown,
                      ),
                    ),
                    Text(
                      'total steps',
                      style: TextStyle(
                        fontSize: 13,
                        color: _brown.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _nextUnlock(next, remaining),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StepHistoryScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _brown,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.directions_walk_rounded),
              label: const Text('Daily steps'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextUnlock(City? next, int remaining) {
    if (next == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _yellow.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration_rounded, size: 16, color: _orange),
            SizedBox(width: 6),
            Text(
              'All cities unlocked!',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _brown,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 16, color: _orange),
          const SizedBox(width: 6),
          Text(
            '$remaining steps to unlock ${next.name}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _brown,
            ),
          ),
        ],
      ),
    );
  }
}
