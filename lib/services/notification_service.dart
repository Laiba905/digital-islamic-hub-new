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
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
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
          fullScreenIntent: true, // Lock screen par bhi dikhayega
        ),
      ),
    );
  }

  static Future<void> schedulePrayerNotification(int id, String name, DateTime time) async {
    var scheduledTime = tz.TZDateTime.from(time, tz.local);

    // Agar waqt guzar gaya hai to kal ke liye schedule karein
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Exact timing k liye
      matchDateTimeComponents: DateTimeComponents.time, // Har roz usi waqt repeat hoga
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }
}