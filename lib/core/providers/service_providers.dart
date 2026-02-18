import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/audio_recorder_service.dart';
import '../services/gemini_service.dart';
import '../services/text_to_speech_service.dart';
import '../services/sarvam_api_service.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/embedding_service.dart';
import '../services/storage_service.dart';
import '../services/knowledge_service.dart';

final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  return AudioRecorderService();
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final textToSpeechServiceProvider = Provider<TextToSpeechService>((ref) {
  return TextToSpeechService();
});

final sarvamApiServiceProvider = Provider<SarvamApiService>((ref) {
  return SarvamApiService();
});

final speechServiceProvider = Provider<SpeechService>((ref) {
  final sarvamService = ref.read(sarvamApiServiceProvider);
  return SpeechService(sarvamService);
});

final translationServiceProvider = Provider<TranslationService>((ref) {
  final geminiService = ref.read(geminiServiceProvider);
  return TranslationService(geminiService);
});

final embeddingServiceProvider = Provider<EmbeddingService>((ref) {
  return EmbeddingService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(Supabase.instance.client);
});

final knowledgeServiceProvider = Provider<KnowledgeService>((ref) {
  return KnowledgeService(Supabase.instance.client);
});
