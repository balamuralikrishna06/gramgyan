import 'gemini_service.dart';

class TranslationService {
  final GeminiService _geminiService;

  TranslationService(this._geminiService);

  Future<String> translate(String text, {String targetLang = 'English'}) async {
    return await _geminiService.translateText(text, targetLang);
  }
}
