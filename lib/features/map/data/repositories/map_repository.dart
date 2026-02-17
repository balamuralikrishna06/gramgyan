import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/report.dart';

class MapRepository {
  final SupabaseClient _supabase;

  MapRepository(this._supabase);

  /// Fetches all reports from the 'reports' table.
  Future<List<Report>> getReports() async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Report.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Subscribes to real-time updates for the 'reports' table.
  Stream<List<Report>> subscribeToReports() {
    return _supabase
        .from('reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Report.fromJson(json)).toList());
  }
}
