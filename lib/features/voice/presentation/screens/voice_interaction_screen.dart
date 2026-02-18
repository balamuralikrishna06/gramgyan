import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../map/presentation/providers/map_providers.dart';
import '../../../../core/providers/service_providers.dart'; // reportRepositoryProvider
import '../../../map/presentation/screens/solution_screen.dart';
import '../widgets/voice_recorder_widget.dart';

enum VoiceMode { ask, share }

class VoiceInteractionScreen extends ConsumerStatefulWidget {
  const VoiceInteractionScreen({super.key});

  @override
  ConsumerState<VoiceInteractionScreen> createState() => _VoiceInteractionScreenState();
}

class _VoiceInteractionScreenState extends ConsumerState<VoiceInteractionScreen> {
  VoiceMode _selectedMode = VoiceMode.ask;
  bool _isProcessing = false;

  void _handleVoiceResult(String transcript, String translation, String? audioPath) async {
    // If empty transcript, do nothing or show error
    if (transcript.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not hear anything. Please try again.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final authState = ref.read(authStateProvider);
      final userId = (authState is AuthAuthenticated) ? authState.userId : 'anon';
      
      // Get location - optional, default to 0,0 if fails or not needed
      double lat = 0;
      double lng = 0;
      try {
        final position = await ref.read(userLocationProvider.future);
        lat = position.latitude;
        lng = position.longitude;
      } catch (e) {
        debugPrint('Location error: $e');
      }

      final repo = ref.read(reportRepositoryProvider);

      // We need these for the report. For now, defaulting crop/category or we could add a quick selector later.
      // The prompt says "Simplify... Remove any modal... Directly navigate...".
      // It doesn't explicitly mention Crop/Category selection in this new flow.
      // However, `createReport` requires them. I will use defaults "General" or similar, 
      // OR specifically for "Ask", the SolutionScreen might handle it?
      // Re-reading `RecordScreen`: it has dropdowns.
      // The master prompt says: "Store transcript + audio... Save mode (ask/share) in database".
      // It doesn't mention selecting crop/category in the `VoiceInteractionScreen`.
      // I will use default values to keep the flow frictionless as requested.
      // Or maybe 'Unknown' so it can be tagged later.
      
      final report = await repo.createReport(
        userId: userId,
        latitude: lat,
        longitude: lng,
        crop: 'General', // Default
        category: 'General', // Default
        audioFile: audioPath != null ? File(audioPath) : null, 
        manualTranscript: transcript,
        translatedText: translation, // Pass Sarvam translation
        type: _selectedMode == VoiceMode.ask ? 'question' : 'knowledge',
      );

      if (!mounted) return;

      if (_selectedMode == VoiceMode.ask) {
        // Navigate to Solution Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SolutionScreen(reportId: report.id)),
        );
      } else {
        // Share Knowledge -> Success and go back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Knowledge Shared Successfully! 🌱'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop(); // Go back to Home
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // ── Header ──
              Row(
                children: [
                   IconButton(
                    icon: const Icon(Icons.close_rounded, size: 28),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const Spacer(flex: 1),

              // ── Title ──
              Text(
                'What would you like to do?',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // ── Toggle ──
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark ? AppColors.dividerDark : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleOption(VoiceMode.ask, 'Ask Problem'),
                    _buildToggleOption(VoiceMode.share, 'Share Knowledge'),
                  ],
                ),
              ),
              
              const Spacer(flex: 2),

              // ── Mic Button ──
              if (_isProcessing)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing your request...'),
                  ],
                )
              else
                VoiceRecorderWidget(
                  onResult: _handleVoiceResult,
                  initialLocale: 'ta_IN',
                ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(VoiceMode mode, String label) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: AppTextStyles.titleSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurfaceVariantLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
