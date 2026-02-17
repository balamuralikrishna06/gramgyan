import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/animated_mic_button.dart';
import '../providers/discussion_providers.dart';

/// Screen for adding a solution / answer to a question.
class AddSolutionScreen extends ConsumerStatefulWidget {
  final String questionId;

  const AddSolutionScreen({super.key, required this.questionId});

  @override
  ConsumerState<AddSolutionScreen> createState() => _AddSolutionScreenState();
}

class _AddSolutionScreenState extends ConsumerState<AddSolutionScreen> {
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasTranscript = false;
  bool _isSubmitting = false;
  int _seconds = 0;
  Timer? _timer;
  String _transcript = '';

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isProcessing = false;
      _hasTranscript = false;
      _seconds = 0;
      _transcript = '';
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final transcripts = AppConstants.mockTranscripts;
      setState(() {
        _isProcessing = false;
        _hasTranscript = true;
        _transcript =
            transcripts[DateTime.now().millisecond % transcripts.length];
      });
    });
  }

  String get _timerDisplay {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
          'Your solution will be shared with the farmer who asked this question.',
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

    setState(() => _isSubmitting = true);

    final repo = ref.read(discussionRepositoryProvider);
    await repo.addSolution(
      questionId: widget.questionId,
      transcript: _transcript,
    );

    // Invalidate providers to refresh data
    ref.invalidate(solutionsProvider(widget.questionId));
    ref.invalidate(questionsProvider);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Solution posted! +10 karma 🎉'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    context.pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                        color:
                            isDark ? AppColors.cardDark : AppColors.cardLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.divider,
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Add Solution', style: AppTextStyles.headlineMedium),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // ── Mic Button ──
            AnimatedMicButton(
              isRecording: _isRecording,
              onTap: _isProcessing ? () {} : _toggleRecording,
            ),

            const SizedBox(height: 20),

            // ── Timer / Status ──
            if (_isRecording)
              Text(
                _timerDisplay,
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              )
            else if (_isProcessing)
              Column(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(
                        isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Processing with AI...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            else if (!_hasTranscript)
              Text(
                'Tap the mic to share your solution',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

            const Spacer(flex: 1),

            // ── Transcript + Buttons ──
            if (_hasTranscript) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardGreenDark
                        : AppColors.cardGreenLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isDark ? AppColors.dividerDark : AppColors.divider,
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
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Your Solution',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _transcript,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
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
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Re-record'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isSubmitting ? null : _submitSolution,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label:
                            Text(_isSubmitting ? 'Posting...' : 'Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
