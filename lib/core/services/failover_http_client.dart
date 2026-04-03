import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  /// POST multipart/form-data. Tries primary, then fallback on any error.
  Future<http.Response> postMultipart(
    String path, {
    required File file,
    required String fileField,
    String? mimeType,
    Map<String, String>? fields,
    Map<String, String>? extraHeaders,
  }) async {
    Future<http.Response> _sendTo(String baseUrl) async {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.MultipartRequest('POST', uri);
      if (extraHeaders != null) request.headers.addAll(extraHeaders);
      if (fields != null) request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath(
        fileField,
        file.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
      final streamed = await request.send().timeout(timeout);
      return http.Response.fromStream(streamed);
    }

    // Try primary
    try {
      debugPrint('[FailoverHttpClient] POST multipart $primaryUrl$path (primary)');
      final response = await _sendTo(primaryUrl);
      if (response.statusCode < 500) return response;
      debugPrint('[FailoverHttpClient] Primary returned ${response.statusCode}, trying fallback...');
    } catch (e) {
      debugPrint('[FailoverHttpClient] Primary multipart failed: $e — switching to fallback');
    }

    // Fallback
    debugPrint('[FailoverHttpClient] POST multipart $fallbackUrl$path (fallback)');
    return await _sendTo(fallbackUrl);
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
