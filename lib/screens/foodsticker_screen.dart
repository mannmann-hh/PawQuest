// --------------------------------------------------------------
// Food Sticker Screen (Food Journey 手帐页)
// --------------------------------------------------------------

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/step_provider.dart';


//
// --------------------------------------------------------------
// ① 单个贴纸（胶带 + 图片 + 城市名字）
// --------------------------------------------------------------
//
class FoodSticker extends StatelessWidget {
  final String filename;
  final String cityName;
  final double angle;

  const FoodSticker({
    super.key,
    required this.filename,
    required this.cityName,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        height: 200,      // ⭐ 固定总高度（不会再超出）
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ⭐ 胶带
            Image.asset(
              "assets/images/tape.png",
              width: 50,
              height: 24,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 5),

            // ⭐ 图片区域（使用 Flexible 自动适应）
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(3, 5),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    "assets/images/food/$filename",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ⭐ 城市名字
            Text(
              cityName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B4F3A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}




//
// --------------------------------------------------------------
// ② 单页布局：不重叠的 2×2 网格 + 每个贴纸随机轻微旋转
// --------------------------------------------------------------
//
class FoodPage extends StatelessWidget {
  final List<Map<String, String>> foods;

  const FoodPage({super.key, required this.foods});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 28,
        crossAxisSpacing: 20,
        childAspectRatio: 0.78,
      ),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final item = foods[index];
        final img = item["file"]!;
        final city = item["city"]!;
        final angle = (Random().nextInt(18) - 9) * pi / 180; // -9°~+9°

        return FoodSticker(
          filename: img,
          cityName: city,
          angle: angle,
        );
      },
    );
  }
}



//
// --------------------------------------------------------------
// ③ 主页面 FoodStickerScreen（Food Journey）
// --------------------------------------------------------------
//
class FoodStickerScreen extends StatelessWidget {
  const FoodStickerScreen({super.key});

  // ⭐ Firestore 解锁逻辑：读取 food（图片名）+ name（城市名）
  Future<List<Map<String, String>>> _getUnlockedFoods(int steps) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("cities")
        .orderBy("order")
        .get();

    List<Map<String, String>> foods = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final need = data["stepRequired"];
      final img = data["food"];
      final city = data["name"];

      if (need != null && img != null && city != null && steps >= need) {
        foods.add({"file": img, "city": city});
      }
    }
    return foods;
  }

  @override
  Widget build(BuildContext context) {
    final steps = context.watch<StepProvider>().steps;

    return Scaffold(
      body: Stack(
        children: [
          // ⭐ 背景图
          Positioned.fill(
            child: Image.asset(
              "assets/images/food_bg.jpeg",
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: FutureBuilder<List<Map<String, String>>>(
              future: _getUnlockedFoods(steps),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final foods = snap.data!;
                if (foods.isEmpty) {
                  return const Center(
                    child: Text(
                      "No foods unlocked yet!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    const SizedBox(height: 5),

                    // ⭐ 顶部 Food Journey PNG
                    Image.asset(
                      "assets/images/title/food_journey.png",
                      height: 120,
                      fit: BoxFit.contain,
                    ),

                    Text(
                      "Unlocked Foods: ${foods.length}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.brown,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ⭐ 带翻页动画的 PageView
                    Expanded(
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.92),
                        itemCount: (foods.length / 4).ceil(),
                        itemBuilder: (context, index) {
                          final start = index * 4;
                          final end = min(start + 4, foods.length);
                          final pageFoods = foods.sublist(start, end);

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 450),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(25 * (1 - value), 0),
                                child: Transform.rotate(
                                  angle: (1 - value) * 0.06,
                                  child: child,
                                ),
                              );
                            },
                            child: FoodPage(foods: pageFoods),
                          );
                        },
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
