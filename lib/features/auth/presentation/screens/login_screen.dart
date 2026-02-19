import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/auth_state.dart';
import '../providers/auth_providers.dart';

/// Welcome / Login Screen with Google Sign-In.
/// Shows app logo, tagline, animated floating mic circles,
/// Google CTA button, and handles loading + error states.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for content
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Floating circles animation (loops)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn() {
    HapticFeedback.mediumImpact();
    ref.read(authStateProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for state transitions to navigate
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next is AuthAuthenticated) {
        context.go('/home');
      } else if (next is AuthProfileIncomplete) {
        context.go('/complete-profile');
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1A1F12),
                    const Color(0xFF252A1C),
                    const Color(0xFF1A1C16),
                  ]
                : [
                    const Color(0xFFF4F1E8),
                    const Color(0xFFECE8DA),
                    const Color(0xFFF4F1E8),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Floating Mic Background ──
              ..._buildFloatingCircles(isDark),

              // ── Main Content ──
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // ── Logo ──
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: isDark ? 0.3 : 0.15),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── App Name ──
                    Text(
                      AppConstants.appName,
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ── Tagline ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppConstants.appTagline,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // ── Auth Content (button / loading / error) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _buildAuthContent(authState, isDark),
                    ),

                    const SizedBox(height: 16),

                    // ── Terms ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'By continuing, you agree to our\nTerms of Service & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthContent(AuthState authState, bool isDark) {
    // ── Loading State ──
    if (authState is AuthLoading) {
      return Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
              backgroundColor:
                  isDark ? AppColors.cardGreenDark : AppColors.cardGreenLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            authState.message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    // ── Error State ──
    if (authState is AuthError) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      size: 28, color: AppColors.error),
                ),
                const SizedBox(height: 12),
                Text(
                  authState.message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authStateProvider.notifier).resetError();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ),
          const SizedBox(height: 12),
          _buildGoogleButton(isDark),
        ],
      );
    }

    // ── Default: Sign-In Buttons ──
    return Column(
      children: [
        _buildGoogleButton(isDark),
        const SizedBox(height: 16),
        _buildPhoneButton(isDark),
      ],
    );
  }

  Widget _buildPhoneButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () => context.push('/otp-login'),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent, // Transparent for outlined look
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_android_rounded, 
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 14),
            Text(
              'Login with Phone',
              style: AppTextStyles.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isDark ? 0 : 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" logo (using built-in icon as fallback)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Continue with Google',
              style: AppTextStyles.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build subtle floating mic circles for background animation.
  List<Widget> _buildFloatingCircles(bool isDark) {
    final circles = <_FloatingCircleData>[
      _FloatingCircleData(0.15, 0.1, 60, 0.0),
      _FloatingCircleData(0.75, 0.15, 40, 0.3),
      _FloatingCircleData(0.85, 0.5, 50, 0.6),
      _FloatingCircleData(0.1, 0.6, 35, 0.4),
      _FloatingCircleData(0.5, 0.75, 45, 0.8),
    ];

    return circles.map((c) {
      return AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final t = (_floatController.value + c.phase) % 1.0;
          final dy = sin(t * 2 * pi) * 12;
          return Positioned(
            left: MediaQuery.of(context).size.width * c.x,
            top: MediaQuery.of(context).size.height * c.y + dy,
            child: Opacity(
              opacity: isDark ? 0.06 : 0.04,
              child: Icon(
                Icons.mic_rounded,
                size: c.size,
                color: AppColors.primary,
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

/// Data for a floating decoration circle.
class _FloatingCircleData {
  final double x;
  final double y;
  final double size;
  final double phase;

  const _FloatingCircleData(this.x, this.y, this.size, this.phase);
}
