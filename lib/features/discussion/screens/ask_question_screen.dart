import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/animated_mic_button.dart';
import '../../home/presentation/providers/knowledge_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../auth/domain/models/auth_state.dart';
import '../providers/discussion_providers.dart';

/// Screen for asking a new question / recording a problem.
class AskQuestionScreen extends ConsumerStatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  ConsumerState<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends ConsumerState<AskQuestionScreen> {
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasTranscript = false;
  bool _isSubmitting = false;
  int _seconds = 0;
  Timer? _timer;
  String _transcript = '';

  String _selectedCrop = 'Tomato';
  String _selectedCategory = 'Crops';

  static const _crops = [
    'Tomato',
    'Paddy',
    'Wheat',
    'Cotton',
    'Sugarcane',
    'Maize',
    'Groundnut',
    'Turmeric',
    'Onion',
    'Chilli',
    'Cow',
    'Goat',
    'Buffalo',
    'Poultry',
  ];

  static const _categories = ['Crops', 'Livestock', 'Soil', 'Weather'];

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

    // Simulate AI transcription
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

  Future<void> _submitQuestion() async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Submit Question?',
            style: AppTextStyles.titleMedium
                .copyWith(fontWeight: FontWeight.w600)),
        content: Text(
          'Your question about $_selectedCrop will be posted for other farmers to answer.',
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

    final authState = ref.read(authStateProvider);
    String authorId = 'unknown';
    String farmerName = 'Farmer';
    String location = 'Unknown Location';

    if (authState is AuthAuthenticated) {
      authorId = authState.userId;
      farmerName = authState.displayName ?? 'Farmer';
      location = authState.city ?? 'Unknown Location';
    }

    final repo = ref.read(discussionRepositoryProvider);
    final question = await repo.addQuestion(
      transcript: _transcript,
      crop: _selectedCrop,
      category: _selectedCategory,
      authorId: authorId,
      farmerName: farmerName,
      location: location,
    );

    // Invalidate the questions provider so next read gets fresh data
    ref.invalidate(questionsProvider);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Question posted successfully! 🎉'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Switch to Questions tab on Home screen and go back
    ref.read(selectedCategoryProvider.notifier).state = 'Questions';
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
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.cardLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.divider,
                        ),
                      ),
                      child:
                          const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ask a Problem',
                    style: AppTextStyles.headlineMedium,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Crop Selector ──
                    Text('Select Crop / Animal',
                        style: AppTextStyles.titleSmall
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.divider,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCrop,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: _crops.map((crop) {
                            return DropdownMenuItem(
                              value: crop,
                              child: Text(crop,
                                  style: AppTextStyles.bodyMedium),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCrop = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Category Selector ──
                    Text('Category',
                        style: AppTextStyles.titleSmall
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.cardDark
                                      : AppColors.cardLight),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.dividerDark
                                        : AppColors.divider),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // ── Location (mock) ──
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardGreenDark
                            : AppColors.cardGreenLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 18,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Your Village, TN (auto-detected)',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Mic Button ──
                    Center(
                      child: AnimatedMicButton(
                        isRecording: _isRecording,
                        onTap: _isProcessing ? () {} : _toggleRecording,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Timer / Status ──
                    Center(
                      child: _isRecording
                          ? Text(
                              _timerDisplay,
                              style: AppTextStyles.displayMedium.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : _isProcessing
                              ? Column(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                          isDark
                                              ? AppColors.primaryLight
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Processing with AI...',
                                      style:
                                          AppTextStyles.bodySmall.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                )
                              : !_hasTranscript
                                  ? Text(
                                      'Tap the mic to describe your problem',
                                      style:
                                          AppTextStyles.bodySmall.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 16),

                    // ── Transcript Preview ──
                    if (_hasTranscript) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardGreenDark
                              : AppColors.cardGreenLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.dividerDark
                                : AppColors.divider,
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
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 14,
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Question',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _transcript,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Action Buttons ──
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _hasTranscript = false;
                                  _transcript = '';
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded,
                                  size: 18),
                              label: const Text('Re-record'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isSubmitting ? null : _submitQuestion,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded,
                                      size: 18),
                              label: Text(
                                  _isSubmitting ? 'Posting...' : 'Submit'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
