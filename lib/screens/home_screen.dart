import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/providers/step_provider.dart';
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

  // ⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐
  // 这里是我唯一添加的代码，其余一行都没动
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 从 Firestore 读取步数并更新 Provider
      await _loadStepsAndUpdateProvider(context);

      // 开始步数监听
      final sp = Provider.of<StepProvider>(context, listen: false);
      sp.startListening();
    });
  }
  // ⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐


  Future<List<City>> loadCities(BuildContext context) async {
    final jsonStr =
        await DefaultAssetBundle.of(context).loadString('assets/config/cities.json');
    print('✅ Loaded cities.json content: $jsonStr');
    final List decoded = jsonDecode(jsonStr);
    return decoded.map((e) => City.fromJson(e)).toList();
  }

  /// 每次进入 HomeScreen 都从 Firestore 重新加载步数到 Provider
  Future<void> _loadStepsAndUpdateProvider(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return;

    final data = doc.data();
    if (data == null) return;

    if (!mounted) return;

    final stepProvider = Provider.of<StepProvider>(context, listen: false);
    stepProvider.setSteps(data['currentStep'] ?? 0);
  }

  @override
  Widget build(BuildContext context) {

    final steps = context.watch<StepProvider>().steps ?? 0;
    final stepProvider = Provider.of<StepProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<List<City>>(
      future: loadCities(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFF6EB),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFF96B29))),
          );
        }

        final cities = snapshot.data!;
        final city = cities.lastWhere(
          (c) => c.stepRequired <= steps,
          orElse: () => cities.first,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFFFF6EB),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  city.backgroundAsset,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                top: 180,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        "assets/images/steps.png",
                        width: 320,
                        fit: BoxFit.contain,
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const SizedBox(height: 8),

                          Text(
                            '$steps',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B3A2E),
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  color: Colors.black26,
                                  offset: Offset(2, 2),
                                )
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const StepHistoryScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF8D66D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.directions_walk),
                            label: const Text(
                              "Daily Steps",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (kDebugMode)
                Positioned(
                  top: 50,
                  left: 20,
                  child: ElevatedButton(
                    onPressed: () => stepProvider.addDebugSteps(1000),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text('+1000 steps'),
                  ),
                ),

              if (user != null)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get(),
                  builder: (context, snapshot) {
                    String catName = 'cat1';
                    if (snapshot.hasData) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      catName = data?['cat'] ?? 'cat1';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          'assets/images/cats/$catName.gif',
                          width: 260,
                          height: 260,
                        ),
                      ),
                    );
                  },
                ),

              Positioned(
                top: 40,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const WorldMapScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/images/icons/custom_earth.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}