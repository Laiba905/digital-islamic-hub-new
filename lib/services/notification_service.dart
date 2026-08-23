import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'prayer_alerts',
      'Prayer Notifications',
      description: 'Namaz ke auqat par Azan play karne ke liye',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('azan'),
    );

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ notification permission aur Android 12+ Exact alarm permission
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      // iOS specific permissions request
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> testInstant() async {
    await _plugin.show(
      99,
      "حي على الصلاة",
      "Azan sound testing... Allah-hu-Akbar!",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_alerts', 'Prayer Notifications',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('azan'),
          fullScreenIntent: true,
        ),
      ),
    );
  }

  static Future<void> schedulePrayerNotification(int id, String name, DateTime time) async {
    // 🚀 FIX 1: Hard device timezone conversion strategy using dynamic ISO parsing
    final String timeZoneName = tz.local.name;
    final location = tz.getLocation(timeZoneName);

    var scheduledTime = tz.TZDateTime.from(time, location);
    var now = tz.TZDateTime.now(location);

    // 🚀 FIX 2: Safe evaluation fallback logic for testing bypass
    if (scheduledTime.isBefore(now)) {
      if (now.difference(scheduledTime).inMinutes > 2) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
    }

    await _plugin.zonedSchedule(
      id,
      "Time for $name",
      "Allah-hu-Akbar! It's time for $name prayer.",
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_alerts',
          'Prayer Notifications',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('azan'),
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Daily automatic repetition trigger
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }
}
