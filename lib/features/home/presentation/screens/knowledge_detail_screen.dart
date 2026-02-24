import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/knowledge_post.dart';
import '../providers/knowledge_providers.dart';

/// Full view showing a detailed knowledge post.
class KnowledgeDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const KnowledgeDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<KnowledgeDetailScreen> createState() => _KnowledgeDetailScreenState();
}

class _KnowledgeDetailScreenState extends ConsumerState<KnowledgeDetailScreen> {
  late AudioPlayer _audioPlayer;
  StreamSubscription<PlayerState>? _audioSubscription;
  bool _isPlaying = false;
  
  StreamSubscription<PlayerState>? _ttsSubscription;
  bool _isTtsPlaying = false;
  
  bool _isTranslating = false;
  String? _translatedText;

  bool _isLoading = true;
  KnowledgePost? _post;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    Future.microtask(() {
      _ttsSubscription = ref.read(textToSpeechServiceProvider).onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _isTtsPlaying = state == PlayerState.playing);
      });
      _audioSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
      });
    });
    
    _loadPost();
  }
  
  Future<void> _loadPost() async {
    final repo = ref.read(knowledgeRepositoryProvider);
    final post = await repo.fetchPostById(widget.postId);
    if (mounted) {
      setState(() {
        _post = post;
        _isLoading = false;
      });
    }
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
      orElse: () => {'english': 'Audio'},
    );
    return '${lang['english']}';
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
                  Text('Knowledge Details', style: AppTextStyles.headlineMedium),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _post == null 
                  ? Center(child: Text('Post not found', style: AppTextStyles.bodyMedium))
                  : _buildContent(context, ref, _post!, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, KnowledgePost post, bool isDark) {
    final upvotedPosts = ref.watch(upvotedPostsProvider);
    final isUpvoted = upvotedPosts.contains(post.id);

    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        // ── Main Card ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.divider,
              width: 0.5,
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status + Crop
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardGreenDark : AppColors.cardGreenLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _cropEmoji(post.crop),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.crop,
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Shared on ${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: post.verified ? 'Verified' : 'Pending', color: post.verified ? AppColors.success : AppColors.accent),
                ],
              ),
              const SizedBox(height: 18),

              // Info rows
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardGreenDark : AppColors.cardGreenLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Farmer',
                      value: post.farmerName,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'City',
                      value: post.location,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: post.category,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Transcript Label
              Row(
                children: [
                  Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Description',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Transcript Text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.dividerDark : AppColors.divider,
                  ),
                ),
                child: Text(
                  post.transcript,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actions (Play Audio / Upvote)
              Row(
                children: [
                  // Audio Action Buttons
                  if (post.audioUrl.isNotEmpty) ...[
                    // Two Buttons (Original Audio & TTS)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_isPlaying) {
                            await _audioPlayer.stop();
                          } else {
                            await ref.read(textToSpeechServiceProvider).stop();
                            await _audioPlayer.play(UrlSource(post.audioUrl));
                          }
                        },
                        icon: Icon(_isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, size: 20),
                        label: Text(
                          _isPlaying ? 'Stop' : 'Original',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  // TTS Button
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
                              final sourceText = (post.englishText != null && post.englishText!.isNotEmpty)
                                  ? post.englishText!
                                  : post.transcript;
                              _translatedText = await sarvam.translateText(
                                sourceText,
                                sourceLanguage: 'en-IN',
                                targetLanguage: userSarvamCode,
                              );
                            } catch (e) {
                              debugPrint('Translation error: $e');
                              _translatedText = post.transcript;
                            } finally {
                              if (mounted) setState(() => _isTranslating = false);
                            }
                          }
                          
                          final fallbackText = (post.englishText != null && post.englishText!.isNotEmpty)
                              ? post.englishText!
                              : post.transcript;
                          final textToSpeak = _translatedText ?? (userSarvamCode == 'en-IN' ? fallbackText : post.transcript);
                          
                          tts.speak(textToSpeak, language: userSarvamCode);
                        }
                      },
                      icon: _isTranslating 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(_isTtsPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded, size: 20),
                      label: Text(
                        _isTranslating ? '...' : (_isTtsPlaying ? 'Stop' : _getLanguageLabel()),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.cardGreenDark : AppColors.cardGreenLight,
                        foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (post.audioUrl.isEmpty) const Spacer(),
                  const SizedBox(width: 12),
                  // Upvote button
                  GestureDetector(
                    onTap: () {
                      final repo = ref.read(knowledgeRepositoryProvider);
                      final set = Set<String>.from(ref.read(upvotedPostsProvider));
                      if (isUpvoted) {
                        set.remove(post.id);
                      } else {
                        set.add(post.id);
                        repo.upvotePost(post.id).ignore();
                        setState(() { _post = post.copyWith(karma: post.karma + 1); });
                      }
                      ref.read(upvotedPostsProvider.notifier).state = set;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: isUpvoted ? AppColors.karma.withValues(alpha: 0.1) : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUpvoted ? AppColors.karma.withValues(alpha: 0.5) : (isDark ? AppColors.dividerDark : AppColors.divider),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isUpvoted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 24,
                            color: isUpvoted ? AppColors.karma : AppColors.primaryMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${post.karma + (isUpvoted ? 1 : 0)}',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: isUpvoted ? AppColors.karma : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
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
      ],
    );
  }

  String _cropEmoji(String crop) {
    final lower = crop.toLowerCase();
    if (lower.contains('rice') || lower.contains('paddy')) return '🌾';
    if (lower.contains('wheat')) return '🌾';
    if (lower.contains('tomato')) return '🍅';
    if (lower.contains('maize') || lower.contains('corn')) return '🌽';
    if (lower.contains('cotton')) return '🏵️';
    if (lower.contains('sugarcane')) return '🎋';
    if (lower.contains('potato')) return '🥔';
    if (lower.contains('onion')) return '🧅';
    if (lower.contains('mango')) return '🥭';
    if (lower.contains('banana')) return '🍌';
    if (lower.contains('goat') || lower.contains('sheep')) return '🐐';
    if (lower.contains('cow') || lower.contains('cattle')) return '🐄';
    return '🌱';
  }
}

// ── Status Badge ──
class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Info Row ──
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: isDark ? AppColors.primaryLight : AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTextStyles.titleSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.titleSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
