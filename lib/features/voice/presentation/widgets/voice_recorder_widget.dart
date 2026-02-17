import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/services/voice_service.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(String) onResult;
  final VoidCallback? onRecordingStopped;
  final String initialLocale;

  const VoiceRecorderWidget({
    super.key,
    required this.onResult,
    this.onRecordingStopped,
    this.initialLocale = 'en_IN',
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  String _currentTranscript = "Tap the mic to start speaking...";
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initVoiceService();
  }

  Future<void> _initVoiceService() async {
    await _voiceService.initialize();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _currentTranscript = "Listening...";
    });

    await _voiceService.startListening(
      locale: widget.initialLocale,
      onResult: (text) {
        setState(() => _currentTranscript = text);
        widget.onResult(text);
      },
    );
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    setState(() => _isListening = false);
    if (widget.onRecordingStopped != null) {
      widget.onRecordingStopped!();
    }
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Transcript Preview
        Container(
          margin: const EdgeInsets.only(bottom: 30),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _currentTranscript,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),

        // Animated Mic Button
        GestureDetector(
          onTap: _toggleListening,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? AppColors.error : AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? AppColors.error : AppColors.primary)
                            .withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          _isListening ? "Tap to Stop" : "Tap to Speak",
          style: AppTextStyles.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
