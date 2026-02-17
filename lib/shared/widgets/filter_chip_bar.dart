import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/home/presentation/providers/knowledge_providers.dart';
import '../../features/discussion/providers/discussion_providers.dart';

/// Unified horizontal scrolling filter chip bar for the home feed.
/// Combines category + discussion status into a single row:
/// All, Questions, Solved, Verified, Crops, Livestock, Weather
class FilterChipBar extends ConsumerWidget {
  const FilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.feedFilters.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = AppConstants.feedFilters[index];
          final isSelected = filter == selected;

          return GestureDetector(
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = filter;
              // Sync discussion status if applicable
              if (['Questions', 'Solved', 'Verified'].contains(filter)) {
                 ref.read(selectedQuestionStatusProvider.notifier).state = filter;
              }
            },
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
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForFilter(filter),
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.primaryLight
                            : AppColors.primaryMuted),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
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

  IconData _iconForFilter(String filter) {
    switch (filter) {
      case 'All':
        return Icons.grid_view_rounded;
      case 'Questions':
        return Icons.help_outline_rounded;
      case 'Solved':
        return Icons.check_circle_outline_rounded;
      case 'Verified':
        return Icons.verified_outlined;
      case 'Crops':
        return Icons.grass_rounded;
      case 'Livestock':
        return Icons.pets_rounded;
      case 'Weather':
        return Icons.wb_sunny_outlined;
      case 'Soil':
        return Icons.landscape_rounded;
      default:
        return Icons.label_outline;
    }
  }
}
