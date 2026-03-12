import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/groq_service.dart';

/// An expandable card that shows the AI analysis for one crop.
class CropResultCard extends StatelessWidget {
  final CropAnalysis analysis;
  final int rank;

  const CropResultCard({
    super.key,
    required this.analysis,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riskColor = _riskColor(analysis.riskLevel);
    final cropEmoji = _cropEmoji(analysis.crop);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: riskColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(cropEmoji, style: const TextStyle(fontSize: 20)),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '#$rank ${analysis.crop}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Risk chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  analysis.riskLevel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Confidence bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: analysis.probability,
                          minHeight: 5,
                          backgroundColor:
                              isDark ? AppColors.dividerDark : AppColors.divider,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_confidenceColor(analysis.probability)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${analysis.confidencePct}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _confidenceColor(analysis.probability),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: 16),

            // ── Risk Cause ──────────────────────────────────────────────
            _SectionTile(
              icon: '⚠️',
              label: 'Cause of Risk',
              color: riskColor,
              child: Text(
                analysis.riskCause,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariantLight,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Why Suitable ────────────────────────────────────────────
            _SectionTile(
              icon: '✅',
              label: 'Why Suitable',
              color: AppColors.success,
              child: Text(
                analysis.whySuitable,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariantLight,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Improvement Steps ───────────────────────────────────────
            if (analysis.improvementSteps.isNotEmpty) ...[
              _SectionTile(
                icon: '🌿',
                label: 'Improve Your Land',
                color: AppColors.info,
                child: _BulletList(items: analysis.improvementSteps),
              ),
              const SizedBox(height: 10),
            ],

            // ── Planting Advice ─────────────────────────────────────────
            if (analysis.plantingAdvice.isNotEmpty) ...[
              _SectionTile(
                icon: '📋',
                label: 'Next Steps to Plant',
                color: AppColors.secondary,
                child: _BulletList(items: analysis.plantingAdvice),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return AppColors.confidenceHigh;
      case 'high':
        return AppColors.confidenceLow;
      default:
        return AppColors.confidenceMedium;
    }
  }

  Color _confidenceColor(double prob) {
    if (prob >= 0.65) return AppColors.confidenceHigh;
    if (prob >= 0.40) return AppColors.confidenceMedium;
    return AppColors.confidenceLow;
  }

  String _cropEmoji(String crop) {
    final name = crop.toLowerCase();
    if (name.contains('rice') || name.contains('paddy')) return '🌾';
    if (name.contains('wheat')) return '🌾';
    if (name.contains('maize') || name.contains('corn')) return '🌽';
    if (name.contains('cotton')) return '🌿';
    if (name.contains('sugarcane')) return '🎋';
    if (name.contains('tomato')) return '🍅';
    if (name.contains('potato')) return '🥔';
    if (name.contains('onion')) return '🧅';
    if (name.contains('banana')) return '🍌';
    if (name.contains('mango')) return '🥭';
    if (name.contains('coconut')) return '🥥';
    if (name.contains('coffee')) return '☕';
    if (name.contains('jute')) return '🌿';
    if (name.contains('lentil') || name.contains('dal')) return '🫘';
    if (name.contains('chickpea') || name.contains('gram')) return '🫘';
    if (name.contains('kidney') || name.contains('bean')) return '🫘';
    if (name.contains('black') || name.contains('mung')) return '🫘';
    if (name.contains('mothbean') || name.contains('mungbean')) return '🫘';
    if (name.contains('pigeonpea')) return '🫘';
    if (name.contains('watermelon') || name.contains('melon')) return '🍉';
    if (name.contains('apple')) return '🍎';
    if (name.contains('orange') || name.contains('papaya')) return '🍊';
    if (name.contains('pomegranate')) return '🍎';
    if (name.contains('grapes')) return '🍇';
    return '🌱';
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final Widget child;

  const _SectionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
