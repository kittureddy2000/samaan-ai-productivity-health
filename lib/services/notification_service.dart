import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _flnp =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) return; // Notifications not supported on web in this setup
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await _flnp.initialize(initSettings);

    if (Platform.isAndroid) {
      final androidPlugin = _flnp.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      // Only request exact alarm permission if needed, and handle gracefully
      try {
        final hasExactAlarmPermission =
            await androidPlugin?.areNotificationsEnabled() ?? false;
        if (!hasExactAlarmPermission) {
          // Don't block the app - just proceed without exact alarms
          print(
              'Exact alarm permission not granted - using approximate timing');
        }
      } catch (e) {
        // If exact alarm permission fails, continue without it
        print('Exact alarm permission request failed: $e');
      }
    }
  }

  Future<void> scheduleDailyMorning({int hour = 8, int minute = 0}) async {
    if (kIsWeb) return; // Skip on web
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'daily_morning',
        'Daily Morning Reminder',
        channelDescription: 'Daily reminder to log your fitness data',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    var next =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    await _flnp.zonedSchedule(
      1001,
      'Good morning',
      'Log today\'s meals, exercise and weight',
      next,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_morning',
    );
  }

  Future<void> cancelDailyMorning() async {
    if (kIsWeb) return; // Skip on web
    await _flnp.cancel(1001);
  }
}
