import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/farmer_profile.dart';
import '../../presentation/providers/profile_providers.dart';

import '../../../auth/domain/models/auth_state.dart';

/// Profile Screen — avatar card, stats row with 4 metrics, badges section,
/// and settings with Dark Mode toggle, language, offline, about.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(farmerProfileProvider);
    final authState = ref.watch(authStateProvider);
    final isDark = ref.watch(darkModeProvider);
    final brightness = Theme.of(context).brightness == Brightness.dark;

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading profile: $e')),
      data: (profile) => _buildProfileContent(context, ref, profile, isDark, brightness, authState),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, FarmerProfile profile, bool isDark, bool brightness, AuthState authState) {

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'My Profile',
              style: AppTextStyles.headlineLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            // ── Profile Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: brightness ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: brightness
                      ? AppColors.dividerDark
                      : AppColors.divider,
                  width: 0.5,
                ),
                boxShadow: brightness
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: brightness
                          ? AppColors.cardGreenDark
                          : AppColors.cardGreenLight,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name.substring(0, 1).toUpperCase()
                            : 'F',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14,
                                color: brightness
                                    ? AppColors.primaryLight
                                    : AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${profile.city}, ${profile.state}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats Row (4 metrics) ──
            Row(
              children: [
                _StatCard(
                  icon: Icons.favorite_rounded,
                  label: 'Karma',
                  value: '${profile.karma}',
                  color: AppColors.karma,
                  isDark: brightness,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.article_outlined,
                  label: 'Posts',
                  value: '${profile.totalPosts}',
                  color: AppColors.primary,
                  isDark: brightness,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.verified_outlined,
                  label: 'Verified',
                  value: '${profile.solutionsVerified}',
                  color: AppColors.verified,
                  isDark: brightness,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.translate_rounded,
                  label: 'Language',
                  value: profile.language,
                  color: AppColors.info,
                  isDark: brightness,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Badges Section ──
            Text(
              'Badges',
              style: AppTextStyles.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: profile.badges.map((badgeId) {
                final badgeDef = AppConstants.badgeDefinitions.firstWhere(
                  (b) => b['id'] == badgeId,
                  orElse: () => {'label': badgeId, 'icon': '🏅'},
                );
                return _BadgeChip(
                  icon: badgeDef['icon'] ?? '🏅',
                  label: badgeDef['label'] ?? badgeId,
                  isDark: brightness,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Admin Dashboard Button
            if (authState is AuthAuthenticated &&
                (authState.role == 'admin' || authState.role == 'expert'))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/admin'),
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: const Text('Admin Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    fixedSize: const Size(double.infinity, 50),
                  ),
                ),
              ),

            // ── Settings Section ──
            Text(
              'Settings',
              style: AppTextStyles.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Dark Mode
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              isDark: brightness,
              trailing: Switch.adaptive(
                value: isDark,
                onChanged: (_) =>
                    ref.read(darkModeProvider.notifier).toggle(),
                activeTrackColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

            // Change Language
            _SettingsTile(
              icon: Icons.language_rounded,
              title: 'Change Language',
              isDark: brightness,
              trailing: Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              onTap: () => _showLanguagePicker(context, ref, profile.language, brightness),
            ),
            const SizedBox(height: 10),

            // About
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About GramGyan',
              isDark: brightness,
              trailing: Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              onTap: () => _showAboutBottomSheet(context, brightness),
            ),
            const SizedBox(height: 8),
            // ── Logout ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(authStateProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String currentLanguage, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Select Language',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...AppConstants.supportedLanguages.map((lang) {
                  final theme = Theme.of(context);
                  final isSelected = lang['english'] == currentLanguage;
                  return ListTile(
                    leading: Text(lang['icon']!, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      lang['name']!,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    subtitle: Text(
                      lang['english']!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      if (!isSelected) {
                        try {
                          await ref.read(profileControllerProvider).updateLanguage(lang['english']!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Language changed to ${lang['english']}'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Failed to update language'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardGreenDark : AppColors.cardGreenLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.info_outline_rounded,
                            color: isDark ? AppColors.primaryLight : AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'About GramGyan',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Theme.of(sheetContext).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Vision',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gramgyan is an AI-powered, community-driven platform designed to bridge the information gap in Indian agriculture. We believe that language and literacy should never be a barrier to modern farming knowledge.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(sheetContext).colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Key Features',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    sheetContext,
                    isDark: isDark,
                    title: 'Audio-First Interaction:',
                    description: 'Ask questions in your local language—no typing required.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    sheetContext,
                    isDark: isDark,
                    title: 'Instant AI Guidance:',
                    description: 'Get immediate, AI-labeled answers powered by Google Gemini to address urgent field issues.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    sheetContext,
                    isDark: isDark,
                    title: 'Community Wisdom:',
                    description: 'Connect with a network of experienced farmers and agricultural experts for human-verified solutions.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    sheetContext,
                    isDark: isDark,
                    title: 'Verified Knowledge:',
                    description: 'Every community answer undergoes admin approval to ensure the highest standards of accuracy and safety.',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(BuildContext context, {required bool isDark, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6.0, right: 8.0, left: 4.0),
          child: Icon(
            Icons.circle,
            size: 6,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.25 : 0.12),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge Chip ──
class _BadgeChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool isDark;

  const _BadgeChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardGreenDark : AppColors.cardGreenLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Tile ──
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22,
                color: isDark ? AppColors.primaryLight : AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
