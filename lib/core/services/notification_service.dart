import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _client;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService(this._client);

  Future<void> init() async {
    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Start listening to Realtime updates
    _listenToAnswers();
  }

  void _listenToAnswers() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _client
        .from('answers')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId) // Listen filters might need adjustment based on RLS
        .listen((List<Map<String, dynamic>> data) {
          // In a real app, you'd filter for *new* inserts only or distinct changes
          // For MVP, we'll just log or show a sample notification if list is non-empty
          if (data.isNotEmpty) {
            _showNotification(
              'New Answer Received!',
              'Someone from the community answered your question.',
            );
          }
        });
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gramgyan_channel',
      'GramGyan Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
