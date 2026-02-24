import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState is AuthAuthenticated ? authState.userId : '';

  if (userId.isEmpty) return [];

  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications(userId);
});

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState is AuthAuthenticated ? authState.userId : '';

  if (userId.isEmpty) return 0;

  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount(userId);
});
