import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'local_storage_service.dart';

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Geocodes an address string to LatLng using OpenStreetMap Nominatim API.
  /// Returns null if no coordinates found or error occurs.
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    // 1. Check local cache first
    final cachedLat = LocalStorageService.get('geo_lat_$address');
    final cachedLng = LocalStorageService.get('geo_lng_$address');

    if (cachedLat != null && cachedLng != null) {
      return LatLng(cachedLat as double, cachedLng as double);
    }

    // 2. Fetch from API
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': address,
        'format': 'json',
        'limit': '1',
      });

      final response = await http.get(
        uri,
        headers: {
          // User-Agent is required by Nominatim
          'User-Agent': 'GramGyan/1.0 (com.gramgyan.app)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']);
          final lon = double.tryParse(data[0]['lon']);
          
          if (lat != null && lon != null) {
            // 3. Cache the result
            await LocalStorageService.put('geo_lat_$address', lat);
            await LocalStorageService.put('geo_lng_$address', lon);
            
            return LatLng(lat, lon);
          }
        }
      }
    } catch (e) {
      // Fail silently and return null
    }
    return null;
  }

  /// Reverse geocodes LatLng to a readable address string.
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    // 1. Check local cache
    final cacheKey = 'geo_addr_${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}';
    final cachedAddr = LocalStorageService.get(cacheKey);
    if (cachedAddr != null) return cachedAddr as String;

    // 2. Fetch from API
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
        'zoom': '14', // City/Suburb level
      });

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'GramGyan/1.0 (com.gramgyan.app)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        
        // Construct readable name: Suburb/Village/Town/City
        String name = '';
        if (address != null) {
          name = address['suburb'] ?? 
                 address['village'] ?? 
                 address['town'] ?? 
                 address['city'] ?? 
                 address['county'] ??
                 'Unknown Location';
        }
        
        if (name.isNotEmpty) {
          await LocalStorageService.put(cacheKey, name);
          return name;
        }
      }
    } catch (_) {}
    return null;
  }
}
