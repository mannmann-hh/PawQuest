import 'package:flutter/material.dart';

import '../services/wiki_city_service.dart';

class CityDetailScreen extends StatelessWidget {
  final String cityName;
  final String badgeImagePath;
  final int stepRequired;

  const CityDetailScreen({
    super.key,
    required this.cityName,
    required this.badgeImagePath,
    required this.stepRequired,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$cityName Explorer'),
      ),
      body: FutureBuilder<WikiCityInfo>(
        future: WikiCityService().fetchCityInfo(cityName),
        builder: (context, snapshot) {
          final info = snapshot.data;
          final cityImage = info?.city.imageUrl;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              _BadgeHeader(
                cityName: cityName,
                badgeImagePath: badgeImagePath,
                stepRequired: stepRequired,
                cityImageUrl: cityImage,
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                _InfoSection(
                  title: 'City Description',
                  body:
                      'Wikipedia content is temporarily unavailable. You still unlocked the $cityName Explorer badge by walking $stepRequired steps.',
                )
              else ...[
                _InfoSection(
                  title: 'City Description',
                  body: info!.city.extract,
                ),
                if (info.landmark != null)
                  _InfoSection(
                    title: 'Landmark: ${info.landmark!.title}',
                    body: info.landmark!.extract,
                  ),
                if (info.history != null)
                  _InfoSection(
                    title: 'History',
                    body: info.history!.extract,
                  ),
              ],
              const SizedBox(height: 12),
              Text(
                'Content dynamically retrieved from Wikipedia / Wikimedia REST API.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.brown.withValues(alpha: 0.65),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BadgeHeader extends StatelessWidget {
  final String cityName;
  final String badgeImagePath;
  final int stepRequired;
  final String? cityImageUrl;

  const _BadgeHeader({
    required this.cityName,
    required this.badgeImagePath,
    required this.stepRequired,
    this.cityImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cityImageUrl != null)
            Image.network(
              cityImageUrl!,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Image.asset(
                  badgeImagePath,
                  width: 96,
                  height: 96,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Badge: $cityName Explorer',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('City: $cityName'),
                      Text('Unlocked by: $stepRequired steps'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String body;

  const _InfoSection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
