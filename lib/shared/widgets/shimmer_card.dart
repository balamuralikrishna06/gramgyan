import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';

/// Shimmer skeleton card matching the enhanced knowledge card layout
/// with crop icon, info rows, transcript, and action chips.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
      highlightColor:
          isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: crop icon + title + badge
            Row(
              children: [
                _shimmerBox(width: 40, height: 40, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(width: 120, height: 16),
                      const SizedBox(height: 6),
                      _shimmerBox(width: 60, height: 12),
                    ],
                  ),
                ),
                _shimmerBox(width: 80, height: 24, radius: 20),
              ],
            ),
            const SizedBox(height: 14),

            // Info container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.shimmerBaseDark
                    : AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _shimmerBar(),
                  const SizedBox(height: 8),
                  _shimmerBar(),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Transcript lines (2 lines)
            _shimmerBox(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            _shimmerBox(width: 200, height: 12),

            const SizedBox(height: 14),

            // Action row
            Row(
              children: [
                _shimmerBox(width: 70, height: 32, radius: 20),
                const SizedBox(width: 8),
                _shimmerBox(width: 80, height: 32, radius: 20),
                const Spacer(),
                _shimmerBox(width: 80, height: 32, radius: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    double? width,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _shimmerBar() {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
