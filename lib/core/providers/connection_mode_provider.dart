import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track whether the app is in Online (Cloud AI) or Offline (Local AI) mode.
/// True = Online (Gemini), False = Offline (Ollama).
final connectionModeProvider = StateProvider<bool>((ref) => true);
