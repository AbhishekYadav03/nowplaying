import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import 'firestore_service.dart';
import 'media_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Silent media control in background if possible
  if (message.data['action'] == 'media_control') {
    // Note: Background execution is limited. For full background control,
    // you'd typically use a platform-specific background task or a high-priority message.
  }
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

    // 1. Handle background notification click
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }

    // 2. Handle background notification click (when app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      if (message.data['action'] == 'media_control') {
        _handleMediaControl(message);
      }
      _showInAppNotification(message);
    });
  }

  void _handleMediaControl(RemoteMessage message) {
    final command = message.data['command'];
    final mediaService = _ref.read(mediaServiceProvider);

    switch (command) {
      case 'play':
        mediaService.play();
        break;
      case 'pause':
        mediaService.pause();
        break;
      case 'skipNext':
        mediaService.skipNext();
        break;
      case 'skipPrevious':
        mediaService.skipPrevious();
        break;
    }
  }

  static void _handleNotificationClick(RemoteMessage message) {
    // If it's a media control click, we might just want to go to feed
    final screen = message.data['screen'] ?? 'feed';
    if (screen == 'feed') {
      router?.go('/');
    } else if (screen == 'friends') {
      router?.go('/friends');
    }
  }

  void _showInAppNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    messengerKey?.currentState?.hideCurrentSnackBar();
    messengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            messengerKey?.currentState?.hideCurrentSnackBar();
            _handleNotificationClick(message);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  message.data['action'] == 'media_control'
                      ? Icons.settings_remote_rounded
                      : Icons.notifications_active,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title ?? 'Notification',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.body ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.surfaceHigh,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
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
