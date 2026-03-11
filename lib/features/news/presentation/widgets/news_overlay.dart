import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/news_provider.dart';
import 'agri_loading_animation.dart';

/// Full-screen frosted glass overlay that shows agri news.
///
/// Shows:
/// - Loading animation while fetching
/// - 3-bullet summary when loaded
/// - Pause/Stop button while audio is playing
/// - Error message if fetch fails
class NewsOverlay extends ConsumerWidget {
  final VoidCallback onClose;

  const NewsOverlay({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {}, // Absorbs taps inside the overlay
      child: SizedBox.expand(
        child: Stack(
          children: [
            // ── Frosted glass backdrop ──
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),

            // ── Content card ──
            Align(
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _buildContent(context, ref, news, size),
              ),
            ),

            // ── Close button (top right) ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: _CloseButton(onPressed: () {
                ref.read(newsProvider.notifier).stopAudio();
                onClose();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, NewsState news, Size size) {
    return Container(
      key: ValueKey(news.status),
      width: size.width * 0.9,
      constraints: BoxConstraints(maxHeight: size.height * 0.75),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Row(
                children: [
                  const Text('🌾', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    'Agri News',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Body ──
              _buildBody(context, ref, news),

              // ── Pause/Stop button — only while audio playing ──
              if (news.isPlaying) ...[
                const SizedBox(height: 24),
                _PauseStopButton(
                  onStop: () => ref.read(newsProvider.notifier).stopAudio(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, NewsState news) {
    switch (news.status) {
      case NewsStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: AgriLoadingAnimation(),
        );

      case NewsStatus.loaded:
        final summary = news.summaryText ?? '';
        final bullets = _parseBullets(summary);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bullets.isNotEmpty)
              ...bullets.asMap().entries.map((e) => _BulletPoint(
                    index: e.key + 1,
                    text: e.value,
                  ))
            else
              Text(
                summary,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
          ],
        );

      case NewsStatus.error:
        return Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF5350), size: 40),
            const SizedBox(height: 10),
            if (news.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Text(
                  news.errorMessage!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              )
            else
              Text(
                'Could not load news.\nPlease try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(newsProvider.notifier).fetchAndPlay(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        );

      case NewsStatus.idle:
        return const SizedBox.shrink();
    }
  }

  /// Parses summary text into bullet lines.
  /// Handles numbered lists (1. / 2. / 3.), bullet chars (•, -, *), or newlines.
  List<String> _parseBullets(String text) {
    // Try numbered pattern first
    final numbered = RegExp(r'^\d+[\.\)]\s+', multiLine: true);
    if (numbered.hasMatch(text)) {
      return text
          .split(RegExp(r'\n'))
          .map((l) => l.replaceAll(RegExp(r'^\d+[\.\)]\s+'), '').trim())
          .where((l) => l.isNotEmpty)
          .take(3)
          .toList();
    }
    // Try bullet chars
    final bulletted = RegExp(r'^[•\-\*]\s+', multiLine: true);
    if (bulletted.hasMatch(text)) {
      return text
          .split(RegExp(r'\n'))
          .map((l) => l.replaceAll(RegExp(r'^[•\-\*]\s+'), '').trim())
          .where((l) => l.isNotEmpty)
          .take(3)
          .toList();
    }
    // Fallback: split by newlines
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).take(3).toList();
    if (lines.length >= 2) return lines;
    // Fallback: return full text as one bullet
    return [text.trim()];
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _BulletPoint extends StatelessWidget {
  final int index;
  final String text;

  const _BulletPoint({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF66BB6A).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF66BB6A).withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color(0xFF66BB6A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14.5,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseStopButton extends StatelessWidget {
  final VoidCallback onStop;
  const _PauseStopButton({required this.onStop});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onStop,
        icon: const Icon(Icons.stop_circle_rounded, size: 22),
        label: const Text(
          'Stop Audio',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF5350),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
