import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'api_service.dart';
import '../models/appointment.dart';

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

  // Appointment reminder offsets, keyed to Appointment.remind* flags.
  static const _reminderOffsets = {
    'r24h': (Duration(hours: 24), '24 hours'),
    'r3h':  (Duration(hours: 3),  '3 hours'),
    'r2h':  (Duration(hours: 2),  '2 hours'),
    'r1h':  (Duration(hours: 1),  '1 hour'),
  };

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

    // Needed for zonedSchedule (appointment reminders).
    tz_data.initializeTimeZones();

    // Register FCM token with backend
    final token = await _fcm.getToken();
    if (token != null) {
      try {
        await ApiService.registerFcmToken(token);
      } catch (e) {
        debugPrint('NotificationService: failed to register FCM token: $e');
      }
    }

    // Refresh token listener
    _fcm.onTokenRefresh.listen((t) async {
      try {
        await ApiService.registerFcmToken(t);
      } catch (e) {
        debugPrint('NotificationService: failed to refresh FCM token: $e');
      }
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

  static int _reminderNotifId(String appointmentId, String key) =>
      Object.hash(appointmentId, key) & 0x7fffffff;

  /// Schedules on-device reminders for an appointment as a fallback that
  /// doesn't depend on the backend sending a push in time. Any previously
  /// scheduled reminders for this appointment are cleared first.
  static Future<void> scheduleAppointmentReminders(Appointment appt) async {
    await cancelAppointmentReminders(appt.id);

    final dt = DateTime.tryParse(appt.appointmentDatetime)?.toUtc();
    if (dt == null) return;

    final flags = {
      'r24h': appt.remind24h,
      'r3h':  appt.remind3h,
      'r2h':  appt.remind2h,
      'r1h':  appt.remind1h,
    };

    for (final entry in flags.entries) {
      if (!entry.value) continue;
      final (offset, label) = _reminderOffsets[entry.key]!;
      final fireAt = dt.subtract(offset);
      if (fireAt.isBefore(DateTime.now().toUtc())) continue;

      final subtitleParts = <String>[
        'In $label',
        if (appt.doctorName.isNotEmpty) 'with ${appt.doctorName}',
        if (appt.location.isNotEmpty) 'at ${appt.location}',
      ];

      try {
        await _local.zonedSchedule(
          _reminderNotifId(appt.id, entry.key),
          appt.title.isEmpty ? 'Upcoming appointment' : appt.title,
          subtitleParts.join(' '),
          tz.TZDateTime.from(fireAt, tz.UTC),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id, _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('NotificationService: failed to schedule ${entry.key} reminder: $e');
      }
    }
  }

  static Future<void> cancelAppointmentReminders(String appointmentId) async {
    for (final key in _reminderOffsets.keys) {
      await _local.cancel(_reminderNotifId(appointmentId, key));
    }
  }
}
