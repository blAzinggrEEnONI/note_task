import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const _channelId = 'task_reminders_v1';
  static const _channelName = 'Task Reminders';
  static const _defaultNotifId = 0;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database and set local timezone
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('NotificationService: Could not get local timezone: $e');
      // Fallback: try to use UTC offset-based approach
      final offset = DateTime.now().timeZoneOffset;
      final offsetHours = offset.inHours;
      final sign = offsetHours >= 0 ? '+' : '-';
      final absHours = offsetHours.abs().toString().padLeft(2, '0');
      try {
        // Try common timezone names based on offset
        tz.setLocalLocation(tz.getLocation('Etc/GMT${sign == '+' ? '-' : '+'}$absHours'));
      } catch (_) {
        // Last resort: keep UTC
      }
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    await _createDefaultChannel();
    _initialized = true;
  }

  static Future<void> _createDefaultChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Reminders for your tasks in NoteTask Pro',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Schedule a task reminder. [soundFilePath] is ignored on Android
  /// (custom sounds require a raw resource; system default is used instead).
  static Future<void> scheduleReminder({
    required String taskId,
    required String taskTitle,
    required DateTime scheduledTime,
    String? soundFilePath,
    String? body,
  }) async {
    await init();

    // Ensure the scheduled time is in the future
    if (!scheduledTime.isAfter(DateTime.now())) {
      debugPrint('NotificationService: Skipping past reminder for $taskTitle');
      return;
    }

    final notifId = taskId.hashCode.abs() % 100000;
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    debugPrint(
        'NotificationService: Scheduling "$taskTitle" at $tzTime (local: ${tz.local.name})');

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Task reminder',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    try {
      await _plugin.zonedSchedule(
        notifId,
        taskTitle,
        body ?? 'Time to work on this task!',
        tzTime,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskId,
      );
      debugPrint('NotificationService: Successfully scheduled notification id=$notifId');
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule notification: $e');
      // Try inexact alarm as fallback (works without SCHEDULE_EXACT_ALARM permission)
      try {
        await _plugin.zonedSchedule(
          notifId,
          taskTitle,
          body ?? 'Time to work on this task!',
          tzTime,
          const NotificationDetails(android: androidDetails, iOS: iosDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: taskId,
        );
        debugPrint('NotificationService: Scheduled with inexact alarm as fallback');
      } catch (e2) {
        debugPrint('NotificationService: Fallback also failed: $e2');
      }
    }
  }

  static Future<void> cancelReminder(String taskId) async {
    await _plugin.cancel(taskId.hashCode.abs() % 100000);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> showTestNotification(String? soundFilePath) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Test notification',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails =
        DarwinNotificationDetails(presentAlert: true, presentSound: true);
    await _plugin.show(
      _defaultNotifId,
      'NoteTask Pro',
      'Test notification — notifications are working!',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Navigation on tap is handled by router — payload = taskId
    debugPrint('NotificationService: Notification tapped, payload=${response.payload}');
  }

  /// Request notification permission (Android 13+ / API 33+).
  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission();
    debugPrint('NotificationService: Notification permission granted=$granted');
    return granted ?? false;
  }

  /// Request exact alarm permission (Android 12+ / API 31+).
  /// Returns true if permission is granted or not required.
  static Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    // Check if exact alarms are permitted
    final permitted = await android.requestExactAlarmsPermission();
    debugPrint('NotificationService: Exact alarm permission granted=$permitted');
    return permitted ?? false;
  }

  /// Returns list of pending notifications (for debugging).
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }
}

/// Top-level function required for background notification responses.
@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  debugPrint('NotificationService: Background notification tapped, payload=${response.payload}');
}
