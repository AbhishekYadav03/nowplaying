import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import 'firestore_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handling
}

class NotificationService {
  final Ref _ref;
  static GlobalKey<ScaffoldMessengerState>? messengerKey;
  static GoRouter? router;

  NotificationService(this._ref);

  Future<void> initialize({required GlobalKey<ScaffoldMessengerState> messengerKey, required GoRouter router}) async {
    NotificationService.messengerKey = messengerKey;
    NotificationService.router = router;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    // Request permissions
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Get and save token
    final token = await messaging.getToken();
    if (token != null) await _saveToken(token);

    // Token refresh
    messaging.onTokenRefresh.listen(_saveToken);

    // 1. Handle background notification click (when app was opened from terminated state)
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }

    // 2. Handle background notification click (when app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showInAppNotification(message);
    });
  }

  static void _handleNotificationClick(RemoteMessage message) {
    final screen = message.data['screen'];
    if (screen == 'feed') {
      router?.go('/');
    } else if (screen == 'friends') {
      router?.go('/friends');
    }
  }

  void _showInAppNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    messengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title ?? 'Notification',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      notification.body ?? '',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  messengerKey?.currentState?.hideCurrentSnackBar();
                  _handleNotificationClick(message);
                },
                child: const Text(
                  'VIEW',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.surfaceHigh,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final service = _ref.read(firestoreServiceProvider);
    await service.updateFcmToken(uid, token);
  }
}
