import 'dart:convert';

import 'package:http/http.dart' as http;

class WikiSummary {
  final String title;
  final String extract;
  final String? imageUrl;
  final String? pageUrl;

  const WikiSummary({
    required this.title,
    required this.extract,
    this.imageUrl,
    this.pageUrl,
  });

  factory WikiSummary.fromJson(Map<String, dynamic> json) {
    return WikiSummary(
      title: json['title']?.toString() ?? '',
      extract: json['extract']?.toString() ?? '',
      imageUrl: json['thumbnail']?['source']?.toString() ??
          json['originalimage']?['source']?.toString(),
      pageUrl: json['content_urls']?['desktop']?['page']?.toString(),
    );
  }
}

class WikiCityInfo {
  final WikiSummary city;
  final WikiSummary? landmark;
  final WikiSummary? history;

  const WikiCityInfo({
    required this.city,
    this.landmark,
    this.history,
  });
}

class WikiCityService {
  static const _baseUrl = 'https://en.wikipedia.org/api/rest_v1/page/summary';

  static const Map<String, String> _cityPages = {
    'Como': 'Como',
    'Milan': 'Milan',
    'Turin': 'Turin',
    'Genova': 'Genoa',
    'Pisa': 'Pisa',
    'Venice': 'Venice',
    'Florence': 'Florence',
    'Bologna': 'Bologna',
    'SanMarino': 'San Marino',
    'Rome': 'Rome',
    'Abruzzo': 'Abruzzo',
    'Naples': 'Naples',
    'Caserta': 'Caserta',
    'AmalfiCoast': 'Amalfi Coast',
    'Sicily': 'Sicily',
    'Sardegna': 'Sardinia',
  };

  static const Map<String, String> _landmarkPages = {
    'Como': 'Como Cathedral',
    'Milan': 'Milan Cathedral',
    'Turin': 'Mole Antonelliana',
    'Genova': 'Palazzi dei Rolli',
    'Pisa': 'Leaning Tower of Pisa',
    'Venice': 'St Mark\'s Basilica',
    'Florence': 'Florence Cathedral',
    'Bologna': 'Two Towers, Bologna',
    'SanMarino': 'Guaita',
    'Rome': 'Colosseum',
    'Abruzzo': 'Gran Sasso d\'Italia',
    'Naples': 'Castel Nuovo',
    'Caserta': 'Royal Palace of Caserta',
    'AmalfiCoast': 'Amalfi Coast',
    'Sicily': 'Valley of the Temples',
    'Sardegna': 'Nuraghe Su Nuraxi',
  };

  static const Map<String, String> _historyPages = {
    'Como': 'History of Como',
    'Milan': 'History of Milan',
    'Turin': 'History of Turin',
    'Genova': 'History of Genoa',
    'Pisa': 'History of Pisa',
    'Venice': 'History of the Republic of Venice',
    'Florence': 'History of Florence',
    'Bologna': 'History of Bologna',
    'SanMarino': 'History of San Marino',
    'Rome': 'History of Rome',
    'Abruzzo': 'History of Abruzzo',
    'Naples': 'History of Naples',
    'Caserta': 'Caserta',
    'AmalfiCoast': 'Amalfi Coast',
    'Sicily': 'History of Sicily',
    'Sardegna': 'History of Sardinia',
  };

  final http.Client _client;

  WikiCityService({http.Client? client}) : _client = client ?? http.Client();

  Future<WikiCityInfo> fetchCityInfo(String cityName) async {
    final cityPage = _cityPages[cityName] ?? cityName;
    final landmarkPage = _landmarkPages[cityName];
    final historyPage = _historyPages[cityName];

    final city = await _fetchSummary(cityPage);
    final landmark =
        landmarkPage == null ? null : await _tryFetch(landmarkPage);
    final history = historyPage == null ? null : await _tryFetch(historyPage);

    return WikiCityInfo(
      city: city,
      landmark: landmark,
      history: history,
    );
  }

  Future<WikiSummary?> _tryFetch(String pageTitle) async {
    try {
      return await _fetchSummary(pageTitle);
    } catch (_) {
      return null;
    }
  }

  Future<WikiSummary> _fetchSummary(String pageTitle) async {
    final uri = Uri.parse('$_baseUrl/${Uri.encodeComponent(pageTitle)}');
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'PawQuest/1.0 (student project)',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Wikipedia request failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return WikiSummary.fromJson(json);
  }
}
