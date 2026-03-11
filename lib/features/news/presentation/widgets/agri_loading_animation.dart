import 'package:flutter/material.dart';

/// Agricultural-themed loading animation.
/// Shows a pulsing wheat stalk icon with a rotating ring while waiting for news.
class AgriLoadingAnimation extends StatefulWidget {
  const AgriLoadingAnimation({super.key});

  @override
  State<AgriLoadingAnimation> createState() => _AgriLoadingAnimationState();
}

class _AgriLoadingAnimationState extends State<AgriLoadingAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _rotateController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating ring
              RotationTransition(
                turns: _rotateController,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                  child: CustomPaint(painter: AgriArcPainter()),
                ),
              ),
              // Center pulsing wheat icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: const Text('🌾', style: TextStyle(fontSize: 36)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const AgriPulsingDots(),
        const SizedBox(height: 12),
        Text(
          'Fetching agri news for you…',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

/// Draws a partial arc to give a loading ring effect.
class AgriArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -1.57, // Start from top
      3.5, // Partial arc (~200 degrees)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Three animated bouncing dots.
class AgriPulsingDots extends StatefulWidget {
  const AgriPulsingDots({super.key});

  @override
  State<AgriPulsingDots> createState() => _AgriPulsingDotsState();
}

class _AgriPulsingDotsState extends State<AgriPulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = (_controller.value * 3 - i).clamp(0.0, 1.0);
            final bounce = (value < 0.5 ? value * 2 : (1 - value) * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8 + bounce * 8,
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A)
                    .withValues(alpha: 0.7 + bounce * 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }
}
