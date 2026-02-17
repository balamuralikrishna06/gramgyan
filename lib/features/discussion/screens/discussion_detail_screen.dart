import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/question.dart';
import '../providers/discussion_providers.dart';
import '../widgets/solution_card.dart';

/// Full discussion view showing the original question and all solutions.
class DiscussionDetailScreen extends ConsumerWidget {
  final String questionId;

  const DiscussionDetailScreen({super.key, required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final questionsAsync = ref.watch(questionsProvider);
    final solutionsAsync = ref.watch(solutionsProvider(questionId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.cardDark : AppColors.cardLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.divider,
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Discussion', style: AppTextStyles.headlineMedium),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: questionsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error loading discussion',
                      style: AppTextStyles.bodyMedium),
                ),
                data: (questions) {
                  final question = questions
                      .where((q) => q.id == questionId)
                      .toList();
                  if (question.isEmpty) {
                    return Center(
                      child: Text('Question not found',
                          style: AppTextStyles.bodyMedium),
                    );
                  }
                  return _buildContent(
                      context, ref, question.first, solutionsAsync, isDark);
                },
              ),
            ),
          ],
        ),
      ),

      // ── Floating Add Solution Button ──
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_solution_fab',
        onPressed: () => context.push('/add-solution/$questionId'),
        icon: const Icon(Icons.reply_rounded),
        label: const Text('Add Solution'),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Question question,
    AsyncValue solutionsAsync,
    bool isDark,
  ) {
    final playingId = ref.watch(discussionPlayingIdProvider);
    final isPlaying = playingId == question.id;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(solutionsProvider(questionId));
        ref.invalidate(questionsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          // ── Question Card ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.divider,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + Crop
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        question.crop,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    _StatusBadge(status: question.status),
                  ],
                ),
                const SizedBox(height: 14),

                // Info rows
                Container(
                  padding: const EdgeInsets.all(14),
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
                const SizedBox(height: 14),

                // Transcript
                Text(
                  question.transcript,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),

                // Play button
                GestureDetector(
                  onTap: () {
                    ref.read(discussionPlayingIdProvider.notifier).state =
                        isPlaying ? null : question.id;
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          size: 20,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPlaying ? 'Stop' : 'Play Audio',
                          style: AppTextStyles.labelMedium.copyWith(
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
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Divider + Solutions Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 20,
                    color:
                        isDark ? AppColors.primaryLight : AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Solutions',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${question.replyCount}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: isDark ? AppColors.dividerDark : AppColors.divider,
            ),
          ),
          const SizedBox(height: 4),

          // ── Solutions List ──
          solutionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('Error loading solutions',
                    style: AppTextStyles.bodyMedium),
              ),
            ),
            data: (solutions) {
              if (solutions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No solutions yet',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to help!',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: solutions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final solution = entry.value;
                  return SolutionCard(
                    solution: solution,
                    isTopAnswer: index == 0 && solution.karma > 0,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──
class _StatusBadge extends StatelessWidget {
  final QuestionStatus status;

  const _StatusBadge({required this.status});

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
        Icon(icon,
            size: 16,
            color: isDark ? AppColors.primaryLight : AppColors.primaryMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
