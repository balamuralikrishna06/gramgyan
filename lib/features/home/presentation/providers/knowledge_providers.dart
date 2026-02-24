import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/knowledge_post.dart';
import '../../data/repositories/supabase_knowledge_repository.dart';

/// Repository provider (singleton).
final knowledgeRepositoryProvider = Provider<SupabaseKnowledgeRepository>((ref) {
  return SupabaseKnowledgeRepository(Supabase.instance.client);
});

/// Currently selected category filter.
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

/// Fetches knowledge posts based on the selected category.
final knowledgePostsProvider = FutureProvider<List<KnowledgePost>>((ref) async {
  final repo = ref.read(knowledgeRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  return repo.fetchPostsByCategory(category);
});

/// Map of post ID → karma count (for local upvotes).
final karmaMapProvider = StateProvider<Map<String, int>>((ref) => {});

/// Set of post IDs the user has already upvoted.
final upvotedPostsProvider = StateProvider<Set<String>>((ref) => {});

/// Search query for filtering posts.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Simulated audio playback state — stores the ID of the currently playing post.
final playingPostIdProvider = StateProvider<String?>((ref) => null);
