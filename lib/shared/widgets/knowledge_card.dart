import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/home/domain/models/knowledge_post.dart';
import '../../features/home/presentation/providers/knowledge_providers.dart';

/// Knowledge card widget with crop icon, status tag, farmer info,
/// transcript preview, reply count, and Answer CTA.
class KnowledgeCard extends ConsumerStatefulWidget {
  final KnowledgePost post;

  const KnowledgeCard({super.key, required this.post});

  @override
  ConsumerState<KnowledgeCard> createState() => _KnowledgeCardState();
}

class _KnowledgeCardState extends ConsumerState<KnowledgeCard> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        if (mounted) ref.read(playingPostIdProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final upvotedPosts = ref.watch(upvotedPostsProvider);
    final isUpvoted = upvotedPosts.contains(widget.post.id);
    final playingId = ref.watch(playingPostIdProvider);
    final isPlaying = playingId == widget.post.id;

    // Listen for play state changes from other cards
    if (playingId != widget.post.id) {
       // Stop audio if another card starts playing
       _audioPlayer.stop();
    }

    return GestureDetector(
      onTap: () => context.push('/knowledge/${widget.post.id}'),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.divider,
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Crop Icon + Title + Status Badge ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardGreenDark
                        : AppColors.cardGreenLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _cropEmoji(widget.post.crop),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.crop,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.post.category,
                        style: AppTextStyles.labelSmall.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  label: widget.post.verified ? 'Solved' : 'Needs Solution',
                  color: widget.post.verified ? AppColors.success : AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Info Rows (Farmer + Village) ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardGreenDark
                    : AppColors.cardGreenLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Farmer',
                    value: widget.post.farmerName,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'City',
                    value: widget.post.location,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Transcript Preview (2 lines max) ──
            Text(
              widget.post.transcript,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 14),

            // ── Action Row: Play | Reply Count | Karma ──
            Row(
              children: [
                // Play button
                _ActionChip(
                  icon: isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: isPlaying ? 'Pause' : 'Play',
                  isDark: isDark,
                  onTap: () async {
                    if (isPlaying) {
                      await _audioPlayer.pause();
                      ref.read(playingPostIdProvider.notifier).state = null;
                    } else {
                      ref.read(playingPostIdProvider.notifier).state = widget.post.id;
                      if (widget.post.audioUrl.isNotEmpty) {
                        try {
                           await _audioPlayer.play(UrlSource(widget.post.audioUrl));
                        } catch(e) {
                           debugPrint('Error playing audio: $e');
                           if (mounted) ref.read(playingPostIdProvider.notifier).state = null;
                        }
                      } else {
                         if (mounted) ref.read(playingPostIdProvider.notifier).state = null;
                      }
                    }
                  },
                ),

                const SizedBox(width: 8),

                // Reply count pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardGreenDark
                        : AppColors.cardGreenLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '3 Replies',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Karma / Upvote or Answer CTA
                if (!widget.post.verified)
                  GestureDetector(
                    onTap: () => context.push('/ask-question'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.reply_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Answer',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _ActionChip(
                    icon: isUpvoted
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: '${widget.post.karma + (isUpvoted ? 1 : 0)}',
                    isDark: isDark,
                    highlighted: isUpvoted,
                    onTap: () {
                      final repo = ref.read(knowledgeRepositoryProvider);
                      final set =
                          Set<String>.from(ref.read(upvotedPostsProvider));
                      if (isUpvoted) {
                        // User can't downvote easily yet, just remove from local set
                        set.remove(widget.post.id);
                      } else {
                        set.add(widget.post.id);
                        // Make remote API call to update database
                        repo.upvotePost(widget.post.id).ignore();
                      }
                      ref.read(upvotedPostsProvider.notifier).state = set;
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
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

// ── Status Badge (e.g. "Solved", "Needs Solution") ──
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Info Row (icon + label + value) ──
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
        Icon(icon, size: 16,
            color: isDark ? AppColors.primaryLight : AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ── Action Chip (play, upvote) ──
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool highlighted;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.karma.withValues(alpha: 0.12)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted
                ? AppColors.karma.withValues(alpha: 0.3)
                : (isDark ? AppColors.dividerDark : AppColors.divider),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: highlighted
                  ? AppColors.karma
                  : (isDark ? AppColors.primaryLight : AppColors.primary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: highlighted
                    ? AppColors.karma
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
