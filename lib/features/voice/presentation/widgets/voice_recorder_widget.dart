import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/services/voice_service.dart'; // This is now the record-based service
import '../../../../core/providers/service_providers.dart';
import '../../../../core/services/sarvam_api_service.dart';

class VoiceRecorderWidget extends ConsumerStatefulWidget {
  final Function(String transcript, String translation, String? audioPath) onResult;
  final VoidCallback? onRecordingStopped;
  final String initialLocale;

  const VoiceRecorderWidget({
    super.key,
    required this.onResult,
    this.onRecordingStopped,
    this.initialLocale = 'en_IN',
  });

  @override
  ConsumerState<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends ConsumerState<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService(); // We could also use a provider for this
  bool _isListening = false;
  bool _isProcessing = false;
  String _statusText = "Tap to Speak";
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
    if (_isProcessing) return; // Ignore taps while processing

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    await _voiceService.startRecording();
    setState(() {
      _isListening = true;
      _statusText = "Listening...";
    });
  }

  Future<void> _stopListening() async {
    final filePath = await _voiceService.stopRecording();
    setState(() {
      _isListening = false;
      _isProcessing = true;
      _statusText = "Processing...";
    });

    if (widget.onRecordingStopped != null) {
      widget.onRecordingStopped!();
    }

    if (filePath != null) {
      try {
        final sarvamService = ref.read(sarvamApiServiceProvider);
        final response = await sarvamService.processAudio(filePath);
        
        if (mounted) {
          widget.onResult(response.transcript, response.translation, filePath);
          setState(() {
            _statusText = "Done!";
            _isProcessing = false;
          });
        }
      } catch (e) {
        debugPrint("Error processing audio: $e");
        if (mounted) {
           setState(() {
            _statusText = "Error processing audio";
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error),
          );
        }
      }
    } else {
      setState(() {
        _isProcessing = false;
        _statusText = "Failed to record";
      });
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Text (Replacing Transcript Preview for now)
        Container(
          margin: const EdgeInsets.only(bottom: 30),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isProcessing 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text(
                    _statusText,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Text(
                _statusText,
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
                    color: _isListening ? AppColors.error : (_isProcessing ? Colors.grey : AppColors.primary),
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

