import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Must be top-level for background handling
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main before this runs
}

class NotificationService {
  static final _fcm   = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'healthcompass_high',
    'HealthCompass Alerts',
    description: 'Health alerts, AI predictions, and record updates',
    importance: Importance.high,
  );

  static Future<void> init() async {
    // Request permission (Android 13+, iOS)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Local notifications init
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(const InitializationSettings(android: androidSettings));

    // Create high-importance channel (Android 8+)
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Register FCM token with backend
    final token = await _fcm.getToken();
    if (token != null) {
      try { await ApiService.registerFcmToken(token); } catch (_) {}
    }

    // Refresh token listener
    _fcm.onTokenRefresh.listen((t) async {
      try { await ApiService.registerFcmToken(t); } catch (_) {}
    });

    // Show notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_showLocal);
  }

  static Future<void> _showLocal(RemoteMessage msg) async {
    final n = msg.notification;
    if (n == null) return;
    await _local.show(
      msg.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
