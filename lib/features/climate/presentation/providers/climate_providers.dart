import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/climate_repository.dart';
import '../../domain/models/climate_model.dart';
import '../../../map/presentation/providers/map_providers.dart'; // Reuse location provider
import '../../../../core/services/geocoding_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/models/auth_state.dart';
import 'package:latlong2/latlong.dart';


final climateRepositoryProvider = Provider<ClimateRepository>((ref) {
  return ClimateRepository();
});

/// Fetches weather data based on the user's city or current location.
final weatherProvider = FutureProvider.autoDispose<ClimateData>((ref) async {
  final repo = ref.read(climateRepositoryProvider);
  final geocoding = GeocodingService();

  // 1. Try GPS Location FIRST (Most Accurate)
  try {
    final position = await ref.read(userLocationProvider.future);
    
    // Get local name for GPS coordinates
    String locationName = 'Current Location';
    final reversedName = await geocoding.getAddressFromCoordinates(
      position.latitude, 
      position.longitude
    );
    if (reversedName != null) {
      locationName = reversedName;
    }

    return repo.fetchWeather(
      position.latitude, 
      position.longitude,
      locationName: locationName,
      isGPS: true,
    );
  } catch (_) {
    // GPS failed/denied, continue to fallback
  }
  
  // 2. Fallback to City from AuthState (Profile)
  final authState = ref.read(authStateProvider);
  if (authState is AuthAuthenticated && 
      authState.city != null && 
      authState.city!.isNotEmpty) {
      
    final coordinates = await geocoding
        .getCoordinatesFromAddress('${authState.city}, India');
        
    if (coordinates != null) {
      return repo.fetchWeather(
        coordinates.latitude, 
        coordinates.longitude, 
        locationName: authState.city!,
        isGPS: false,
      );
    }
  }

  throw Exception('Unable to determine location');
});
