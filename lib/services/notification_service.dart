import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const String _prefPrefix = 'prayer_notif_enabled_';

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
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
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

  /// Toggle notification: Schedule baseline set karta hai aur preference save karta hai
  static Future<void> togglePrayerNotification({
    required int id,
    required String name,
    required DateTime time,
    required bool enable,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefPrefix$id', enable);

    if (enable) {
      await schedulePrayerNotification(id, name, time);
    } else {
      await cancelNotification(id);
    }
  }

  /// Stored setting status get karne ke liye
  static Future<bool> isPrayerNotificationSaved(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefPrefix$id') ?? false;
  }

  static Future<void> schedulePrayerNotification(int id, String name, DateTime time) async {
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
    await _plugin.cancel(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefPrefix$id', false);
  }

  static Future<bool> isNotificationScheduled(int id) async {
    final List<PendingNotificationRequest> pending = await _plugin.pendingNotificationRequests();
    return pending.any((element) => element.id == id);
  }

  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefPrefix));
    for (var key in keys) {
      await prefs.remove(key);
    }
  }
}