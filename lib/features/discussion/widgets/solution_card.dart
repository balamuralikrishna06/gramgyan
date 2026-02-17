import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/solution.dart';
import '../providers/discussion_providers.dart';

/// Card widget for displaying a solution in the discussion detail.
class SolutionCard extends ConsumerWidget {
  final Solution solution;
  final bool isTopAnswer;

  const SolutionCard({
    super.key,
    required this.solution,
    this.isTopAnswer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final upvoted = ref.watch(upvotedSolutionsProvider);
    final isUpvoted = upvoted.contains(solution.id);
    final playingId = ref.watch(discussionPlayingIdProvider);
    final isPlaying = playingId == solution.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopAnswer
              ? AppColors.secondary.withValues(alpha: 0.5)
              : (isDark ? AppColors.dividerDark : AppColors.divider),
          width: isTopAnswer ? 1.5 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Answer highlight ──
            if (isTopAnswer) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        size: 14, color: AppColors.secondaryDark),
                    const SizedBox(width: 4),
                    Text(
                      'Top Answer',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Farmer name + verified badge ──
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.cardGreenDark
                        : AppColors.cardGreenLight,
                  ),
                  child: Icon(Icons.person_rounded,
                      size: 16,
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    solution.farmerName,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (solution.isVerified)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.verified.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 14, color: AppColors.verified),
                        const SizedBox(width: 3),
                        Text(
                          'Verified',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.verified,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Transcript ──
            Text(
              solution.transcript,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // ── Actions: Play + Upvote ──
            Row(
              children: [
                // Play button
                GestureDetector(
                  onTap: () {
                    ref.read(discussionPlayingIdProvider.notifier).state =
                        isPlaying ? null : solution.id;
                  },
                  child: Container(
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
                        Icon(
                          isPlaying
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPlaying ? 'Stop' : 'Play',
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
                ),
                const Spacer(),
                // Upvote button
                GestureDetector(
                  onTap: () {
                    final set = {...ref.read(upvotedSolutionsProvider)};
                    if (isUpvoted) {
                      set.remove(solution.id);
                    } else {
                      set.add(solution.id);
                      ref
                          .read(discussionRepositoryProvider)
                          .upvoteSolution(solution.id);
                    }
                    ref.read(upvotedSolutionsProvider.notifier).state = set;
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUpvoted
                          ? AppColors.karma.withValues(alpha: 0.12)
                          : (isDark
                              ? AppColors.cardGreenDark
                              : AppColors.cardGreenLight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUpvoted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color:
                              isUpvoted ? AppColors.karma : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${solution.karma + (isUpvoted ? 5 : 0)}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color:
                                isUpvoted ? AppColors.karma : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
