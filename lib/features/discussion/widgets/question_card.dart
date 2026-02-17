import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/question.dart';

/// Card widget for displaying a discussion question in the feed.
/// Matches the earthy organic design of KnowledgeCard.
class QuestionCard extends StatelessWidget {
  final Question question;

  const QuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/discussion/${question.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Crop name + Status Badge ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      question.crop,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _StatusBadge(status: question.status, isDark: isDark),
                ],
              ),
              const SizedBox(height: 12),

              // ── Info Rows ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardGreenDark
                      : AppColors.cardGreenLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Farmer',
                      value: question.farmerName,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: question.location,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: question.category,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Transcript Preview ──
              Text(
                question.transcript,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // ── Action Row ──
              Row(
                children: [
                  // Reply count
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardGreenDark
                          : AppColors.cardGreenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${question.replyCount} replies',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Answer button for open questions
                  if (question.status == QuestionStatus.open)
                    GestureDetector(
                      onTap: () =>
                          context.push('/add-solution/${question.id}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.reply_rounded,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'Answer',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Karma display for solved/verified
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.karmaBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded,
                              size: 16, color: AppColors.karma),
                          const SizedBox(width: 4),
                          Text(
                            '${question.karma}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.karma,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status Badge ──
class _StatusBadge extends StatelessWidget {
  final QuestionStatus status;
  final bool isDark;

  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case QuestionStatus.open:
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        break;
      case QuestionStatus.solved:
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        break;
      case QuestionStatus.verified:
        bgColor = AppColors.secondary.withValues(alpha: 0.15);
        textColor = AppColors.secondaryDark;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${status.emoji} ${status.label}',
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Info Row ──
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16,
            color: isDark ? AppColors.primaryLight : AppColors.primaryMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
