import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/news_repository.dart';

// ── Repository provider ──────────────────────────────────────────────────────

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository();
});

// ── Audio player provider ─────────────────────────────────────────────────────

final _audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

// ── News State ────────────────────────────────────────────────────────────────

enum NewsStatus { idle, loading, loaded, error }

class NewsState {
  final NewsStatus status;
  final String? summaryText;
  final String? errorMessage;
  final bool isPlaying;
  final String? rawResponse; // debug: actual webhook response

  const NewsState({
    this.status = NewsStatus.idle,
    this.summaryText,
    this.errorMessage,
    this.isPlaying = false,
    this.rawResponse,
  });

  NewsState copyWith({
    NewsStatus? status,
    String? summaryText,
    String? errorMessage,
    bool? isPlaying,
    String? rawResponse,
  }) =>
      NewsState(
        status: status ?? this.status,
        summaryText: summaryText ?? this.summaryText,
        errorMessage: errorMessage ?? this.errorMessage,
        isPlaying: isPlaying ?? this.isPlaying,
        rawResponse: rawResponse ?? this.rawResponse,
      );
}

// ── News Notifier ─────────────────────────────────────────────────────────────

class NewsNotifier extends StateNotifier<NewsState> {
  final Ref _ref;

  NewsNotifier(this._ref) : super(const NewsState()) {
    // Track audio player state changes
    _ref.read(_audioPlayerProvider).onPlayerStateChanged.listen((playerState) {
      if (mounted) {
        state = state.copyWith(
          isPlaying: playerState == PlayerState.playing,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Stops any currently playing audio.
  Future<void> stopAudio() async {
    await _ref.read(_audioPlayerProvider).stop();
    if (mounted) {
      state = state.copyWith(isPlaying: false);
    }
  }

  /// Pauses the currently playing audio.
  Future<void> pauseAudio() async {
    await _ref.read(_audioPlayerProvider).pause();
  }

  /// Fetches agri news for the current user+location and plays the audio.
  Future<void> fetchAndPlay() async {
    // Prevent duplicate fetches while already loading
    if (state.status == NewsStatus.loading) return;

    // Stop any current audio first
    await stopAudio();

    state = state.copyWith(status: NewsStatus.loading);

    try {
      // ── Get user ID + language ──
      final authState = _ref.read(authStateProvider);
      String userId = '';
      String language = 'English'; // default
      if (authState is AuthAuthenticated) {
        userId = authState.userId;
        // language is stored as a code e.g. 'ta', 'en', 'hi'
        // Convert to full name for the LLM prompt
        final langCode = authState.language ?? 'en';
        language = _langCodeToName(langCode);
      }

      // ── Get GPS location ──
      double lat = 0;
      double lon = 0;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8),
          );
          lat = pos.latitude;
          lon = pos.longitude;
        }
      } catch (_) {
        // GPS unavailable — proceed with (0, 0)
      }

      // ── Call n8n webhook ──
      final repo = _ref.read(newsRepositoryProvider);
      final result =
          await repo.fetchNews(userId: userId, lat: lat, lon: lon, language: language);

      // Treat empty summary_text as a workflow config error
      if (result.summaryText.isEmpty) {
        state = state.copyWith(
          status: NewsStatus.error,
          rawResponse: result.rawResponse,
          errorMessage:
              'n8n returned no summary_text.\n\nRaw response:\n${result.rawResponse.length > 300 ? result.rawResponse.substring(0, 300) + '...' : result.rawResponse}',
        );
        return;
      }

      state = state.copyWith(
        status: NewsStatus.loaded,
        summaryText: result.summaryText,
        rawResponse: result.rawResponse,
      );

      // ── Decode and play base64 audio ──
      if (result.audioBase64.isNotEmpty) {
        await _playBase64Audio(result.audioBase64);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          status: NewsStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<void> _playBase64Audio(String base64Audio) async {
    try {
      final Uint8List bytes = base64Decode(base64Audio);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/agri_news_audio.mp3');
      await file.writeAsBytes(bytes);

      final player = _ref.read(_audioPlayerProvider);
      await player.play(DeviceFileSource(file.path));
    } catch (e) {
      // Audio play failure is non-fatal — news summary is still shown
    }
  }

  /// Converts language codes to full English names for the LLM prompt.
  String _langCodeToName(String code) {
    const map = {
      'en': 'English',
      'hi': 'Hindi',
      'ta': 'Tamil',
      'te': 'Telugu',
      'mr': 'Marathi',
      'or': 'Odia',
      'bn': 'Bengali',
      'gu': 'Gujarati',
      'kn': 'Kannada',
      'ml': 'Malayalam',
    };
    return map[code.toLowerCase()] ?? 'English';
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  return NewsNotifier(ref);
});
