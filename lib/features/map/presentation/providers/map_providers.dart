import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/service_providers.dart';
import '../../data/repositories/map_repository.dart';
import '../../domain/models/report.dart';

import '../../data/repositories/report_repository.dart';

// Repository Providers
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(Supabase.instance.client);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return ReportRepository(Supabase.instance.client, geminiService);
});

// Real-time Reports Provider
final mapReportsProvider = StreamProvider<List<Report>>((ref) {
  final repository = ref.watch(mapRepositoryProvider);
  return repository.subscribeToReports();
});

// User Location Provider
final userLocationProvider = FutureProvider<Position>((ref) async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // Use High accuracy with a timeout
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
    timeLimit: const Duration(seconds: 10),
  );
});
