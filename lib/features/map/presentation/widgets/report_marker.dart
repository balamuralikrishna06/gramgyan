import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/report.dart';

class ReportMarker extends Marker {
  final Report report;
  final VoidCallback onTap;

  ReportMarker({
    required this.report,
    required this.onTap,
  }) : super(
          point: LatLng(report.latitude, report.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: report.aiGenerated ? Colors.blue : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                report.aiGenerated ? Icons.smart_toy : Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
}
