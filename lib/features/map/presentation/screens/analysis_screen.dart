import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../map/presentation/providers/map_providers.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  final String originalText;
  final String? translatedText;
  final List<Map<String, dynamic>>? preloadedMatches;

  const AnalysisScreen({
    super.key,
    required this.originalText,
    this.translatedText,
    this.preloadedMatches,
  });

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _isLoading = true;
  bool _foundMatch = false;
  
  Map<String, dynamic>? _matchData;
  String? _aiAnswer;
  
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _processQuery();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _processQuery() async {
    final repo = ref.read(reportRepositoryProvider);
    final gemini = ref.read(geminiServiceProvider);
    final authState = ref.read(authStateProvider);
    
    String? userId;
    if (authState is AuthAuthenticated) {
      userId = authState.userId;
    } else if (authState is AuthProfileIncomplete) {
      userId = authState.userId;
    } else {
      userId = Supabase.instance.client.auth.currentUser?.id;
    }
    
    final farmerProfile = await ref.read(farmerProfileProvider.future);
    final farmerName = farmerProfile.name;
    
    // 1. Use preloaded matches or search for similar knowledge
    final List<Map<String, dynamic>> matches;
    if (widget.preloadedMatches != null && widget.preloadedMatches!.isNotEmpty) {
      matches = widget.preloadedMatches!;
    } else {
      final queryText = widget.translatedText ?? widget.originalText;
      matches = await repo.searchSimilarKnowledge(queryText);
    }

    if (matches.isNotEmpty) {
      // MATCH FOUND
      if (mounted) {
        setState(() {
          _isLoading = false;
          _foundMatch = true;
          _matchData = matches.first; // Best match
        });
      }
      _speak(_matchData!['original_text'] ?? 'Solution found.');
    } else {
      // NO MATCH -> AI FALLBACK
      // 1. Create Question (Async)
      repo.createQuestion(
        userId: userId,
        farmerName: farmerName,
        originalText: widget.originalText,
        englishText: widget.translatedText,
        latitude: 0, // Should be passed ideally
        longitude: 0,
      );

      // 2. Generate AI Answer
      final aiResponse = await gemini.generateAnswer(widget.translatedText ?? widget.originalText);
      // Translate back if needed (Assuming Tamil for now as MVP default or user pref)
      // For now, we show English AI response or simple translation logic
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _foundMatch = false;
          _aiAnswer = aiResponse;
        });
      }
      _speak(aiResponse);
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-IN"); // Default to English/Indian for MVP
    // If Tamil text is detected, switch (simple check)
    // In production, use user preference
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) {
       await _flutterTts.setLanguage("ta-IN");
    }

    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
    setState(() => _isPlaying = true);

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const CircularProgressIndicator(),
                   const SizedBox(height: 16),
                   Text('Consulting the Knowledge Base...', style: AppTextStyles.bodyMedium),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // QUESTON CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Question', style: AppTextStyles.labelMedium),
                        const SizedBox(height: 8),
                        Text(widget.originalText, style: AppTextStyles.titleMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ANSWER SECTION
                  if (_foundMatch) ...[
                    // COMMUNITY ANSWER
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.nature_people_rounded, color: AppColors.success),
                              const SizedBox(width: 8),
                              Text('Community Answer', 
                                style: AppTextStyles.titleMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(_matchData!['original_text'] ?? '', style: AppTextStyles.bodyLarge),
                        ],
                      ),
                    ),
                  ] else ...[
                    // AI ANSWER
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text('AI Creating Answer...', 
                                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(_aiAnswer ?? 'Generating...', style: AppTextStyles.bodyLarge),
                          const SizedBox(height: 12),
                          Text('• Question posted to community for verification', 
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  // TTS CONTROLS
                  Center(
                    child: FloatingActionButton.extended(
                      onPressed: _isPlaying ? _stopSpeaking : () => _speak(_foundMatch ? _matchData!['original_text'] : _aiAnswer!), 
                      icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded),
                      label: Text(_isPlaying ? 'Stop Reading' : 'Read Aloud'),
                      backgroundColor: _isPlaying ? AppColors.error : AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
