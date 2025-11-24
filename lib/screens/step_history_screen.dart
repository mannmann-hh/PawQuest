import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class StepHistoryScreen extends StatelessWidget {
  const StepHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("请先登录")),
      );
    }

    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('step_history')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EB),
      appBar: AppBar(
        title: const Text(
          '每日步数记录',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF8D66D), // 主色
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: historyRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.reversed.toList();

          if (docs.isEmpty) {
            return const Center(child: Text("暂无记录"));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildBarChart(docs),
              const SizedBox(height: 24),

              const Text(
                "每日明细",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4F3A),
                ),
              ),
              const SizedBox(height: 12),

              ...docs.map((doc) => buildStepCard(doc)).toList(),
            ],
          );
        },
      ),
    );
  }

  // -------------------------------
  // ⭐ 折线图：统一主题颜色
  // -------------------------------
Widget buildBarChart(List<QueryDocumentSnapshot> docs) {
  if (docs.isEmpty) {
    return const Center(child: Text("暂无数据可显示图表"));
  }

  // ----------- 1. 取最近 7 天（从旧到新）-----------
  List<QueryDocumentSnapshot> last7 = docs.reversed.take(7).toList();
  last7 = last7.reversed.toList(); // 保证最旧 → 最新

  final List<BarChartGroupData> barGroups = [];
  final List<String> dateLabels = [];

  for (int i = 0; i < last7.length; i++) {
    final data = last7[i].data() as Map<String, dynamic>;
    final daily = (data['daily'] ?? 0).toDouble();
    final date = data['date'] ?? "";

    barGroups.add(
      BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: daily,
            width: 28,
            color: const Color(0xFFF8D66D),
            borderRadius: BorderRadius.circular(8),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100000,
              color: const Color(0xFFF8D66D).withOpacity(0.15),
            ),
          ),
        ],
      ),
    );

    dateLabels.add(date.substring(5)); // 显示 11-19
  }

  return SizedBox(
    height: 350,
    child: BarChart(
      BarChartData(
        maxY: 30000,  // ✔️ 图表最大值
        minY: 0,
        barGroups: barGroups,

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFEEE2C8),
            strokeWidth: 1,
          ),
        ),

        borderData: FlBorderData(show: false),

        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

          // ----------- X 轴 -----------
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dateLabels.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    dateLabels[index],
                    style: const TextStyle(fontSize: 10, color: Colors.brown),
                  ),
                );
              },
            ),
          ),

          // ----------- Y 轴 -----------
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2000,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.brown),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}



  // -------------------------------
  // ⭐ 统一风格的卡片
  // -------------------------------
  Widget buildStepCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Card(
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Color.fromARGB(255, 105, 182, 210)),
        title: Text(
          data['date'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4F3A),
          ),
        ),
        trailing: Text(
          "${data['daily']} 步",
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF6B4F3A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

