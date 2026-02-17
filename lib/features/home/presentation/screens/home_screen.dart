import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../discussion/providers/discussion_providers.dart';
import '../../../discussion/widgets/question_card.dart';
import '../../domain/models/knowledge_post.dart';
import '../providers/knowledge_providers.dart';
import '../../../../shared/widgets/knowledge_card.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/shimmer_card.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/auth/domain/models/auth_state.dart';

/// Home Screen — main feed with greeting, quick actions, filters, and posts.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(knowledgePostsProvider);
    final questionsAsync = ref.watch(questionsProvider);
    final filter = ref.watch(selectedCategoryProvider);
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = (authState is AuthAuthenticated)
        ? (authState.displayName ?? 'Farmer')
        : 'Farmer';
    final userInitials = userName.isNotEmpty ? userName[0].toUpperCase() : 'F';

    // Show questions feed for discussion-type filters
    final showDiscussion = ['Questions', 'Solved', 'Verified'].contains(filter);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $userName 👋',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Voice of the Farmer',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _IconBtn(
                  icon: Icons.notifications_none_rounded,
                  isDark: isDark,
                  badgeCount: 3,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.cardGreenDark
                        : AppColors.cardGreenLight,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(userInitials, style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 14,
                    )),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Quick Actions ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _QuickAction(
                  icon: Icons.forum_rounded,
                  label: 'Discussion',
                  color: AppColors.accent,
                  isDark: isDark,
                  onTap: () {
                    // Switch filter to Questions and show My Questions
                    ref.read(selectedCategoryProvider.notifier).state = 'Questions';
                    ref.read(selectedQuestionStatusProvider.notifier).state = 'My Questions';
                  },
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Weather',
                  color: AppColors.info,
                  isDark: isDark,
                  onTap: () => context.push('/climate'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Filter Chips ──
          const FilterChipBar(),
          const SizedBox(height: 12),

          // ── Feed ──
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(knowledgePostsProvider);
                ref.invalidate(questionsProvider);
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: showDiscussion
                  ? _buildQuestionsFeed(questionsAsync, ref)
                  : _buildKnowledgeFeed(postsAsync, context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeFeed(
    AsyncValue<List<KnowledgePost>> postsAsync,
    BuildContext context,
  ) {
    return postsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: 4,
        itemBuilder: (_, __) => const ShimmerCard(),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('Something went wrong',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No posts yet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: 4),
                  Text('Be the first to share knowledge!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: posts.length,
          itemBuilder: (_, i) => KnowledgeCard(post: posts[i]),
        );
      },
    );
  }

  Widget _buildQuestionsFeed(
    AsyncValue questionsAsync,
    WidgetRef ref,
  ) {
    return questionsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: 3,
        itemBuilder: (_, __) => const ShimmerCard(),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: AppTextStyles.bodyMedium),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🤔', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('No questions yet',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariantLight,
                    )),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: questions.length,
          itemBuilder: (_, i) => QuestionCard(question: questions[i]),
        );
      },
    );
  }
}

// ── Quick Action Pill ──
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.3 : 0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Icon Button (notification icon with optional badge) ──
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final int badgeCount;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.isDark,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.divider,
              ),
            ),
            child: Icon(icon, size: 22,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          if (badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
