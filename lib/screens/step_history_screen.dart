import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class StepHistoryScreen extends StatelessWidget {
  const StepHistoryScreen({super.key});

  static const Color _cream = Color(0xFFFFF6EB);
  static const Color _yellow = Color(0xFFF8D66D);
  static const Color _orange = Color(0xFFF77F42);
  static const Color _brown = Color(0xFF6B4F3A);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in first")),
      );
    }

    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('step_history')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text(
          'Step History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _yellow,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: historyRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Oldest -> newest
          final docs = snapshot.data!.docs.reversed.toList();
          if (docs.isEmpty) {
            return _emptyState();
          }

          // ---- summary stats over all history ----
          int total = 0;
          int best = 0;
          for (final d in docs) {
            final daily = _daily(d);
            total += daily;
            if (daily > best) best = daily;
          }
          final activeDays = docs.length;
          final avg = activeDays == 0 ? 0 : (total / activeDays).round();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryGrid(total: total, avg: avg, best: best, days: activeDays),
              const SizedBox(height: 20),
              _sectionTitle('Last 7 days'),
              const SizedBox(height: 12),
              _chartCard(docs),
              const SizedBox(height: 24),
              _sectionTitle('Daily details'),
              const SizedBox(height: 12),
              // newest first in the list
              ...docs.reversed.map(_buildStepCard),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------- helpers

  int _daily(QueryDocumentSnapshot doc) {
    final raw = (doc.data() as Map<String, dynamic>)['daily'];
    return raw is num ? raw.toInt() : 0;
  }

  String _comma(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _axisLabel(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return k == k.roundToDouble()
          ? '${k.toInt()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return v.toInt().toString();
  }

  /// A "nice" tick step (1/2/2.5/5 × 10^n) for ~5 ticks.
  double _niceStep(double maxVal, {int ticks = 5}) {
    if (maxVal <= 0) return 1000;
    final rough = maxVal / ticks;
    final mag = pow(10, (log(rough) / ln10).floor()).toDouble();
    final norm = rough / mag;
    double nice;
    if (norm <= 1) {
      nice = 1;
    } else if (norm <= 2) {
      nice = 2;
    } else if (norm <= 2.5) {
      nice = 2.5;
    } else if (norm <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * mag;
  }

  // ----------------------------------------------------------------- widgets

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _brown,
        ),
      );

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_walk_rounded,
              size: 56, color: _orange.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          const Text(
            'No steps recorded yet',
            style: TextStyle(fontSize: 16, color: _brown),
          ),
          const SizedBox(height: 4),
          Text(
            'Start walking and your history will appear here.',
            style: TextStyle(fontSize: 13, color: _brown.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid({
    required int total,
    required int avg,
    required int best,
    required int days,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(Icons.functions_rounded, 'Total steps',
                  _comma(total), _orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(Icons.trending_up_rounded, 'Daily average',
                  _comma(avg), _orange),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                  Icons.emoji_events_rounded, 'Best day', _comma(best), _orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(Icons.calendar_month_rounded, 'Active days',
                  '$days', _orange),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: _brown.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _brown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(List<QueryDocumentSnapshot> docs) {
    // last 7 days, oldest -> newest
    final last7 = docs.length <= 7 ? docs : docs.sublist(docs.length - 7);

    double maxVal = 0;
    for (final d in last7) {
      maxVal = max(maxVal, _daily(d).toDouble());
    }
    final interval = _niceStep(maxVal);
    double maxY = (maxVal / interval).ceil() * interval;
    if (maxY <= maxVal) maxY += interval; // headroom so the top bar isn't clipped
    if (maxY <= 0) maxY = interval;

    final barGroups = <BarChartGroupData>[];
    final dateLabels = <String>[];
    for (int i = 0; i < last7.length; i++) {
      final daily = _daily(last7[i]).toDouble();
      final isLatest = i == last7.length - 1;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: daily,
              width: 22,
              color: isLatest ? _orange : _yellow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: _yellow.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      );
      final date = (last7[i].data() as Map<String, dynamic>)['date'] ?? '';
      dateLabels.add(date is String && date.length >= 5 ? date.substring(5) : '');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 18, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: SizedBox(
        height: 240,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            barGroups: barGroups,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) => const FlLine(
                color: Color(0xFFEEE2C8),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
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
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        dateLabels[index],
                        style: const TextStyle(fontSize: 10, color: _brown),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  reservedSize: 38,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox();
                    return Text(
                      _axisLabel(value),
                      style: const TextStyle(fontSize: 10, color: _brown),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final daily = _daily(doc);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _yellow.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_walk_rounded,
                size: 20, color: _orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              data['date'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _brown,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '${_comma(daily)} steps',
            style: const TextStyle(
              fontSize: 15,
              color: _brown,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
