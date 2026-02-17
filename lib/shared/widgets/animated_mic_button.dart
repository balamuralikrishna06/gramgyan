import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Animated mic button with organic earthy styling.
/// Pulsing scale effect, custom-painted ripple waves,
/// and waveform bars animation during recording.
class AnimatedMicButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTap;
  final String? detectedLanguage;

  const AnimatedMicButton({
    super.key,
    required this.isRecording,
    required this.onTap,
    this.detectedLanguage,
  });

  @override
  State<AnimatedMicButton> createState() => _AnimatedMicButtonState();
}

class _AnimatedMicButtonState extends State<AnimatedMicButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();
      _waveController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _pulseController.reset();
      _rippleController.stop();
      _rippleController.reset();
      _waveController.stop();
      _waveController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mic button with ripples
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow background
              if (widget.isRecording)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 160 + (_pulseController.value * 20),
                      height: 160 + (_pulseController.value * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (widget.isRecording
                                ? AppColors.error
                                : AppColors.primary)
                            .withValues(alpha: 0.08),
                      ),
                    );
                  },
                ),

              // Ripple rings
              if (widget.isRecording)
                AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(200, 200),
                      painter: _RipplePainter(
                        progress: _rippleController.value,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),

              // Main button
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = widget.isRecording
                      ? 1.0 + (_pulseController.value * 0.08)
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isRecording
                            ? [
                                AppColors.error,
                                AppColors.error.withValues(alpha: 0.8),
                              ]
                            : [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isRecording
                                  ? AppColors.error
                                  : AppColors.primary)
                              .withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isRecording
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Waveform bars
        if (widget.isRecording) ...[
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return _WaveformBars(
                progress: _waveController.value,
                isDark: isDark,
              );
            },
          ),
        ],

        // Language badge
        if (widget.detectedLanguage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardGreenDark
                  : AppColors.cardGreenLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate_rounded,
                    size: 14,
                    color:
                        isDark ? AppColors.primaryLight : AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  widget.detectedLanguage!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.primaryLight
                        : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Waveform bars widget — shows animated bars during recording.
class _WaveformBars extends StatelessWidget {
  final double progress;
  final bool isDark;

  const _WaveformBars({required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(12, (index) {
        final phase = (index / 12) * 2 * pi;
        final height = 8.0 + (sin(progress * 2 * pi + phase) + 1) * 12;
        return Container(
          width: 4,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.primaryLight : AppColors.primary)
                .withValues(alpha: 0.4 + (height / 40) * 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

/// Paints expanding ripple circles around the mic button.
class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final rippleProgress = ((progress + (i * 0.33)) % 1.0);
      final radius = 50 + (rippleProgress * 50);
      final opacity = (1.0 - rippleProgress) * 0.2;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      progress != oldDelegate.progress;
}
