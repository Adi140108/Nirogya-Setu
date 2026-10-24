import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// App-wide notifications.
///
/// * [showNotification] posts a notification on THIS device: a system
///   notification in the Android notification panel plus the in-app banner.
/// * [sendToUsers] delivers a notification to OTHER devices: it is written to
///   the Firestore `notifications` collection, and every signed-in device
///   listens ([startListening]) for notifications addressed to its user and
///   shows them in its notification panel.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _collection = 'notifications';
  static const String _deliveredKey = 'aarogya_delivered_notification_ids_v1';
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'aarogya_alerts',
    'Health alerts',
    description: 'Issues raised by citizens, issue updates and health alerts',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final List<AppNotificationItem> _history = [];
  final ValueNotifier<AppNotificationItem?> activeNotificationNotifier = ValueNotifier(null);
  Timer? _dismissTimer;
  bool _initialized = false;
  int _nextSystemId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String _listeningKey = '';
  Set<String> _delivered = {};

  List<AppNotificationItem> get history => List.unmodifiable(_history);

  /// Sets up the Android notification channel. Safe to call more than once.
  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      final prefs = await SharedPreferences.getInstance();
      _delivered = (prefs.getStringList(_deliveredKey) ?? const []).toSet();
      _initialized = true;
    } catch (e) {
      debugPrint('Notification setup notice: $e');
    }
  }

  /// Asks for the Android 13+ "Allow notifications" permission.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await init();
    try {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? true;
    } catch (e) {
      debugPrint('Notification permission notice: $e');
      return false;
    }
  }

  /// Shows a notification on this device (system notification panel + in-app banner).
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
    unawaited(_showSystemNotification(title, body));

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

  Future<void> _showSystemNotification(String title, String body) async {
    if (kIsWeb) return;
    await init();
    if (!_initialized) return;
    try {
      await _plugin.show(
        _nextSystemId++,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
      );
      debugPrint('[Notifications] posted to system tray: $title');
    } catch (e) {
      debugPrint('System notification notice: $e');
    }
  }

  // --- Cross-device delivery through Cloud Firestore ---

  bool get _cloudAvailable => Firebase.apps.isNotEmpty;

  /// Sends a notification to the given users' devices.
  Future<void> sendToUsers({
    required List<String> recipientIds,
    required String title,
    required String body,
    String type = 'general',
    String? issueId,
  }) async {
    final recipients = recipientIds.where((id) => id.trim().isNotEmpty).toSet();
    if (!_cloudAvailable || recipients.isEmpty) return;
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now().toIso8601String();
    for (final recipientId in recipients) {
      try {
        final doc = firestore.collection(_collection).doc();
        await doc.set({
          'id': doc.id,
          'recipientId': recipientId,
          'title': title,
          'body': body,
          'type': type,
          'issueId': issueId,
          'createdAt': now,
        }).timeout(const Duration(seconds: 10));
      } catch (e) {
        // Firestore keeps the write queued offline and sends it when back online.
        debugPrint('Notification send queued/failed for $recipientId: $e');
      }
    }
  }

  /// Listens for notifications addressed to [recipientIds] (the signed-in user)
  /// and shows each new one in the notification panel exactly once.
  Future<void> startListening(List<String> recipientIds) async {
    final ids = recipientIds.where((id) => id.trim().isNotEmpty).toSet().take(30).toList()..sort();
    final key = ids.join('|');
    if (key == _listeningKey) return;
    await stopListening();
    if (!_cloudAvailable || ids.isEmpty) return;
    await init();
    _listeningKey = key;
    debugPrint('[Notifications] listening for recipients: $ids');

    final cutoff = DateTime.now().subtract(const Duration(days: 2));
    _subscription = FirebaseFirestore.instance
        .collection(_collection)
        .where('recipientId', whereIn: ids)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null || _delivered.contains(change.doc.id)) continue;
        debugPrint('[Notifications] received ${change.doc.id} for ${data['recipientId']}');
        final created = DateTime.tryParse(data['createdAt']?.toString() ?? '');
        _markDelivered(change.doc.id);
        if (created == null || created.isBefore(cutoff)) continue;
        showNotification(
          title: data['title']?.toString() ?? 'Aarogya Setu',
          body: data['body']?.toString() ?? '',
          category: data['type']?.toString(),
        );
      }
    }, onError: (Object e) => debugPrint('Notification listener paused: $e'));
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    _listeningKey = '';
  }

  void _markDelivered(String id) {
    _delivered.add(id);
    if (_delivered.length > 500) {
      _delivered = _delivered.skip(_delivered.length - 400).toSet();
    }
    SharedPreferences.getInstance().then((prefs) => prefs.setStringList(_deliveredKey, _delivered.toList()));
  }
}
