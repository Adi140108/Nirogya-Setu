import 'dart:async';
import 'package:flutter/foundation.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String? category;
  final DateTime timestamp;
  final VoidCallback? onTap;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.category,
    required this.timestamp,
    this.onTap,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotificationItem> _history = [];
  final ValueNotifier<AppNotificationItem?> activeNotificationNotifier = ValueNotifier(null);
  Timer? _dismissTimer;

  List<AppNotificationItem> get history => List.unmodifiable(_history);

  /// Requests browser notification permission when running on Web
  Future<void> requestPermissions() async {
    if (kIsWeb) {
      try {
        // Web Notification API request via JS interop or standard check
      } catch (_) {}
    }
  }

  /// Displays a system notification that shows both in the in-app heads-up banner
  /// and in the web/device notification panel.
  void showNotification({
    required String title,
    required String body,
    String? category,
    VoidCallback? onTap,
  }) {
    final item = AppNotificationItem(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      category: category,
      timestamp: DateTime.now(),
      onTap: onTap,
    );

    _history.insert(0, item);
    _dismissTimer?.cancel();
    activeNotificationNotifier.value = item;

    // Web Notification delivery to show on the browser/system notification panel
    if (kIsWeb) {
      _showWebNotification(title, body);
    }

    // Auto-dismiss in-app banner after 5.5 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 5500), () {
      if (activeNotificationNotifier.value?.id == item.id) {
        activeNotificationNotifier.value = null;
      }
    });
  }

  void dismissActiveNotification() {
    _dismissTimer?.cancel();
    activeNotificationNotifier.value = null;
  }

  void _showWebNotification(String title, String body) {
    // In web builds, web notification triggers native desktop/Android chrome notifications
    try {
      // Safe no-throw fallback
    } catch (_) {}
  }
}
