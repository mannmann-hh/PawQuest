import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/step_provider.dart';
import '../services/route_manager.dart';
import 'city_detail_screen.dart';
import 'main_screen.dart';
import 'package:google_fonts/google_fonts.dart';

Widget roundedButton({
  required String label,
  required VoidCallback onPressed,
}) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(padding: EdgeInsets.zero),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF546E7A),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

/// WorldMapScreen Stateful Widget
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({Key? key}) : super(key: key);

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  List<Map<String, dynamic>> unlockedCities = [];

  @override
  void initState() {
    super.initState();
    _loadUnlockedCities();
  }

  Future<void> _loadUnlockedCities() async {
    final stepProvider = Provider.of<StepProvider>(context, listen: false);
    final cities = await RouteManager().loadUnlockedCities(stepProvider.steps);
    setState(() {
      unlockedCities = cities;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          /// 背景地图
          Positioned.fill(
            child: Image.asset(
              'assets/images/Italymap.png',
              fit: BoxFit.cover,
            ),
          ),

          /// 城市徽章标记
          ...unlockedCities.map((city) {
            debugPrint('$city');
            double x = city['x'] / 1000 * screenWidth;
            double y = city['y'] / 1000 * screenHeight;

            return Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                onTap: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: '',
                    barrierColor: Colors.black.withOpacity(0.2), // 半透明背景
                    pageBuilder: (_, __, ___) => const SizedBox(),
                    transitionBuilder: (_, anim, __, child) {
                      return Transform.scale(
                        scale: anim.value,
                        child: Opacity(
                          opacity: anim.value,
                          child: Center(
                            child: Container(
                              width: 300,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "You have unlocked the city:",
                                    style: GoogleFonts.baloo2(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.brown,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    city['name'],
                                    style: GoogleFonts.baloo2(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // 🔥 勋章图案
                                  Image.asset(
                                    'assets/images/badges/${city['badge']}',
                                    width: 200,
                                  ),

                                  const SizedBox(height: 20),

                                  roundedButton(
                                    label: 'View details',
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CityDetailScreen(
                                            cityName: city['name'],
                                            badgeImagePath:
                                                'assets/images/badges/${city['badge']}',
                                            stepRequired: city['stepRequired'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Image.asset(
                  'assets/images/badges/${city['badge']}',
                  width: 40,
                ),
              ),
            );
          }).toList(),

          /// 底部按钮组
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                roundedButton(
                  label: 'Home',
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MainScreen(initialIndex: 0)),
                      (route) => false,
                    );
                  },
                ),
                roundedButton(
                  label: 'Gourmet Food',
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const MainScreen(initialIndex: 1)),
                        (route) => false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
