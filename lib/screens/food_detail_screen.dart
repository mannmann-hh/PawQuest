import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_palette.dart';

/// Detail page for a single unlocked food. Reads the curated entry from
/// assets/config/food_details.json (keyed by city name) and offers a button
/// that opens the recommended restaurant in Google Maps.
class FoodDetailScreen extends StatefulWidget {
  final String filename; // food image file, e.g. "9Roma.jpeg"
  final String city; // city key, e.g. "Rome"

  const FoodDetailScreen({
    super.key,
    required this.filename,
    required this.city,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  late final Future<Map<String, dynamic>?> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<Map<String, dynamic>?> _loadDetail() async {
    try {
      final raw =
          await rootBundle.loadString('assets/config/food_details.json');
      final Map<String, dynamic> all = jsonDecode(raw);
      final entry = all[widget.city];
      return entry is Map<String, dynamic> ? entry : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openInMaps(String query) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.accent,
        foregroundColor: p.text,
        elevation: 0,
        title: Text(widget.city,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _detailFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final detail = snap.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food image card
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/real_food/${widget.filename}',
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Dish name + city
                Text(
                  detail?['dish'] ?? widget.city,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                      widget.city,
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  detail?['description'] ??
                      'No description available for this food yet.',
                  style: const TextStyle(
                      fontSize: 16, height: 1.5, color: Colors.black87),
                ),
                const SizedBox(height: 24),

                // "Where to try it" card
                if (detail != null) ...[
                  Text(
                    'Where to try it',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEDFc0)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.restaurant,
                                size: 20, color: p.text),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                detail['restaurant'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: p.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((detail['address'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Text(
                              detail['address'],
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: p.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.map),
                            label: const Text('Open in Google Maps'),
                            onPressed: () => _openInMaps(
                              detail['mapsQuery'] ??
                                  '${detail['dish']} ${widget.city}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
