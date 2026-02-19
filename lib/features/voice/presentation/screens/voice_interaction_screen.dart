import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../map/presentation/providers/map_providers.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../discussion/providers/discussion_providers.dart';
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

  // State for matched answer
  String? _matchedAnswer;
  String? _tamilAnswer;
  int _matchSimilarity = 0;
  bool _isAiAnswer = false;

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
        // Force refresh location
        ref.invalidate(userLocationProvider);
        try {
           final position = await ref.read(userLocationProvider.future);
           lat = position.latitude;
           lng = position.longitude;
        } catch (e) {
           debugPrint('Fresh location failed: $e');
           try {
             final lastKnown = await Geolocator.getLastKnownPosition();
             if (lastKnown != null) {
               lat = lastKnown.latitude;
               lng = lastKnown.longitude;
             }
           } catch (_) {}
        }
        
        // Fallback for Emulator/Testing if still 0
        if (lat == 0 && lng == 0) {
          debugPrint('⚠️ Location is 0,0. Using Demo Location (Dindigul) for testing.');
          lat = 10.3673; // Dindigul Lat
          lng = 77.9803; // Dindigul Lng
          
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ GPS failed. Using Demo Location (Dindigul). Check Emulator Settings.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        
        debugPrint('Final Location used: $lat, $lng');
      } catch (e) {
        debugPrint('Location error: $e');
      }

      final repo = ref.read(reportRepositoryProvider);

      if (_selectedMode == VoiceMode.ask) {
        // --- ASK FLOW ---
        // 1. Generate embedding for the question
        setState(() => _loadingMessage = 'Searching knowledge base...');
        final geminiService = ref.read(geminiServiceProvider);
        final queryText = _translation ?? _transcript!;
        final matches = await repo.searchSimilarKnowledge(queryText);

        if (!mounted) return;

        // 2. Route based on similarity score
        final hasGoodMatch = matches.isNotEmpty && 
            (matches.first['similarity'] as num? ?? 0) >= 0.75;

        if (hasGoodMatch) {
          // ✅ MATCH FOUND → Translate to Tamil + speak via Sarvam TTS
          final matchData = matches.first;
          final answerText = matchData['english_text'] as String? ?? 
                             matchData['original_text'] as String? ?? 
                             'Solution found in knowledge base.';
          final similarity = ((matchData['similarity'] as num?) ?? 0) * 100;

          // Translate answer to Tamil using Sarvam
          setState(() => _loadingMessage = 'Translating to Tamil...');
          final sarvam = ref.read(sarvamApiServiceProvider);
          final tamilAnswer = await sarvam.translateText(
            answerText,
            sourceLanguage: 'en-IN',
            targetLanguage: 'ta-IN',
          );

          setState(() {
            _isProcessing = false;
            _loadingMessage = null;
            _matchedAnswer = answerText;
            _tamilAnswer = tamilAnswer;
            _matchSimilarity = similarity.toInt();
            _isAiAnswer = false;
          });

          // Speak the Tamil answer via flutter_tts
          final tts = ref.read(textToSpeechServiceProvider);
          await tts.speak(tamilAnswer, language: 'ta-IN');

        } else {
          // ❌ NO MATCH → Post to Community + Get AI Answer
          setState(() => _loadingMessage = 'Posting to community & consulting AI...');
          
          final farmerName = (authState is AuthAuthenticated)
              ? (authState.displayName ?? 'Farmer')
              : 'Farmer';

          // 3. Post to community discussion in background
          // 3. Post to community discussion in background
          repo.createQuestion(
            userId: userId,
            originalText: _transcript!,
            englishText: _translation,
            latitude: lat,
            longitude: lng,
            audioFile: File(_audioPath!),
          ).ignore();

          // 4. Generate AI Answer using Gemini
          final aiAnswer = await geminiService.generateAnswer(queryText);

          // 5. Translate AI Answer to Tamil
          final sarvam = ref.read(sarvamApiServiceProvider);
          final tamilAiAnswer = await sarvam.translateText(
            aiAnswer,
            sourceLanguage: 'en-IN',
            targetLanguage: 'ta-IN',
          );

          setState(() {
            _isProcessing = false;
            _loadingMessage = null;
            _matchedAnswer = aiAnswer;
            _tamilAnswer = tamilAiAnswer;
            _isAiAnswer = true;
            _matchSimilarity = 0; // AI answer, similarity not applicable
          });

          // Speak the AI answer in Tamil
          final tts = ref.read(textToSpeechServiceProvider);
          await tts.speak(tamilAiAnswer, language: 'ta-IN');

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Consulted AI & Posted to community! 🌾'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }

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
    // Stop TTS if playing
    try { ref.read(textToSpeechServiceProvider).stop(); } catch (_) {}
    setState(() {
      _transcript = null;
      _translation = null;
      _audioPath = null;
      _matchedAnswer = null;
      _tamilAnswer = null;
      _matchSimilarity = 0;
      _isAiAnswer = false;
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

                          // ── Matched Answer Card ──
                          if (_matchedAnswer != null) ...[
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.success.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isAiAnswer ? Icons.auto_awesome : Icons.check_circle_rounded, 
                                        size: 22, 
                                        color: _isAiAnswer ? AppColors.primary : AppColors.success
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _isAiAnswer ? 'AI Suggested Answer' : 'Community Answer Found!', 
                                          style: AppTextStyles.titleSmall.copyWith(
                                            color: _isAiAnswer ? AppColors.primary : AppColors.success,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (!_isAiAnswer)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text('$_matchSimilarity% match',
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w600,
                                            )),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text('🤖 AI',
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            )),
                                        ),
                                    ],
                                  ),

                                  // Tamil Answer (primary)
                                  if (_tamilAnswer != null) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Text('தமிழ் பதில்', 
                                          style: AppTextStyles.labelMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                          )),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _tamilAnswer!,
                                      style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                                    ),
                                  ],

                                  // English Answer (secondary)
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Text('🌐', style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 6),
                                      Text('English', 
                                        style: AppTextStyles.labelMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        )),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _matchedAnswer!,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      height: 1.5,
                                      color: Colors.grey[600],
                                    ),
                                  ),

                                  // Listen Again button
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        final tts = ref.read(textToSpeechServiceProvider);
                                        tts.speak(
                                          _tamilAnswer ?? _matchedAnswer!,
                                          language: 'ta-IN',
                                        );
                                      },
                                      icon: const Icon(Icons.volume_up_rounded),
                                      label: Text(_isAiAnswer ? 'Listen AI Answer 🔉' : 'Listen Community Answer 🔊'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isAiAnswer ? AppColors.primary : AppColors.success,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isAiAnswer) ...[
                                    const SizedBox(height: 12),
                                    Text('• Question posted to community for verification', 
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      )),
                                  ],
                                ],
                              ),
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
