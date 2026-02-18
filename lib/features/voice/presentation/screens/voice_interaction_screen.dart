import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../map/presentation/providers/map_providers.dart';
import '../../../../core/providers/service_providers.dart';
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
  String? _loadingMessage;

  // State for result display
  String? _transcript;
  String? _translation;
  String? _audioPath;

  void _handleVoiceResult(String transcript, String translation, String? audioPath) {
    if (transcript.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not hear anything. Please try again.')),
      );
      return;
    }

    // Just update state to show results and enable review
    setState(() {
      _transcript = transcript;
      _translation = translation;
      _audioPath = audioPath;
      _isProcessing = false;
    });
  }

  Future<void> _submit() async {
    if (_transcript == null || _audioPath == null) return;

    setState(() {
      _isProcessing = true;
      _loadingMessage = 'Processing...';
    });

    try {
      final authState = ref.read(authStateProvider);
      final userId = (authState is AuthAuthenticated) ? authState.userId : 'anon';
      
      // Get location
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

      if (_selectedMode == VoiceMode.ask) {
        // --- ASK FLOW ---
        // Use createReport for Questions
        final report = await repo.createReport(
          userId: userId,
          latitude: lat,
          longitude: lng,
          crop: 'General', // Default
          category: 'General', // Default
          audioFile: File(_audioPath!), 
          manualTranscript: _transcript!,
          translatedText: _translation, 
          type: 'question',
        );
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SolutionScreen(reportId: report.id)),
        );

      } else {
        // --- SHARE KNOWLEDGE FLOW ---
        // Use createKnowledgePost for Sharing (Handles Embeddings)
        await repo.createKnowledgePost(
          userId: userId,
          latitude: lat,
          longitude: lng,
          audioFile: File(_audioPath!),
          manualTranscript: _transcript!,
          translatedText: _translation, 
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Knowledge Shared Successfully! 🚀'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _loadingMessage = null;
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _transcript = null;
      _translation = null;
      _audioPath = null;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasResult = _transcript != null;

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
              
              if (!hasResult) ...[
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
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_loadingMessage ?? 'Processing...'),
                    ],
                  )
                else
                  VoiceRecorderWidget(
                    onResult: _handleVoiceResult,
                    initialLocale: 'ta_IN',
                  ),

                const Spacer(flex: 3),
              ] else ...[
                // ── Result View ──
                const SizedBox(height: 20),
                Text(
                  'Here is what I heard:',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.dividerDark : AppColors.divider,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.record_voice_over_rounded, 
                                size: 20, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text('Original Audio', style: AppTextStyles.titleSmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _transcript!,
                            style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
                          ),
                          
                          if (_translation != null && _translation!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.translate_rounded, 
                                  size: 20, color: AppColors.secondary),
                                const SizedBox(width: 10),
                                Text('English Translation', style: AppTextStyles.titleSmall),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _translation!,
                              style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                if (_isProcessing)
                   Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_loadingMessage ?? 'Sending...'),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reset,
                          child: const Text('Re-record'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_selectedMode == VoiceMode.ask ? 'Get Solution' : 'Share Knowledge'),
                        ),
                      ),
                    ],
                  ),
              ],
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
