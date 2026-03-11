import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Repository responsible for fetching agri news from the n8n webhook.
class NewsRepository {
  static const String _webhookUrl =
      'https://balamuralikrishna06.app.n8n.cloud/webhook/get-agri-news';

  /// Sends a POST request with [userId], [lat], [lon] to the n8n webhook. 
  ///
  /// Returns a [NewsResult] containing the summary text and base64 audio.
  /// Throws an [Exception] on HTTP error.
  Future<NewsResult> fetchNews({
    required String userId,
    required double lat,
    required double lon,
    String language = 'English',
  }) async {
    final payload = {
      'user_id': userId,
      'lat': lat,
      'lon': lon,
      'language': language,
    };

    debugPrint('[NewsRepository] POST $_webhookUrl payload=$payload');

    final response = await http
        .post(
          Uri.parse(_webhookUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'News webhook failed [${response.statusCode}]: ${response.body}');
    }

    // Guard against empty body
    final rawBody = response.body.trim();
    debugPrint('[NewsRepository] Raw response (${rawBody.length} chars): $rawBody');

    if (rawBody.isEmpty) {
      throw Exception(
          'n8n returned an empty body.\n\n'
          'Fix: In your n8n "Respond to Webhook" node, make sure the '
          'Response Body fields are configured with expressions (⚡ icon) '
          'returning summary_text and audio_file.');
    }

    // n8n webhooks return a JSON array by default: [{"summary_text": "...", "audio_file": "..."}]
    // Also handle plain object format for flexibility.
    final decoded = jsonDecode(response.body);

    Map<String, dynamic> data;
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      // n8n sometimes wraps in {"json": {...}} per item
      if (first is Map<String, dynamic> && first.containsKey('json')) {
        data = first['json'] as Map<String, dynamic>;
      } else {
        data = first as Map<String, dynamic>;
      }
    } else if (decoded is Map<String, dynamic>) {
      data = decoded;
    } else {
      throw Exception('Unexpected response format from news webhook');
    }

    debugPrint('[NewsRepository] Parsed data: $data');

    return NewsResult(
      summaryText: data['summary_text'] as String? ?? '',
      audioBase64: data['audio_file'] as String? ?? '',
      rawResponse: response.body,
    );
  }
}

/// Holds the parsed response from the news webhook.
class NewsResult {
  final String summaryText;
  final String audioBase64;
  final String rawResponse;

  const NewsResult({
    required this.summaryText,
    required this.audioBase64,
    required this.rawResponse,
  });
}
