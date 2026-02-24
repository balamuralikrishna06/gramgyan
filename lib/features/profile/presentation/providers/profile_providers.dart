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
  int totalPosts = data != null ? (data['total_posts'] as int? ?? 0) : 0;
  int solutionsVerified = data != null ? (data['solutions_verified'] as int? ?? 0) : 0;
  List<String> badges = [];

  // Basic badge logic based on the user table fields
  if (solutionsVerified >= 1) badges.add('first_solution');
  if (solutionsVerified >= 5) badges.add('top_contributor');
  if (totalPosts >= 10) badges.add('active_farmer');

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
