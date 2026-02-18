import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
  
  // State for result display
  String? _transcript;
  String? _translation;

  void _handleVoiceResult(String transcript, String translation) async {
    if (transcript.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not hear anything. Please try again.')),
      );
      return;
    }

    // Instead of saving to DB, just update state to show results
    setState(() {
      _transcript = transcript;
      _translation = translation;
      _isProcessing = false;
    });
  }

  void _reset() {
    setState(() {
      _transcript = null;
      _translation = null;
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reset,
                        child: const Text('Try Again'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Done'),
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
