import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/service_providers.dart';

class SolutionScreen extends ConsumerStatefulWidget {
  final String reportId;

  const SolutionScreen({super.key, required this.reportId});

  @override
  ConsumerState<SolutionScreen> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends ConsumerState<SolutionScreen> {
  final _supabase = Supabase.instance.client;
  bool _isPlaying = false;
  
  @override
  Widget build(BuildContext context) {
    final tts = ref.watch(textToSpeechServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight; // AppBar same as bg typically or card
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Solution', style: TextStyle(color: textColor)),
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('solutions')
            .stream(primaryKey: ['id'])
            .eq('report_id', widget.reportId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildLoadingState();
          }

          final solution = snapshot.data!.first;
          final solutionText = solution['solution_text'] as String;
          final isAi = solution['ai_generated'] as bool;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AI Badge ──
                if (isAi)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'AI Generated Solution',
                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // ── Solution Text ──
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      solutionText,
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── TTS Button ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_isPlaying) {
                        await tts.stop();
                        setState(() => _isPlaying = false);
                      } else {
                        setState(() => _isPlaying = true);
                        await tts.speak(solutionText);
                        setState(() => _isPlaying = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded),
                    label: Text(_isPlaying ? 'Stop Listening' : 'Listen to Solution'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'Analyzing your problem...',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Consulting agricultural knowledge base',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariantLight),
          ),
        ],
      ),
    );
  }
}
