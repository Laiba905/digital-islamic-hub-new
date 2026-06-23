import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const MethodChannel _channel = MethodChannel('digital_islamic_hub/timezone');

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      // Get timezone directly from Native Android/iOS
      final String? timeZoneName = await _channel.invokeMethod('getLocalTimezone');
      if (timeZoneName != null) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } else {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

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
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'prayer_alerts',
      'Prayer Notifications',
      channelDescription: 'Namaz ke auqat par Azan play karne ke liye',
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('azan'),
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      99,
      "حی على الصلاة",
      "Azan sound testing... Allah-hu-Akbar!",
      details,
    );
  }

  static Future<void> schedulePrayerNotification(int id, String name, DateTime time) async {
    final location = tz.local;
    var scheduledTime = tz.TZDateTime.from(time, location);
    var now = tz.TZDateTime.now(location);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      "Waqt-e-$name",
      "Allah-hu-Akbar! $name ka waqt ho gaya hai.",
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_alerts',
          'Prayer Notifications',
          importance: Importance.max,
          priority: Priority.max,
          sound: RawResourceAndroidNotificationSound('azan'),
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          ongoing: false,
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }
}
