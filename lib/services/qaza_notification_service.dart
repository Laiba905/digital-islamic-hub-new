import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import 'qaza_storage.dart';

/// Har notification action ka unique id -> prayer name map karne ke liye
/// action id ko "add_prayerName" format mein rakhenge.
const String _addActionPrefix = 'add_';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

class QazaNotificationService {
  static Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    // Android 13+ pe runtime permission
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Ek prayer ke liye reminder notification jisme "Qaza Add Karein" button ho.
  static Future<void> showQazaReminder(String prayer) async {
    final actionId = '$_addActionPrefix$prayer';

    final androidDetails = AndroidNotificationDetails(
      'qaza_channel',
      'Qaza Reminders',
      channelDescription: 'Reminders to log missed prayers',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          actionId,
          'Add Qaza',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      prayer.hashCode, // har prayer ka unique notification id
      'Qaza Namaz Reminder',
      'Kya aap ne $prayer qaza chorhi thi? Tap karke add karein.',
      details,
      payload: prayer,
    );
  }

  /// Sab prayers ke liye daily fixed time pe scheduled reminder.
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'qaza_daily_channel',
      'Daily Qaza Reminder',
      channelDescription: 'Daily reminder to check qaza record',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      9999,
      'Qaza Namaz',
      'Apna qaza record check karein aur update karein.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime, // roz repeat
    );
  }

  static void _onForegroundResponse(NotificationResponse response) {
    _handleAction(response);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse response) {
    _handleAction(response);
  }

  static void _handleAction(NotificationResponse response) {
    final actionId = response.actionId;
    String? prayer;

    if (actionId != null && actionId.startsWith(_addActionPrefix)) {
      prayer = actionId.substring(_addActionPrefix.length);
    } else {
      prayer = response.payload;
    }

    if (prayer != null && prayer.isNotEmpty) {
      // App band ho ya open, dono halaton mein storage update hoga.
      QazaStorage.incrementQaza(prayer);
    }
  }
}
