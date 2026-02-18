import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_mic_button.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../map/presentation/providers/map_providers.dart';

import '../../../../core/providers/service_providers.dart';
import '../../../map/presentation/screens/solution_screen.dart';
import '../../../voice/presentation/widgets/voice_recorder_widget.dart'; 

/// Record Knowledge Screen — voice-first with centered glowing mic,
/// waveform animation, AI transcript card, and action buttons.
class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasResult = false;
  bool _isSubmitting = false; 
  int _seconds = 0;
  String _transcript = '';
  String _translation = '';
  String? _audioPath; // Added audio path state

  // Form Fields
  String _selectedCrop = 'Tomato';
  String _selectedCategory = 'Crops';
  bool _isAskMode = true; // true = Ask a Problem, false = Share Knowledge

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

  // Old recording methods removed in favor of VoiceRecorderWidget


  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authStateProvider);
      final userId = (authState is AuthAuthenticated) ? authState.userId : 'anon';
      final position = await ref.read(userLocationProvider.future);
      final repo = ref.read(reportRepositoryProvider);
      
      final report = await repo.createReport(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        crop: _selectedCrop,
        category: _selectedCategory,
        // Using manualTranscript from client-side STT
        audioFile: _audioPath != null ? File(_audioPath!) : null, 
        manualTranscript: _transcript,
        translatedText: _translation, // Pass translated text
        type: _isAskMode ? 'question' : 'knowledge',
      );

      // If ASK MODE -> Go to Solution Screen
      if (_isAskMode && mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => SolutionScreen(reportId: report.id)),
        );
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report submitted successfully! 🚀'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                       _isRecording ? 'Recording...' : (_isAskMode ? 'Ask a Problem' : 'Share Knowledge'),
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // ── Mode Toggle ──
            if (!_isRecording && !_hasResult)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton('Ask Problem', true),
                    _buildModeButton('Share Knowledge', false),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 1),

            // ── Voice Recorder ──
            if (!_hasResult)
              VoiceRecorderWidget(
                onResult: (transcript, translation, audioPath) {
                  setState(() {
                    _transcript = transcript;
                    _translation = translation;
                    _audioPath = audioPath;
                    _hasResult = true;
                  });
                },
                onRecordingStopped: () {
                   // Logic moved to onResult for processing completion
                },
                initialLocale: 'ta_IN', 
              ),

            // ── AI Transcript Card & Form ──
            if (_hasResult)
              Expanded( // Use Expanded to allow scrolling if needed
                flex: 10,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transcript Card
                      Container(
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
                                Icon(Icons.auto_awesome_rounded,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text(
                                  'AI Transcript',
                                  style: AppTextStyles.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _transcript,
                              style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                            ),
                            if (_translation.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.translate_rounded,
                                      size: 18, color: AppColors.secondary),
                                  const SizedBox(width: 10),
                                  Text(
                                    'English Translation',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _translation,
                                style: AppTextStyles.bodyMedium.copyWith(
                                    height: 1.5,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Crop Selector
                       Text('Crop', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                       const SizedBox(height: 8),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                         decoration: BoxDecoration(
                           color: isDark ? AppColors.cardDark : AppColors.cardLight,
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.divider),
                         ),
                         child: DropdownButtonHideUnderline(
                           child: DropdownButton<String>(
                             value: _selectedCrop,
                             isExpanded: true,
                             items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                             onChanged: (v) => setState(() => _selectedCrop = v!),
                           ),
                         ),
                       ),
                       const SizedBox(height: 16),

                       // Category Selector
                       Text('Category', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                       const SizedBox(height: 8),
                       Wrap(
                         spacing: 8,
                         children: _categories.map((c) {
                           final isSelected = c == _selectedCategory;
                           return ChoiceChip(
                             label: Text(c),
                             selected: isSelected,
                             onSelected: (val) => setState(() => _selectedCategory = c),
                             selectedColor: AppColors.primary,
                             labelStyle: TextStyle(
                               color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                             ),
                           );
                         }).toList(),
                       ),
                       const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

             if (!_hasResult) const Spacer(flex: 1),

            // ── Action Buttons ──
            if (_hasResult)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : () {
                          setState(() {
                            _hasResult = false;
                            _transcript = '';
                            _seconds = 0;
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Re-record'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitReport,
                        icon: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded),
                        label: Text(_isSubmitting ? 'Sending...' : 'Submit'),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_hasResult) const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  Widget _buildModeButton(String text, bool isAsk) {
    final isSelected = _isAskMode == isAsk;
    return GestureDetector(
      onTap: () => setState(() => _isAskMode = isAsk),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: AppTextStyles.labelLarge.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurfaceVariantLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
