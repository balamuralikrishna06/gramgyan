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

  if (data != null) {
    return FarmerProfile(
      id: user.uid,
      name: data['name'] as String? ??
          user.displayName ??
          'Farmer',
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      karma: data['karma'] as int? ?? 0,
      totalPosts: 0,
      solutionsVerified: 0,
      language: data['language'] as String? ?? '',
      avatarUrl: user.photoURL ?? '',
      badges: const [],
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
    karma: 0,
    totalPosts: 0,
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
