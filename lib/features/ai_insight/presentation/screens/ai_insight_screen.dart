import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/ai_insight.dart';
import '../providers/ai_insight_providers.dart';

/// AI Insight Screen — displays AI analysis after a farmer posts a problem.
/// Shows possible cause with confidence %, suggested solutions,
/// similar past cases, weather correlation, and voice playback.
class AiInsightScreen extends ConsumerWidget {
  final String questionId;

  const AiInsightScreen({super.key, required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(aiInsightProvider(questionId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: insightAsync.when(
          loading: () => _buildLoading(context, isDark),
          error: (e, _) => _buildError(context, e),
          data: (insight) => _buildContent(context, insight, isDark),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildHeader(context),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.aiPrimary,
                  ),
                ),
                SizedBox(height: 16),
                Text('AI is analyzing...'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, Object e) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Center(
            child: Text('Error: $e', style: AppTextStyles.bodyMedium),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.aiPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 18, color: AppColors.aiPrimary),
          ),
          const SizedBox(width: 10),
          Text(
            'AI Analysis',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, AiInsight insight, bool isDark) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Possible Cause Card ──
                _SectionCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.search_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Possible Cause',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        insight.possibleCause,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Confidence bar
                      Row(
                        children: [
                          Text(
                            'Confidence',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(insight.confidence * 100).toInt()}%',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: _confidenceColor(insight.confidence),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: insight.confidence,
                          minHeight: 8,
                          backgroundColor: isDark
                              ? AppColors.cardGreenDark
                              : AppColors.cardGreenLight,
                          color: _confidenceColor(insight.confidence),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _severityBgColor(
                                  insight.severity, isDark),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Severity: ${insight.severity}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _severityTextColor(insight.severity),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Suggested Solutions ──
                _SectionCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded,
                              size: 20, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Suggested Solutions',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...insight.suggestedSolutions
                          .asMap()
                          .entries
                          .map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style:
                                        AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Similar Past Cases ──
                _SectionCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history_rounded,
                              size: 20, color: AppColors.verified),
                          const SizedBox(width: 8),
                          Text(
                            'Similar Past Cases',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...insight.similarCases.map((sc) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person_outline_rounded,
                                      size: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${sc.farmerName} — ${sc.location}',
                                    style:
                                        AppTextStyles.labelMedium.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    sc.wasEffective
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 16,
                                    color: sc.wasEffective
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                sc.solution,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Weather Correlation ──
                _SectionCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny_outlined,
                              size: 20, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Weather Correlation',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        insight.weatherCorrelation,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Listen to AI Advice Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('🔊 Playing AI advice...'),
                          backgroundColor: AppColors.aiPrimary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Listen to AI Advice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.aiPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.7) return AppColors.confidenceHigh;
    if (confidence >= 0.4) return AppColors.confidenceMedium;
    return AppColors.confidenceLow;
  }

  Color _severityBgColor(String severity, bool isDark) {
    switch (severity) {
      case 'High':
        return AppColors.error.withValues(alpha: 0.1);
      case 'Medium':
        return AppColors.accent.withValues(alpha: 0.1);
      default:
        return AppColors.success.withValues(alpha: 0.1);
    }
  }

  Color _severityTextColor(String severity) {
    switch (severity) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return AppColors.accent;
      default:
        return AppColors.success;
    }
  }
}

/// Reusable card wrapper for insight sections.
class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.divider,
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.aiPrimary.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}
