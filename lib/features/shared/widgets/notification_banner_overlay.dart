import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';

class NotificationBannerOverlay extends StatelessWidget {
  final Widget child;

  const NotificationBannerOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppNotificationItem?>(
      valueListenable: NotificationService().activeNotificationNotifier,
      builder: (context, notification, _) {
        return Stack(
          children: [
            child,
            if (notification != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Dismissible(
                      key: Key(notification.id),
                      direction: DismissDirection.up,
                      onDismissed: (_) => NotificationService().dismissActiveNotification(),
                      child: GestureDetector(
                        onTap: () {
                          notification.onTap?.call();
                          NotificationService().dismissActiveNotification();
                        },
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF0F172A), // Modern sleek dark slate
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF0284C7).withOpacity(0.4),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.5)),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              notification.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Text(
                                            'Just now',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        notification.body,
                                        style: const TextStyle(
                                          color: Color(0xFFCBD5E1),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                  onPressed: () => NotificationService().dismissActiveNotification(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
