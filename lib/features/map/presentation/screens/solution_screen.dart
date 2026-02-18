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
        // stream: _supabase
        //     .from('solutions')
        //     .stream(primaryKey: ['id'])
        //     .eq('report_id', widget.reportId),
        // builder: (context, snapshot) {
        //   // Temporary placeholder since 'solutions' table is missing
        //   return Center(
        //     child: Padding(
        //       padding: const EdgeInsets.all(24.0),
        //       child: Column(
        //         mainAxisAlignment: MainAxisAlignment.center,
        //         children: [
        //           Icon(Icons.construction, size: 48, color: AppColors.primary),
        //           SizedBox(height: 16),
        //           Text(
        //             'Solution feature is currently under development.',
        //             textAlign: TextAlign.center,
        //             style: AppTextStyles.bodyLarge,
        //           ),
        //           SizedBox(height: 8),
        //           Text(
        //             'We are working on the Knowledge Share table first.',
        //             textAlign: TextAlign.center,
        //             style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariantLight),
        //           ),
        //         ],
        //       ),
        //     ),
        //   );
        // },
      body: FutureBuilder<Map<String, dynamic>>(
        future: _supabase
            .from('knowledge_posts')
            .select()
            .eq('id', widget.reportId)
            .single(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Post not found'));
          }

          final post = snapshot.data!;
          final transcript = post['original_text'] as String? ?? 'No transcript available';
          final translation = post['english_text'] as String? ?? 'No translation available';
          final audioUrl = post['audio_url'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (audioUrl != null) ...[
                   Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.audiotrack, color: AppColors.primary),
                        SizedBox(width: 12),
                        Expanded(child: Text('Audio Recording', style: AppTextStyles.labelLarge)),
                        // TODO: Add audio player widget here if needed
                      ],
                    ),
                   ),
                   const SizedBox(height: 24),
                ],

                Text('Transcript', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.divider),
                  ),
                  child: Text(transcript, style: AppTextStyles.bodyLarge),
                ),
                
                const SizedBox(height: 24),
                
                Text('English Translation', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.divider),
                  ),
                  child: Text(translation, style: AppTextStyles.bodyLarge),
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
