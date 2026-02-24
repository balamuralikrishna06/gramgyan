import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/report.dart';
import '../providers/map_providers.dart';
import '../widgets/report_details_sheet.dart';
import '../widgets/report_marker.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/models/auth_state.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  // Tamil Nadu coordinates as initial center
  static const LatLng _initialCenter = LatLng(11.1271, 78.6569);



// ... (existing imports)

  @override
  void initState() {
    super.initState();
    _centerMap();
  }

  Future<void> _centerMap() async {
    // 1. Try User Location FIRST (High Accuracy)
    try {
      final position = await ref.read(userLocationProvider.future);
      if (mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15,
        );
        return; // Success, stop here
      }
    } catch (_) {
      // Permission denied or service disabled
    }

    // 2. Fallback to City from AuthState
    final authState = ref.read(authStateProvider);
    if (authState is AuthAuthenticated &&
        authState.city != null &&
        authState.city!.isNotEmpty) {
      final coordinates = await GeocodingService()
          .getCoordinatesFromAddress('${authState.city}, India');
      
      if (coordinates != null && mounted) {
         _mapController.move(coordinates, 13);
         return;
      }
    }

    // 3. Fallback to default center (already set in MapOptions)
  }

  void _showReportDetails(BuildContext context, Report report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportDetailsSheet(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(mapReportsProvider);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 7,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gramgyan.app',
              ),
              reportsAsync.when(
                data: (reports) {
                  final markers = reports.map((report) {
                    return ReportMarker(
                      report: report,
                      onTap: () => _showReportDetails(context, report),
                    );
                  }).toList();

                  return MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(40, 40),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      maxZoom: 15,
                      markers: markers,
                      builder: (context, markers) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.primary,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),
              CurrentLocationLayer(
                alignPositionOnUpdate: AlignOnUpdate.always,
                style: const LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    child: Icon(
                      Icons.navigation,
                      color: Colors.white,
                    ),
                  ),
                  markerSize: Size(20, 20),
                  markerDirection: MarkerDirection.heading,
                ),
              ),
              // Attribution
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
          
          // Header / Title
          Positioned(
            top: 40, 
            left: 16,
            right: 16,
            child: Card(
              color: AppColors.surfaceLight.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.radar, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Disease Radar',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Legend
          Positioned(
            bottom: 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                            color: Colors.blue, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text('AI Detected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text('Farmer Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // FAB to center location
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () {
                ref.read(userLocationProvider.future).then((position) {
                   _mapController.move(
                    LatLng(position.latitude, position.longitude),
                    15,
                  );
                });
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
