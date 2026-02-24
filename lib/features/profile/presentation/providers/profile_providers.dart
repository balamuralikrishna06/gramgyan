import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/auth_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../domain/models/farmer_profile.dart';

/// Fetches the farmer profile from Supabase `users` table.
/// Falls back to auth metadata if DB fetch fails.
final farmerProfileProvider = FutureProvider<FarmerProfile>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  
  // If not authenticated, return guest/empty profile immediately
  if (authState is! AuthAuthenticated && authState is! AuthProfileIncomplete) {
     return const FarmerProfile(
      id: '',
      name: 'Guest',
      city: '',
      state: '',
      karma: 0,
      totalPosts: 0,
      language: '',
    );
  }

  final user = repo.currentUser;
  if (user == null) {
     return const FarmerProfile(
      id: '',
      name: 'Guest',
      city: '',
      state: '',
      karma: 0,
      totalPosts: 0,
      language: '',
    );
  }
  // Try to fetch from Backend
  final data = await repo.fetchUserProfile();

  int calculatedKarma = data != null ? (data['karma'] as int? ?? 0) : 0;
  int totalPosts = 0;
  int solutionsVerified = 0;
  List<String> badges = [];

  try {
    final client = Supabase.instance.client;

    // 1. Get Questions count and karma
    final questions = await client.from('questions').select('karma').eq('user_id', user.uid);
    totalPosts += (questions as List).length;
    for (var q in questions) {
      calculatedKarma += (q['karma'] as int? ?? 0);
    }

    // 2. Get Knowledge Posts count and likes
    final kPosts = await client.from('knowledge_posts').select('likes_count').eq('user_id', user.uid);
    totalPosts += (kPosts as List).length;
    for (var k in kPosts) {
      calculatedKarma += (k['likes_count'] as int? ?? 0);
    }

    // 3. Get Answers for verified solutions and karma
    final answers = await client.from('answers').select('karma, is_verified').eq('user_id', user.uid);
    for (var a in answers) {
      calculatedKarma += (a['karma'] as int? ?? 0);
      if (a['is_verified'] == true) {
        solutionsVerified++;
      }
    }

    // Basic badge logic
    if (solutionsVerified >= 1) badges.add('first_solution');
    if (solutionsVerified >= 5) badges.add('top_contributor');
    if (totalPosts >= 10) badges.add('active_farmer');
  } catch (e) {
    // Silently continue if stats fail to load
  }

  if (data != null) {
    return FarmerProfile(
      id: user.uid,
      name: data['name'] as String? ??
          user.displayName ??
          'Farmer',
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      karma: calculatedKarma,
      totalPosts: totalPosts,
      solutionsVerified: solutionsVerified,
      language: data['language'] as String? ?? '',
      avatarUrl: user.photoURL ?? '',
      badges: badges,
    );
  }

  // Fallback: use auth metadata only
  return FarmerProfile(
    id: user.uid,
    name: user.displayName ??
        user.email?.split('@').first ??
        'Farmer',
    city: '',
    state: '',
    karma: calculatedKarma,
    totalPosts: totalPosts,
    language: '',
    avatarUrl: user.photoURL ?? '',
  );
});

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});

class ProfileController {
  final Ref _ref;
  ProfileController(this._ref);

  Future<void> updateLanguage(String newLanguage) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    
    // Get existing profile data to preserve it during update
    final currentProfile = _ref.read(farmerProfileProvider).valueOrNull;

    try {
      await _ref.read(authRepositoryProvider).updateProfile(
        name: currentProfile?.name ?? user.displayName ?? 'Farmer',
        state: currentProfile?.state ?? '',
        city: currentProfile?.city ?? '',
        language: newLanguage,
        role: 'farmer',
      );
      
      // Invalidate the profile provider to reflect changes
      _ref.invalidate(farmerProfileProvider);
    } catch (e) {
      throw Exception('Failed to update language: $e');
    }
  }
}
