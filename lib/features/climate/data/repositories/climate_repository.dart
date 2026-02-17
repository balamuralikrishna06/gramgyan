import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/climate_model.dart';

class ClimateRepository {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<ClimateData> fetchWeather(double lat, double lng, {String locationName = '', bool isGPS = false}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lng.toString(),
      'current_weather': 'true',
      'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode',
      'timezone': 'auto',
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ClimateData.fromJson(data, locationName: locationName, isGPS: isGPS);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to weather service: $e');
    }
  }
}
