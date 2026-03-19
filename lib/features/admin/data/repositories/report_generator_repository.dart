import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_user.dart';

/// Repository that handles all data operations for the Report Generator feature.
///
/// Responsibilities:
///   - Fetch [ReportUser] records from Supabase [report_users] table.
///   - Insert new [ReportUser] records.
///   - Trigger the n8n report-generation webhook for a given user.
class ReportGeneratorRepository {
  final SupabaseClient _client;

  static const String _table = 'report_users';
  static const String _webhookUrl =
      'https://bala006.app.n8n.cloud/webhook/generate-report';

  const ReportGeneratorRepository(this._client);

  // ── Fetch ──────────────────────────────────────────────────────────────────

  /// Returns all stored report users, newest first.
  Future<List<ReportUser>> fetchReportUsers() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false);

      return response
          .map((json) => ReportUser.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('ReportGeneratorRepository.fetchReportUsers error: $e');
      rethrow;
    }
  }

  // ── Insert ─────────────────────────────────────────────────────────────────

  /// Inserts a new record into [report_users] and returns the inserted row.
  Future<ReportUser> addReportUser({
    required String name,
    required String email,
    required String position,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .insert({
            'name': name,
            'email': email,
            'position': position,
          })
          .select()
          .single();

      return ReportUser.fromJson(response);
    } catch (e) {
      debugPrint('ReportGeneratorRepository.addReportUser error: $e');
      rethrow;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Deletes a record from [report_users] by its UUID.
  Future<void> deleteReportUser(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
      debugPrint('ReportGeneratorRepository: deleted user $id');
    } catch (e) {
      debugPrint('ReportGeneratorRepository.deleteReportUser error: $e');
      rethrow;
    }
  }

  // ── Webhook ────────────────────────────────────────────────────────────────

  /// Sends a POST request to the n8n webhook with the given [user]'s details.
  ///
  /// Throws an [Exception] if the server returns a non-2xx status.
  Future<void> sendWebhook(ReportUser user) async {
    final payload = {
      'name': user.name,
      'email': user.email,
      'position': user.position,
      'source': 'GramGyan Admin',
      'time': DateTime.now().toUtc().toIso8601String(),
    };

    debugPrint('Sending webhook to $_webhookUrl with payload: $payload');

    try {
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Webhook failed with status ${response.statusCode}: ${response.body}',
        );
      }

      debugPrint('Webhook sent successfully: ${response.statusCode}');
    } catch (e) {
      debugPrint('ReportGeneratorRepository.sendWebhook error: $e');
      rethrow;
    }
  }
}
