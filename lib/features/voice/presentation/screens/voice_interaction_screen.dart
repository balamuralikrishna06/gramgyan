import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../map/presentation/providers/map_providers.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../discussion/providers/discussion_providers.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
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
  String? _matchedAudioUrl;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Image State
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source, 
        imageQuality: 50, // Optimize for API
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_transcript == null || _audioPath == null) return;

    setState(() {
      _isProcessing = true;
      _loadingMessage = 'Processing...';
    });

    try {
      final authState = ref.read(authStateProvider);
      
      // Real user id (either AuthAuthenticated or Supabase login)
      String? userId;
      if (authState is AuthAuthenticated) {
        userId = authState.userId;
      } else if (authState is AuthProfileIncomplete) {
        userId = authState.userId;
      } else {
        userId = Supabase.instance.client.auth.currentUser?.id;
      }
      
      // Get farmer name from profile provider
      final farmerProfile = await ref.read(farmerProfileProvider.future);
      final farmerName = farmerProfile.name;
      
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
        
        // 🆕 1. Check for Image (Multimodal Diagnosis)
        if (_selectedImage != null) {
          setState(() => _loadingMessage = 'Analyzing crop health...');
          final geminiService = ref.read(geminiServiceProvider);
          
          // Use translation or transcript or default query
          final queryText = _translation ?? _transcript ?? 'What is wrong with this crop?';
          
          final analysisJson = await geminiService.analyzeCropDisease(_selectedImage!, queryText);
          
          String englishSummary = analysisJson;
          
          // Try to parse JSON to get the friendly summary
          try {
            // Clean markdown code blocks if present
            final cleanJson = analysisJson.replaceAll('```json', '').replaceAll('```', '').trim();
            final Map<String, dynamic> data = json.decode(cleanJson);
            
            if (data.containsKey('summary_for_farmer')) {
              englishSummary = data['summary_for_farmer'];
            }
          } catch (e) {
            debugPrint('JSON Parse Error: $e');
            // Fallback to raw text if parsing fails
          }

          
          // 2026-02-19 FIX: Ensure content is truly English before translating
          bool isHindi = RegExp(r'[\u0900-\u097F]').hasMatch(englishSummary);
          if (isHindi) {
            debugPrint('⚠️ Warning: AI returned Hindi/Devanagari text in English field.');
            // Strategy: Translate this "Hindi" English summary to Actual English first, or directly to Tamil
            // Let's try to translate it to Tamil directly, but setting source to 'hi-IN'
             final sarvam = ref.read(sarvamApiServiceProvider);
             
             // 1. Translate Hindi -> Tamil
             final tamilSummary = await sarvam.translateText(
                englishSummary,
                sourceLanguage: 'hi-IN', // Correct the source
                targetLanguage: 'ta-IN',
              );

             // 2. Translate Hindi -> English (for display)
             final newEnglish = await sarvam.translateText(
                englishSummary,
                sourceLanguage: 'hi-IN',
                targetLanguage: 'en-IN',
              );
              
             setState(() {
                _isProcessing = false;
                _loadingMessage = null;
                _matchedAnswer = newEnglish; // Fixed English
                _tamilAnswer = tamilSummary;
                _isAiAnswer = true;
                _matchSimilarity = 0;
                _matchedAudioUrl = null;
              });

              // Speak the result
              final tts = ref.read(textToSpeechServiceProvider);
              await tts.speak(tamilSummary, language: 'ta-IN');
              
          } else {
             // Standard Flow (English -> Tamil)
             setState(() => _loadingMessage = 'Translating diagnosis...');
             final sarvam = ref.read(sarvamApiServiceProvider);
             final tamilSummary = await sarvam.translateText(
                englishSummary,
                sourceLanguage: 'en-IN',
                targetLanguage: 'ta-IN',
              );
              
              setState(() {
                _isProcessing = false;
                _loadingMessage = null;
                _matchedAnswer = englishSummary;
                _tamilAnswer = tamilSummary;
                _isAiAnswer = true;
                _matchSimilarity = 0;
                _matchedAudioUrl = null;
              });

              // Speak the result
              final tts = ref.read(textToSpeechServiceProvider);
              await tts.speak(tamilSummary, language: 'ta-IN');
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Crop Diagnosed! 🌿'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          
          return; // Exit Ask Flow
        }

        // 📝 2. Text-Only Flow (Existing)
        // Generate embedding for the question
        setState(() => _loadingMessage = 'Searching knowledge base...');
        final geminiService = ref.read(geminiServiceProvider);
        final queryText = _translation ?? _transcript!;
        final matches = await repo.searchSimilarKnowledge(queryText);

        if (!mounted) return;

        // Route based on similarity score
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

          // Speak the Tamil answer via flutter_tts or Play Original Audio
          final audioUrl = matchData['audio_url'] as String?;
          if (audioUrl != null && audioUrl.isNotEmpty) {
            debugPrint('Playing original audio for solution: $audioUrl');
            await _audioPlayer.stop(); // Stop any previous
            await _audioPlayer.play(UrlSource(audioUrl));
            setState(() {
              _matchedAudioUrl = audioUrl;
            });
          } else {
             debugPrint('No original audio, using TTS.');
             final tts = ref.read(textToSpeechServiceProvider);
             await tts.speak(tamilAnswer, language: 'ta-IN');
             setState(() {
               _matchedAudioUrl = null;
             });
          }

        } else {
          // ❌ NO MATCH → Post to Community + Get AI Answer
          setState(() => _loadingMessage = 'Posting to community & consulting AI...');
          
          // Post to community discussion and await it so it crashes visibly if columns are missing
          try {
            await repo.createQuestion(
              userId: userId,
              farmerName: farmerName,
              originalText: _transcript!,
              englishText: _translation,
              latitude: lat,
              longitude: lng,
              audioFile: File(_audioPath!),
            );
          } catch (e) {
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text(e.toString()),
                 backgroundColor: Colors.red,
                 duration: const Duration(seconds: 10),
               ));
            }
          }

          // Generate AI Answer using Gemini
          final aiAnswer = await geminiService.generateAnswer(queryText);

          // Translate AI Answer to Tamil
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
        // Get current language name (e.g., 'Tamil', 'English')
        final languageCode = ref.read(languageProvider) ?? 'en';
        final languageName = AppConstants.supportedLanguages.firstWhere(
          (l) => l['code'] == languageCode,
          orElse: () => {'english': 'Unknown'},
        )['english'] ?? 'Unknown';

        // Use createKnowledgePost for Sharing (Handles Embeddings)
        await repo.createKnowledgePost(
          userId: userId ?? '',
          latitude: lat,
          longitude: lng,
          farmerName: Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? 'Farmer',
          location: await repo.getLocationName(lat, lng), // Will need to make this public or implement here
          crop: 'General',
          category: 'Crops',
          audioFile: File(_audioPath!),
          manualTranscript: _transcript!,
          translatedText: _translation, 
          language: languageName,
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
    // Stop TTS or Audio if playing
    try { ref.read(textToSpeechServiceProvider).stop(); } catch (_) {}
    _audioPlayer.stop();
    setState(() {
      _transcript = null;
      _translation = null;
      _audioPath = null;
      _matchedAnswer = null;
      _tamilAnswer = null;
      _matchSimilarity = 0;
      _isAiAnswer = false;
      _isProcessing = false;
      _selectedImage = null; // Reset image
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

                // ── Image Preview (Initial State) ──
                if (_selectedImage != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 120, width: 120,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: AppColors.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),

                // ── Mic & Camera Controls ──
                if (_isProcessing)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_loadingMessage ?? 'Processing...'),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gallery
                       Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded),
                          color: AppColors.primary,
                          tooltip: 'Gallery',
                        ),
                      ),
                      const SizedBox(width: 24),
                      
                      // Mic (Center)
                      VoiceRecorderWidget(
                        onResult: _handleVoiceResult,
                        initialLocale: 'ta_IN',
                      ),
                      
                      const SizedBox(width: 24),
                      
                      // Camera
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded),
                          color: AppColors.primary,
                          tooltip: 'Camera',
                        ),
                      ),
                    ],
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
                          if (_selectedImage != null) ...[
                            Container(
                              height: 150,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
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
                                      onPressed: () async {
                                        if (_matchedAudioUrl != null) {
                                           await _audioPlayer.stop();
                                           await _audioPlayer.play(UrlSource(_matchedAudioUrl!));
                                        } else {
                                          final tts = ref.read(textToSpeechServiceProvider);
                                          tts.speak(
                                            _tamilAnswer ?? _matchedAnswer!,
                                            language: 'ta-IN',
                                          );
                                        }
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
