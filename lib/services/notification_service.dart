import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here if needed
}

class NotificationService {
  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    // Request permissions (iOS)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and save token
    final token = await messaging.getToken();
    if (token != null) await _saveToken(token);

    // Token refresh
    messaging.onTokenRefresh.listen(_saveToken);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      // TODO: Show in-app snackbar/notification overlay
      // This is handled in the UI layer with a listener
    });
  }

  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final service = FirestoreService();
    await service.updateFcmToken(uid, token);
  }
}
