import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../auth/domain/models/auth_state.dart';

import '../models/question.dart';
import '../models/solution.dart';
import '../repository/mock_discussion_repository.dart';

/// Singleton repository instance.
final discussionRepositoryProvider = Provider<MockDiscussionRepository>((ref) {
  return MockDiscussionRepository();
});

/// Discussion status tab filter: 'All', 'Questions', 'Solved', 'Verified'.
final selectedQuestionStatusProvider = StateProvider<String>((ref) => 'All');

/// Sort mode for questions.
final questionSortProvider = StateProvider<String>((ref) => 'Latest');

/// Search query to filter questions by crop name.
final questionSearchProvider = StateProvider<String>((ref) => '');

/// Provides the filtered & sorted list of questions.
final questionsProvider = FutureProvider<List<Question>>((ref) async {
  final repo = ref.read(discussionRepositoryProvider);
  final statusFilter = ref.watch(selectedQuestionStatusProvider);
  final sortMode = ref.watch(questionSortProvider);
  final search = ref.watch(questionSearchProvider).toLowerCase();

  var questions = await repo.getQuestions();

  // Status filter
  if (statusFilter == 'Questions') {
    questions = questions
        .where((q) => q.status == QuestionStatus.open)
        .toList();
  } else if (statusFilter == 'Solved') {
    questions = questions
        .where((q) => q.status == QuestionStatus.solved)
        .toList();
  } else if (statusFilter == 'Verified') {
    questions = questions
        .where((q) => q.status == QuestionStatus.verified)
        .toList();
  } else if (statusFilter == 'My Questions') {
    final authState = ref.watch(authStateProvider);
    if (authState is AuthAuthenticated) {
      questions = questions
          .where((q) => q.authorId == authState.userId)
          .toList();
    } else {
      questions = [];
    }
  }

  // Search by crop
  if (search.isNotEmpty) {
    questions = questions
        .where((q) => q.crop.toLowerCase().contains(search))
        .toList();
  }

  // Sort
  switch (sortMode) {
    case 'Most Replied':
      questions.sort((a, b) => b.replyCount.compareTo(a.replyCount));
      break;
    case 'Most Karma':
      questions.sort((a, b) => b.karma.compareTo(a.karma));
      break;
    case 'Latest':
    default:
      questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
  }

  return questions;
});

/// Solutions for a specific question (family provider).
final solutionsProvider =
    FutureProvider.family<List<Solution>, String>((ref, questionId) async {
  final repo = ref.read(discussionRepositoryProvider);
  return repo.getSolutions(questionId);
});

/// Set of solution IDs the current user has upvoted.
final upvotedSolutionsProvider = StateProvider<Set<String>>((ref) => {});

/// Currently playing audio ID in discussion screens.
final discussionPlayingIdProvider = StateProvider<String?>((ref) => null);
