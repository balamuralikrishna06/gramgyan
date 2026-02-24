import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../voice/presentation/widgets/voice_recorder_widget.dart';
import '../../map/presentation/providers/map_providers.dart';

/// Screen for adding a solution / answer to a question.
class AddSolutionScreen extends ConsumerStatefulWidget {
  final String questionId;

  const AddSolutionScreen({super.key, required this.questionId});

  @override
  ConsumerState<AddSolutionScreen> createState() => _AddSolutionScreenState();
}

class _AddSolutionScreenState extends ConsumerState<AddSolutionScreen> {
  bool _isProcessing = false;
  bool _hasTranscript = false;
  String _transcript = '';
  String _translationText = '';
  String? _audioPath;

  void _handleRecordingResult(String transcript, String translation, String? audioPath) {
    setState(() {
      _transcript = transcript;
      _translationText = translation;
      _audioPath = audioPath;
      _hasTranscript = true;
    });
  }

  Future<void> _submitSolution() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Submit Solution?',
            style: AppTextStyles.titleMedium
                .copyWith(fontWeight: FontWeight.w600)),
        content: Text(
          'Your solution will be submitted to our agricultural experts for verification. Once approved, it will be shared with the farmer.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(reportRepositoryProvider);
      await repo.submitAnswerForModeration(
        questionId: widget.questionId,
        latitude: 0, // Fallback, could pass actual location if needed
        longitude: 0,
        farmerName: '', // Fetched from auth profile inside repo
        location: 'Unknown',
        audioFile: _audioPath != null ? File(_audioPath!) : null,
        manualTranscript: _transcript,
        translatedText: _translationText,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Solution submitted for review! 🌾'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                   GestureDetector(
                     onTap: () => context.pop(),
                     child: Container(
                       padding: const EdgeInsets.all(10),
                       decoration: BoxDecoration(
                         color: isDark ? AppColors.cardDark : AppColors.cardLight,
                         shape: BoxShape.circle,
                         border: Border.all(
                           color: isDark ? AppColors.dividerDark : AppColors.divider,
                         ),
                       ),
                       child: const Icon(Icons.arrow_back_rounded, size: 20),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Text('Record Answer', style: AppTextStyles.headlineMedium),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // ── Main Content ──
            if (!_hasTranscript)
              VoiceRecorderWidget(
                onResult: _handleRecordingResult,
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardGreenDark : AppColors.cardGreenLight,
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
                           Container(
                             padding: const EdgeInsets.all(6),
                             decoration: BoxDecoration(
                               color: AppColors.primary.withValues(alpha: 0.12),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Icon(
                               Icons.auto_awesome_rounded,
                               size: 16,
                               color: isDark ? AppColors.primaryLight : AppColors.primary,
                             ),
                           ),
                           const SizedBox(width: 10),
                           Text(
                             'Your Reviewed Solution',
                             style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
                           ),
                         ],
                       ),
                       const SizedBox(height: 14),
                       Text(
                         _transcript,
                         style: AppTextStyles.bodyMedium.copyWith(
                           color: Theme.of(context).colorScheme.onSurfaceVariant,
                           height: 1.6,
                         ),
                       ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _hasTranscript = false;
                            _transcript = '';
                            _audioPath = null;
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Re-record'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _submitSolution,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(_isProcessing ? 'Submitting...' : 'Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
