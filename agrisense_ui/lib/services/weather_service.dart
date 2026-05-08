import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherData {
  final String day;
  final double temp;
  final double feelsLike;
  final String condition;
  final int humidity;
  final double windSpeed;
  final double pressure;
  final int cloudiness;
  final double? precipitation;

  WeatherData({
    required this.day,
    required this.temp,
    required this.feelsLike,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.cloudiness,
    this.precipitation,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, String dayLabel) {
    return WeatherData(
      day: dayLabel,
      temp: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      condition: json['weather'][0]['main'] as String,
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      pressure: (json['main']['pressure'] as num).toDouble(),
      cloudiness: json['clouds']['all'] as int,
      precipitation: json['rain']?['1h'] ?? json['snow']?['1h'],
    );
  }
}

class WeatherService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/weather';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/weather';
    }
    return 'http://localhost:5000/api/weather';
  }

  static Future<List<WeatherData>> getWeatherForecast(
      double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$latitude&lon=$longitude',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Weather API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> list = json['list'];

        // Get 5-day forecast (one entry per day at noon)
        final Map<String, WeatherData> dailyWeather = {};
        final List<String> dayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

        for (var i = 0; i < list.length; i += 8) {
          // Every 8 entries = 1 day (3-hour intervals * 8 = 24 hours)
          if (list[i] != null) {
            final dateTime = DateTime.parse(list[i]['dt_txt']);
            final dayLabel = dayLabels[dateTime.weekday % 7];

            if (!dailyWeather.containsKey(dayLabel)) {
              dailyWeather[dayLabel] = WeatherData.fromJson(list[i], dayLabel);
            }
          }
        }

        return dailyWeather.values.toList().take(4).toList();
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather forecast: $e');
    }
  }
  static Future<List<WeatherData>> getHourlyForecast(
      double latitude, double longitude) async {
    try {
      final url = Uri.parse('$_baseUrl/forecast?lat=$latitude&lon=$longitude');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Weather API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> list = json['list'];
        final List<WeatherData> hourlyWeather = [];

        for (var i = 0; i < list.length && hourlyWeather.length < 8; i++) {
          if (list[i] != null) {
            final dateTime = DateTime.parse(list[i]['dt_txt']);
            final label = _formatHour(dateTime);
            hourlyWeather.add(WeatherData.fromJson(list[i], label));
          }
        }

        return hourlyWeather.take(4).toList();
      } else {
        throw Exception('Failed to load hourly weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching hourly weather: $e');
    }
  }

  static String _formatHour(DateTime dateTime) {
    final hour = dateTime.hour;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return '$displayHour $period';
  }
  static Future<WeatherData> getCurrentWeather(
      double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/current?lat=$latitude&lon=$longitude',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Weather API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return WeatherData.fromJson(json, 'Today');
      } else {
        throw Exception('Failed to load current weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching current weather: $e');
    }
  }

  static Future<Map<String, dynamic>> getLocationCoordinates(String city) async {
    try {
      final url = Uri.parse('$_baseUrl/geocode?city=${Uri.encodeComponent(city)}');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Geocoding request timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json;
      } else {
        throw Exception('Failed to resolve location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error resolving location: $e');
    }
  }

  // Map weather conditions to Flutter icons
  static String getWeatherIconDescription(String condition) {
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('cloud')) {
      return 'cloud';
    } else if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
      return 'rain';
    } else if (lowerCondition.contains('thunderstorm') || lowerCondition.contains('storm')) {
      return 'storm';
    } else if (lowerCondition.contains('snow')) {
      return 'snow';
    } else if (lowerCondition.contains('clear') || lowerCondition.contains('sunny')) {
      return 'sunny';
    } else if (lowerCondition.contains('wind')) {
      return 'wind';
    }

    return 'cloud';
  }
}
