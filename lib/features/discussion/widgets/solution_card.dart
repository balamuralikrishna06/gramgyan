import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../models/solution.dart';
import '../providers/discussion_providers.dart';

/// Card widget for displaying a solution in the discussion detail.
class SolutionCard extends ConsumerStatefulWidget {
  final Solution solution;
  final bool isTopAnswer;

  const SolutionCard({
    super.key,
    required this.solution,
    this.isTopAnswer = false,
  });

  @override
  ConsumerState<SolutionCard> createState() => _SolutionCardState();
}

class _SolutionCardState extends ConsumerState<SolutionCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _audioSubscription;
  bool _isAudioPlaying = false;

  StreamSubscription<PlayerState>? _ttsSubscription;
  bool _isTtsPlaying = false;
  
  bool _isTranslating = false;
  String? _translatedText;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _ttsSubscription = ref.read(textToSpeechServiceProvider).onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _isTtsPlaying = state == PlayerState.playing);
      });
      _audioSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _isAudioPlaying = state == PlayerState.playing);
      });
    });
  }

  @override
  void dispose() {
    _ttsSubscription?.cancel();
    _audioSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _getLanguageLabel() {
    final langCode = ref.read(languageProvider) ?? 'en';
    final lang = AppConstants.supportedLanguages.firstWhere(
      (l) => l['code'] == langCode,
      orElse: () => {'english': 'Answer'},
    );
    return '${lang['english']}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final upvoted = ref.watch(upvotedSolutionsProvider);
    final isUpvoted = upvoted.contains(widget.solution.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isTopAnswer
              ? AppColors.secondary.withValues(alpha: 0.5)
              : (isDark ? AppColors.dividerDark : AppColors.divider),
          width: widget.isTopAnswer ? 1.5 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Answer highlight ──
            if (widget.isTopAnswer) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        size: 14, color: AppColors.secondaryDark),
                    const SizedBox(width: 4),
                    Text(
                      'Top Answer',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Farmer name + verified badge ──
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.cardGreenDark
                        : AppColors.cardGreenLight,
                  ),
                  child: Icon(Icons.person_rounded,
                      size: 16,
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.solution.farmerName,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (widget.solution.isVerified)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.verified.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 14, color: AppColors.verified),
                        const SizedBox(width: 3),
                        Text(
                          'Verified',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.verified,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Transcript ──
            Text(
              widget.solution.transcript,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // ── Actions: Play + Upvote ──
            Row(
              children: [
                // Audio Action Buttons
                if (widget.solution.audioUrl.isNotEmpty) ...[
                  // Two Buttons (Original Audio & TTS)
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_isAudioPlaying) {
                                await _audioPlayer.stop();
                              } else {
                                await ref.read(textToSpeechServiceProvider).stop();
                                await _audioPlayer.play(UrlSource(widget.solution.audioUrl));
                              }
                            },
                            icon: Icon(_isAudioPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, size: 18),
                            label: Text(
                              _isAudioPlaying ? 'Stop' : 'Original',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final userLangCode = ref.read(languageProvider) ?? 'en';
                              final userSarvamCode = toSarvamCode(userLangCode);
                              final tts = ref.read(textToSpeechServiceProvider);
                              if (_isTtsPlaying) {
                                await tts.stop();
                              } else if (!_isTranslating) {
                                await _audioPlayer.stop();
                                if (_translatedText == null && userSarvamCode != 'en-IN') {
                                  setState(() => _isTranslating = true);
                                  try {
                                    final sarvam = ref.read(sarvamApiServiceProvider);
                                    _translatedText = await sarvam.translateText(
                                      widget.solution.transcript,
                                      sourceLanguage: 'en-IN',
                                      targetLanguage: userSarvamCode,
                                    );
                                  } catch (e) {
                                    debugPrint('Translation error: $e');
                                    _translatedText = widget.solution.transcript;
                                  } finally {
                                    if (mounted) setState(() => _isTranslating = false);
                                  }
                                }
                                tts.speak(_translatedText ?? widget.solution.transcript, language: userSarvamCode);
                              }
                            },
                            icon: _isTranslating 
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Icon(_isTtsPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded, size: 18),
                            label: Text(
                              _isTranslating ? '...' : (_isTtsPlaying ? 'Stop' : _getLanguageLabel()),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Single TTS Button
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final userLangCode = ref.read(languageProvider) ?? 'en';
                          final userSarvamCode = toSarvamCode(userLangCode);
                          final tts = ref.read(textToSpeechServiceProvider);
                          if (_isTtsPlaying) {
                            await tts.stop();
                          } else if (!_isTranslating) {
                            if (_translatedText == null && userSarvamCode != 'en-IN') {
                              setState(() => _isTranslating = true);
                              try {
                                final sarvam = ref.read(sarvamApiServiceProvider);
                                _translatedText = await sarvam.translateText(
                                  widget.solution.transcript,
                                  sourceLanguage: 'en-IN',
                                  targetLanguage: userSarvamCode,
                                );
                              } catch (e) {
                                debugPrint('Translation error: $e');
                                _translatedText = widget.solution.transcript;
                              } finally {
                                if (mounted) setState(() => _isTranslating = false);
                              }
                            }
                            tts.speak(_translatedText ?? widget.solution.transcript, language: userSarvamCode);
                          }
                        },
                        icon: _isTranslating 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(_isTtsPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded, size: 18),
                        label: Text(
                          _isTranslating ? 'Translating...' : (_isTtsPlaying ? 'Stop' : 'Listen'),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                // Upvote button
                GestureDetector(
                  onTap: () {
                    final set = {...ref.read(upvotedSolutionsProvider)};
                    if (isUpvoted) {
                      set.remove(widget.solution.id);
                    } else {
                      set.add(widget.solution.id);
                      ref
                          .read(discussionRepositoryProvider)
                          .upvoteSolution(widget.solution.id);
                    }
                    ref.read(upvotedSolutionsProvider.notifier).state = set;
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUpvoted
                          ? AppColors.karma.withValues(alpha: 0.12)
                          : (isDark
                              ? AppColors.cardGreenDark
                              : AppColors.cardGreenLight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUpvoted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color:
                              isUpvoted ? AppColors.karma : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.solution.karma + (isUpvoted ? 5 : 0)}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color:
                                isUpvoted ? AppColors.karma : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
