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

  final user = Supabase.instance.client.auth.currentUser;
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
  // Try to fetch from Supabase DB
  final data = await repo.fetchUserProfile();

  if (data != null) {
    return FarmerProfile(
      id: user.id,
      name: data['name'] as String? ??
          user.userMetadata?['full_name'] as String? ??
          'Farmer',
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      karma: data['karma'] as int? ?? 0,
      totalPosts: 0,
      solutionsVerified: 0,
      language: data['language'] as String? ?? '',
      avatarUrl: user.userMetadata?['avatar_url'] as String? ?? '',
      badges: const [],
    );
  }

  // Fallback: use auth metadata only
  return FarmerProfile(
    id: user.id,
    name: user.userMetadata?['full_name'] as String? ??
        user.email?.split('@').first ??
        'Farmer',
    city: '',
    state: '',
    karma: 0,
    totalPosts: 0,
    language: '',
    avatarUrl: user.userMetadata?['avatar_url'] as String? ?? '',
  );
});
