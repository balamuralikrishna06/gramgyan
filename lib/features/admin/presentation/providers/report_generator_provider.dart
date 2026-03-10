import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/report_user.dart';
import '../../data/repositories/report_generator_repository.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

final reportGeneratorRepositoryProvider =
    Provider<ReportGeneratorRepository>((ref) {
  return ReportGeneratorRepository(Supabase.instance.client);
});

// ── State ─────────────────────────────────────────────────────────────────────

/// State class for the report generator list.
class ReportGeneratorState {
  final List<ReportUser> users;
  final bool isLoading;
  final String? error;

  const ReportGeneratorState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  ReportGeneratorState copyWith({
    List<ReportUser>? users,
    bool? isLoading,
    String? error,
  }) {
    return ReportGeneratorState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ReportGeneratorNotifier extends StateNotifier<ReportGeneratorState> {
  final ReportGeneratorRepository _repo;

  ReportGeneratorNotifier(this._repo) : super(const ReportGeneratorState()) {
    fetchUsers();
  }

  /// Load all report users from Supabase.
  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repo.fetchReportUsers();
      state = ReportGeneratorState(users: users);
    } catch (e) {
      state = ReportGeneratorState(error: e.toString());
    }
  }

  /// Insert a new person and refresh the list.
  Future<void> addPerson({
    required String name,
    required String email,
    required String position,
  }) async {
    await _repo.addReportUser(name: name, email: email, position: position);
    await fetchUsers();
  }

  /// Delete a person and refresh the list.
  Future<void> deletePerson(String id) async {
    await _repo.deleteReportUser(id);
    await fetchUsers();
  }

  /// Trigger the n8n webhook for the given user.
  Future<void> sendReport(ReportUser user) async {
    await _repo.sendWebhook(user);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final reportGeneratorProvider =
    StateNotifierProvider<ReportGeneratorNotifier, ReportGeneratorState>((ref) {
  final repo = ref.watch(reportGeneratorRepositoryProvider);
  return ReportGeneratorNotifier(repo);
});
