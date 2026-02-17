import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/report.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/service_providers.dart';

class ReportDetailsSheet extends ConsumerStatefulWidget {
  final Report report;

  const ReportDetailsSheet({super.key, required this.report});

  @override
  ConsumerState<ReportDetailsSheet> createState() => _ReportDetailsSheetState();
}

class _ReportDetailsSheetState extends ConsumerState<ReportDetailsSheet> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    // Reset TTS on init just in case
     ref.read(textToSpeechServiceProvider).stop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    ref.read(textToSpeechServiceProvider).stop();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (widget.report.audioUrl == null) return;
    
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.report.audioUrl!));
    }
  }

  Future<void> _toggleTTS() async {
    final tts = ref.read(textToSpeechServiceProvider);
    
    if (_isSpeaking) {
      await tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      // Prefer translated text if available (usually English), else original
      // Or maybe read original then English? For now, read what is shown.
      String textToRead = widget.report.translatedTranscript ?? widget.report.transcript;
      if (textToRead.isEmpty) textToRead = "No description available.";
      
      // Determine language: if translated is present, likely English. 
      // If only transcript, it's original language.
      // Ideally we pass language code.
      // For MVP, default to English/System default. A real app would detect.
      
      await tts.speak(textToRead);
      // Note: flutter_tts doesn't easily give "onComplete" in this simple wrapper without listener setup.
      // We'll just toggle state back manually or let it be for now. 
      // Better: Setup listener in TTS service or just let user stop it.
      // Simplification: We assume speaking starts.
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final hasAudio = report.audioUrl != null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                report.aiGenerated ? Icons.smart_toy : Icons.person,
                color: report.aiGenerated ? Colors.blue : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                report.crop,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: report.aiGenerated
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.category,
                  style: TextStyle(
                    color: report.aiGenerated ? Colors.blue : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reported on ${DateFormat.yMMMd().format(report.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          
          // Audio Player Control
          if (hasAudio) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                    iconSize: 40,
                    color: AppColors.primary,
                    onPressed: _toggleAudio,
                  ),
                  const SizedBox(width: 8),
                  const Text("Play Original Voice", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
             const SizedBox(height: 16),
          ],

          // Description & Translation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: Icon(_isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded),
                color: AppColors.primary,
                tooltip: "Read Aloud",
                onPressed: _toggleTTS,
              )
            ],
          ),
          const SizedBox(height: 4),
          
          if (report.originalLanguage != null && report.originalLanguage != 'English') ...[
             Text("Original (${report.originalLanguage}):", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
             Text(report.transcript, style: Theme.of(context).textTheme.bodyMedium),
             const SizedBox(height: 8),
             const Text("English Translation:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
             Text(report.translatedTranscript ?? report.transcript, style: Theme.of(context).textTheme.bodyMedium),
          ] else ...[
             Text(report.transcript.isNotEmpty ? report.transcript : 'No description provided.', 
                  style: Theme.of(context).textTheme.bodyMedium),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Close'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
