import 'package:flutter/foundation.dart'; // kIsWeb ke liye
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) return; // Web par notifications skip karein

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
    if (kIsWeb) return;
    
    // Platform.isAndroid ki jagah Implementation check use karein
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static Future<void> testInstant() async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
    final String timeZoneName = tz.local.name;
    final location = tz.getLocation(timeZoneName);

    var scheduledTime = tz.TZDateTime.from(time, location);
    var now = tz.TZDateTime.now(location);

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
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }
}
