import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// Weather data auto-fetched via GPS + OpenWeatherMap.
///
/// NOTE: Only temperature and humidity are fetched automatically.
/// Rainfall is NOT included here because OpenWeather returns instantaneous
/// mm/hour which is meaningless for crop models that expect ANNUAL rainfall
/// (e.g. Tamil Nadu avg: 500–900 mm/year). The user enters rainfall manually.
class WeatherData {
  final double temperature; // °C (current)
  final double humidity;    // % relative humidity (current)
  final double latitude;
  final double longitude;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.latitude,
    required this.longitude,
  });
}

class WeatherService {
  /// Gets GPS coordinates and fetches current temperature + humidity
  /// from OpenWeatherMap. Throws a descriptive [Exception] on failure.
  Future<WeatherData> fetchWeather() async {
    // ── 1. Location Permission ──────────────────────────────────────
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable GPS and try again.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. Please allow location access.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Enable it in Settings.',
      );
    }

    // ── 2. Get GPS Position ─────────────────────────────────────────
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    final lat = position.latitude;
    final lon = position.longitude;
    debugPrint('WeatherService: GPS lat=$lat, lon=$lon');

    final uri = Uri.parse(
      '${AppConstants.backendPrimaryUrl}/api/v1/weather?lat=$lat&lon=$lon',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Weather API error (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final double temperature = (data['temperature'] as num).toDouble();
    final double humidity = (data['humidity'] as num).toDouble();

    debugPrint('WeatherService (Backend): temp=$temperature°C, humidity=$humidity%');

    return WeatherData(
      temperature: temperature,
      humidity: humidity,
      latitude: lat,
      longitude: lon,
    );
  }
}
