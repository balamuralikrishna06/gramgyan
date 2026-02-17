import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Language selection screen matching the earthy card style.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onLanguageSelected(String code) async {
    setState(() => _selectedCode = code);
    await ref.read(languageProvider.notifier).setLanguage(code);
    await LocalStorageService.setOnboarded(true);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Header section
              FadeTransition(
                opacity: _controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardGreenDark
                            : AppColors.cardGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.translate_rounded,
                        size: 28,
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Choose Your\nLanguage',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a language to continue',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Language Cards
              Expanded(
                child: ListView.separated(
                  itemCount: AppConstants.supportedLanguages.length,
                  separatorBuilder: (_, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final lang = AppConstants.supportedLanguages[index];
                    final code = lang['code']!;
                    final isSelected = _selectedCode == code;

                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.2, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _controller,
                        curve: Interval(
                          0.08 * index,
                          0.5 + 0.08 * index,
                          curve: Curves.easeOutCubic,
                        ),
                      )),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve: Interval(
                            0.08 * index,
                            0.5 + 0.08 * index,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => _onLanguageSelected(code),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.cardGreenDark
                                      : AppColors.cardGreen)
                                  : (isDark
                                      ? AppColors.cardDark
                                      : AppColors.cardLight),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.dividerDark
                                        : AppColors.divider),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  lang['icon']!,
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang['name']!,
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        lang['english']!,
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
