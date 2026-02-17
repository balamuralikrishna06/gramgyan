import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/auth_state.dart';
import '../providers/auth_providers.dart';

/// Profile completion screen shown to first-time users after Google sign-in.
/// Collects village, state, preferred language, and crop type.
class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _villageController = TextEditingController();
  String? _selectedState;
  String? _selectedLanguage;
  String? _selectedCrop;

  // Cache user details to prevent flicker during loading state
  String? _cachedDisplayName;
  String? _cachedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null ||
        _selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    ref.read(authStateProvider.notifier).completeProfile(
          city: _villageController.text.trim(),
          selectedState: _selectedState!,
          language: _selectedLanguage!,
        );
  }



  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extract user info from auth state and update cache
    if (authState is AuthProfileIncomplete) {
      _cachedDisplayName = authState.displayName;
      _cachedAvatarUrl = authState.avatarUrl;
    }

    // Use cached values if state is loading (prevent fallback to 'Farmer')
    final displayName = _cachedDisplayName;
    final avatarUrl = _cachedAvatarUrl;

    // Navigate on authenticated
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next is AuthAuthenticated) {
        context.go('/home');
      }
    });

    final isLoading = authState is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Text(
                    'Complete Your\nProfile',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tell us about yourself',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Profile Card (Google info) ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardGreenDark
                          : AppColors.cardGreenLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary
                            .withValues(alpha: isDark ? 0.3 : 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: isDark
                                          ? AppColors.cardDark
                                          : AppColors.cardLight,
                                      child: const Icon(
                                          Icons.person_rounded,
                                          color: AppColors.primary),
                                    ),
                                    errorWidget: (_, __, ___) =>
                                        _buildFallbackAvatar(displayName),
                                  )
                                : _buildFallbackAvatar(displayName),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName ?? 'Farmer',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        size: 12, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Google verified',
                                      style:
                                          AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── City ──
                  _buildLabel('City'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _villageController,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Enter your city name',
                      prefixIcon: const Icon(Icons.location_city_rounded),
                      prefixIconColor: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── State ──
                  _buildLabel('State'),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    value: _selectedState,
                    hint: 'Select your state',
                    icon: Icons.map_outlined,
                    items: AppConstants.indianStates,
                    enabled: !isLoading,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _selectedState = v),
                  ),
                  const SizedBox(height: 20),

                  // ── Language ──
                  _buildLabel('Preferred Language'),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    value: _selectedLanguage,
                    hint: 'Select language',
                    icon: Icons.translate_rounded,
                    items: AppConstants.supportedLanguages
                        .map((l) => l['english']!)
                        .toList(),
                    enabled: !isLoading,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _selectedLanguage = v),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 36),

                  // ── Continue Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleSubmit,
                      child: isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                    backgroundColor: AppColors.onPrimary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Saving...'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Continue'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required bool enabled,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value as String?,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixIconColor: isDark ? AppColors.primaryLight : AppColors.primary,
      ),
      dropdownColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildFallbackAvatar(String? name) {
    return Container(
      color: AppColors.cardGreenLight,
      child: Center(
        child: Text(
          name != null && name.isNotEmpty
              ? name.substring(0, 1).toUpperCase()
              : 'F',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
