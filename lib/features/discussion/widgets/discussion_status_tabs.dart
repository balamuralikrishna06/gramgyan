import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/discussion_providers.dart';

/// Horizontal tab bar for discussion status filtering.
/// Matches the earthy pill-chip style of the existing FilterChipBar.
class DiscussionStatusTabs extends ConsumerWidget {
  const DiscussionStatusTabs({super.key});

  static const _tabs = ['All', 'Questions', 'Solved', 'Verified'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedQuestionStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = tab == selected;

          return GestureDetector(
            onTap: () =>
                ref.read(selectedQuestionStatusProvider.notifier).state = tab,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.cardDark : AppColors.cardLight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.dividerDark : AppColors.divider),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForTab(tab),
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.primaryLight
                            : AppColors.primaryMuted),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconForTab(String tab) {
    switch (tab) {
      case 'All':
        return Icons.forum_outlined;
      case 'Questions':
        return Icons.help_outline_rounded;
      case 'Solved':
        return Icons.check_circle_outline_rounded;
      case 'Verified':
        return Icons.verified_outlined;
      default:
        return Icons.label_outline;
    }
  }
}
