import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A simple HTTP client that tries a primary URL and automatically
/// falls back to a secondary URL if the primary fails or times out.
class FailoverHttpClient {
  final String primaryUrl;
  final String fallbackUrl;
  final Duration timeout;

  const FailoverHttpClient({
    required this.primaryUrl,
    required this.fallbackUrl,
    this.timeout = const Duration(seconds: 30),
  });

  /// POST with JSON body. Tries primary, then fallback on any error.
  Future<http.Response> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };
    final encodedBody = jsonEncode(body);

    // Try primary
    try {
      final uri = Uri.parse('$primaryUrl$path');
      debugPrint('[FailoverHttpClient] POST $uri (primary)');
      final response = await http
          .post(uri, headers: headers, body: encodedBody)
          .timeout(timeout);
      if (response.statusCode < 500) return response; // success or 4xx (don't retry)
      debugPrint('[FailoverHttpClient] Primary returned ${response.statusCode}, trying fallback...');
    } catch (e) {
      debugPrint('[FailoverHttpClient] Primary failed: $e — switching to fallback');
    }

    // Fallback
    final fallbackUri = Uri.parse('$fallbackUrl$path');
    debugPrint('[FailoverHttpClient] POST $fallbackUri (fallback)');
    return await http
        .post(fallbackUri, headers: headers, body: encodedBody)
        .timeout(timeout);
  }

  /// GET request. Tries primary, then fallback on any error.
  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = {'Content-Type': 'application/json', ...?extraHeaders};

    // Try primary
    try {
      final uri = Uri.parse('$primaryUrl$path')
          .replace(queryParameters: queryParams);
      debugPrint('[FailoverHttpClient] GET $uri (primary)');
      final response = await http
          .get(uri, headers: headers)
          .timeout(timeout);
      if (response.statusCode < 500) return response;
      debugPrint('[FailoverHttpClient] Primary returned ${response.statusCode}, trying fallback...');
    } catch (e) {
      debugPrint('[FailoverHttpClient] Primary failed: $e — switching to fallback');
    }

    // Fallback
    final fallbackUri = Uri.parse('$fallbackUrl$path')
        .replace(queryParameters: queryParams);
    debugPrint('[FailoverHttpClient] GET $fallbackUri (fallback)');
    return await http
        .get(fallbackUri, headers: headers)
        .timeout(timeout);
  }
}
