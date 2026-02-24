import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: isDark ? AppColors.dividerDark : AppColors.divider,
            ),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isUnread = !notification.isRead;

              return InkWell(
                onTap: () {
                  if (isUnread) {
                    ref.read(notificationRepositoryProvider).markAsRead(notification.id);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadNotificationsCountProvider);
                  }
                  if (notification.questionId != null) {
                    context.push('/discussion/${notification.questionId}');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  color: isUnread 
                      ? (isDark ? AppColors.accent.withValues(alpha: 0.1) : AppColors.accentLight.withValues(alpha: 0.1))
                      : Colors.transparent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.dividerDark : AppColors.divider,
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          size: 20,
                          color: isUnread ? AppColors.accent : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              timeago.format(notification.createdAt),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
