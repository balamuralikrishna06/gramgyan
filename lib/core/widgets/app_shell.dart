import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/news/presentation/providers/news_provider.dart';
import '../../features/news/presentation/widgets/news_overlay.dart';

/// Main app shell with bottom navigation and microphone FAB.
/// Houses Home, Map, and Profile screens, plus a central News overlay button.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _isNewsOverlayVisible = false;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/map')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // home
  }

  void _onNavTap(BuildContext context, int index) {
    // Auto-close news overlay when switching to any other tab
    if (index != 1 && _isNewsOverlayVisible) {
      ref.read(newsProvider.notifier).stopAudio();
      setState(() => _isNewsOverlayVisible = false);
    }

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        // News button — toggle overlay
        _handleNewsTap();
        break;
      case 2:
        context.go('/map');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  void _handleNewsTap() {
    HapticFeedback.mediumImpact();
    final newsState = ref.read(newsProvider);

    // If overlay already open, close it and stop audio
    if (_isNewsOverlayVisible) {
      ref.read(newsProvider.notifier).stopAudio();
      setState(() => _isNewsOverlayVisible = false);
      return;
    }

    // If already playing (edge case), stop first
    if (newsState.isPlaying) {
      ref.read(newsProvider.notifier).stopAudio();
    }

    // Open overlay and trigger fetch
    setState(() => _isNewsOverlayVisible = true);
    ref.read(newsProvider.notifier).fetchAndPlay();
  }

  void _closeNewsOverlay() {
    setState(() => _isNewsOverlayVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        body: Stack(
          children: [
            // ── Main page content ──
            widget.child,

            // ── News frosted glass overlay ──
            if (_isNewsOverlayVisible)
              Positioned.fill(
                child: NewsOverlay(onClose: _closeNewsOverlay),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.dividerDark : AppColors.divider,
                width: 0.5,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _isNewsOverlayVisible ? 1 : index,
            onDestinationSelected: (i) => _onNavTap(context, i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              // ── News (center) ──
              NavigationDestination(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isNewsOverlayVisible
                      ? const Icon(
                          Icons.close_rounded,
                          key: ValueKey('news_close'),
                          color: AppColors.primary,
                        )
                      : const Icon(
                          Icons.newspaper_rounded,
                          key: ValueKey('news_open'),
                        ),
                ),
                selectedIcon: const Icon(Icons.newspaper_rounded),
                label: 'News',
              ),
              const NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: 'Map',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
        floatingActionButton: (!_isNewsOverlayVisible && index == 0)
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'chat_fab',
                    mini: true,
                    backgroundColor:
                        isDark ? AppColors.surfaceDark : Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 4,
                    onPressed: () => context.push('/chat'),
                    child: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'main_fab',
                    onPressed: () => context.push('/voice-interaction'),
                    child: const Icon(Icons.mic_rounded, size: 30),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
