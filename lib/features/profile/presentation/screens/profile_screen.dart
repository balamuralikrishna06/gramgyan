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

/// Profile Screen — avatar card, stats row with 4 metrics, badges section,
/// and settings with Dark Mode toggle, language, offline, about.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(farmerProfileProvider);
    final isDark = ref.watch(darkModeProvider);
    final brightness = Theme.of(context).brightness == Brightness.dark;

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading profile: $e')),
      data: (profile) => _buildProfileContent(context, ref, profile, isDark, brightness),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, FarmerProfile profile, bool isDark, bool brightness) {

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
            const SizedBox(height: 28),

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
              onTap: () {},
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
              onTap: () {},
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
