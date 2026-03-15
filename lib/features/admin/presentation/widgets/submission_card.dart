import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/services/text_to_speech_service.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class SubmissionCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> submission;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const SubmissionCard({
    super.key,
    required this.submission,
    required this.onApprove,
    required this.onReject,
  });

  @override
  ConsumerState<SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends ConsumerState<SubmissionCard> {
  late AudioPlayer _audioPlayer;
  late TextToSpeechService _ttsService;

  bool _isPlaying = false;
  bool _isTtsPlaying = false;
  bool _isTtsLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });

    _ttsService = TextToSpeechService();
    _ttsService.init();
    _ttsService.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isTtsPlaying = state == PlayerState.playing);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final url = widget.submission['audio_url'] as String?;
    if (url == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_isTtsPlaying) await _ttsService.stop();
      await _audioPlayer.play(UrlSource(url));
    }
  }

  Future<void> _toggleTts(String originalText, String? englishText, String submitterLang) async {
    if (_isTtsPlaying || _isTtsLoading) {
      await _ttsService.stop();
      if (mounted) setState(() => _isTtsLoading = false);
      return;
    }

    if (_isPlaying) await _audioPlayer.pause();
    
    if (mounted) setState(() => _isTtsLoading = true);

    try {
      // Get the language from the database profile instead of just local app state.
      // This matches the "language field in users table" request.
      final profile = ref.read(farmerProfileProvider).valueOrNull;
      
      String targetLangCode = 'ta'; // Default fallback
      if (profile != null && profile.language.isNotEmpty) {
        targetLangCode = profile.language.toLowerCase();
      } else {
        targetLangCode = ref.read(languageProvider) ?? 'en';
      }
      
      // Map semantic name to short code if needed
      switch (targetLangCode) {
        case 'tamil': targetLangCode = 'ta'; break;
        case 'english': targetLangCode = 'en'; break;
        case 'hindi': targetLangCode = 'hi'; break;
        case 'telugu': targetLangCode = 'te'; break;
        case 'punjabi': targetLangCode = 'pa'; break;
        case 'marathi': targetLangCode = 'mr'; break;
        case 'odia': targetLangCode = 'or'; break;
        case 'bengali': targetLangCode = 'bn'; break;
        case 'gujarati': targetLangCode = 'gu'; break;
        case 'kannada': targetLangCode = 'kn'; break;
        case 'malayalam': targetLangCode = 'ml'; break;
      }

      final targetSarvamCode = toSarvamCode(targetLangCode);
      
      String textToPlay = originalText;
      
      // If Admin language is different from English and we have englishText, translate it
      if (targetSarvamCode != 'en-IN' && englishText != null && englishText.isNotEmpty) {
        final sarvamService = ref.read(sarvamApiServiceProvider);
        textToPlay = await sarvamService.translateText(
          englishText,
          sourceLanguage: 'en-IN',
          targetLanguage: targetSarvamCode,
        );
      } else if (targetSarvamCode == 'en-IN' && englishText != null && englishText.isNotEmpty) {
        textToPlay = englishText;
      }

      await _ttsService.speak(textToPlay, language: targetSarvamCode);
    } catch(e) {
      debugPrint("TTS Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error playing TTS: $e')));
      }
    } finally {
      if (mounted) setState(() => _isTtsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalText = widget.submission['original_text'] as String? ?? '';
    final englishText = widget.submission['english_text'] as String?;
    final aiFlagged = widget.submission['ai_flagged'] as bool? ?? false;
    final aiReason = widget.submission['ai_reason'] as String?;
    final hasAudio = widget.submission['audio_url'] != null;
    
    // Fallback logic for language
    String userLanguage = 'ta'; 
    if (widget.submission['users'] != null && widget.submission['users']['language'] != null) {
      userLanguage = widget.submission['users']['language'] as String;
    } else if (widget.submission['language'] != null) {
      userLanguage = widget.submission['language'] as String;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Safety Badge
            if (aiFlagged)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25), // ~0.1 opacity
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(76)), // ~0.3 opacity
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Flagged: ${aiReason ?? "Unsafe Content"}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Text(
              'Original Text:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              originalText,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            
            if (englishText != null) ...[
              const SizedBox(height: 12),
              Text(
                'English Translation:',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                englishText,
                style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
              ),
            ],

            // Display Question Context if this is an Answer
            if (widget.submission['questions'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(13), // ~0.05 opacity
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withAlpha(51)), // ~0.2 opacity
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Answering Question:',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.submission['questions']['english_text'] ??
                      widget.submission['questions']['original_text'] ?? 'Unknown Question',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Audio Player
            if (hasAudio || originalText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (hasAudio) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleAudio,
                        icon: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _isPlaying ? 'Playing...' : 'Audio',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade50,
                          foregroundColor: Colors.teal,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(color: Colors.teal.shade200),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (originalText.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTtsLoading ? null : () => _toggleTts(originalText, englishText, userLanguage),
                        icon: _isTtsLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade700),
                              )
                            : Icon(
                                _isTtsPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                        label: Text(
                          _isTtsLoading ? '...' : (_isTtsPlaying ? 'Stop' : 'Play TTS'),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(color: Colors.blue.shade200),
                          ),
                        ),
                      ),
                    ),
                  if (!hasAudio && originalText.isNotEmpty)
                    const Spacer(), // Ensure button doesn't stretch too wide if only one
                ],
              ),
            ],

            const SizedBox(height: 20),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onReject,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withAlpha(128)), // ~0.5 opacity
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onApprove,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Approve', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
