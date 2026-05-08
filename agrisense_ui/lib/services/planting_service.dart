import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PlantingService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  static Future<String> getPlantingWindowRecommendation({
    required String riceType,
    required String fieldSize,
    required String weatherSummary,
  }) async {
    final prompt = _buildPrompt(riceType, fieldSize, weatherSummary);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('$_baseUrl/api/chatbot');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': prompt}),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('AI request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['response'] as String?;
        if (aiText != null && aiText.isNotEmpty) {
          return aiText;
        }
      }
      throw Exception('AI recommendation unavailable');
    } catch (e) {
      return _fallbackRecommendation(riceType, fieldSize, weatherSummary);
    }
  }

  static String _buildPrompt(
    String riceType,
    String fieldSize,
    String weatherSummary,
  ) {
    return 'Provide a recommended planting window as a date range and simple guidance for planting $riceType rice on a $fieldSize field. ' 
        'Use the current weather summary: $weatherSummary. ' 
        'Include a short recommendation for soil moisture, ideal temperature range, and wind speed. Keep it concise and easy to read.';
  }

  static String _fallbackRecommendation(
    String riceType,
    String fieldSize,
    String weatherSummary,
  ) {
    return 'Recommended Planting Window: Next 5–9 days\n'
        'Soil moisture: Moderate to high, keep soil evenly moist.\n'
        'Temperature range: 26–30°C for best germination.\n'
        'Wind speed: Low to moderate, avoid strong gusts while planting.\n'
        'Rice variety: $riceType on $fieldSize field.';
  }
}
