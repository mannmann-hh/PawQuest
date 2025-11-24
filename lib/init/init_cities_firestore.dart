import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> uploadCitiesToFirestore() async {
  try {
    final jsonString = await rootBundle.loadString('assets/config/cities.json');
    final List<dynamic> cityList = jsonDecode(jsonString);

    for (final cityData in cityList) {
      if (cityData is! Map<String, dynamic>) continue;

      final cityKey = cityData['name'].toString().toLowerCase();

      await FirebaseFirestore.instance
          .collection('cities')
          .doc(cityKey)
          .set({
        'name': cityData['name'],
        'stepRequired': cityData['stepRequired'],
        'badge': cityData['badge'],
        'order': cityData['order'],
        'x': cityData['x'],
        'y': cityData['y'],
      }, SetOptions(merge: true));

      print('✅ 上传成功: $cityKey');
    }

    print('🎉 所有城市上传完成');
  } catch (e) {
    print('❌ 上传失败: $e');
  }
}
