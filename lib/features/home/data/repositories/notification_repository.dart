import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/app_notification.dart';

class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository(this._client);

  Future<List<AppNotification>> getNotifications(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<int> getUnreadCount(String userId) async {
     if (userId.isEmpty) return 0;
     try {
       final response = await _client
           .from('notifications')
           .select('id')
           .eq('user_id', userId)
           .eq('is_read', false)
           .count(CountOption.exact);
       return response.count ?? 0;
     } catch (e) {
       debugPrint('Error counting unread notifications: $e');
       return 0;
     }
  }
}

