import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const _channelId = 'task_reminders_v1';
  static const _channelName = 'Task Reminders';
  static const _defaultNotifId = 0;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

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

  /// Schedule a task reminder. [soundFilePath] can be null for default sound.
  static Future<void> scheduleReminder({
    required String taskId,
    required String taskTitle,
    required DateTime scheduledTime,
    String? soundFilePath,
    String? body,
  }) async {
    await init();

    final notifId = taskId.hashCode.abs() % 100000;
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    AndroidNotificationDetails androidDetails;

    if (soundFilePath != null && File(soundFilePath).existsSync()) {
      // For custom sounds, copy file to app's external files if needed
      final soundUri = await _prepareSoundUri(soundFilePath);
      androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Task reminder',
        importance: Importance.max,
        priority: Priority.max,
        sound: UriAndroidNotificationSound(soundUri),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
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
      );
    }

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.zonedSchedule(
      notifId,
      taskTitle,
      body ?? 'Time to work on this task!',
      tzTime,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
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
    );
    const iosDetails =
        DarwinNotificationDetails(presentAlert: true, presentSound: true);
    await _plugin.show(
      _defaultNotifId,
      'NoteTask Pro',
      'Test notification — sound is working!',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  static Future<String> _prepareSoundUri(String originalPath) async {
    // Copy to app docs dir and return a content URI friendly path
    final docsDir = await getApplicationDocumentsDirectory();
    final soundsDir = Directory('${docsDir.path}/notification_sounds');
    await soundsDir.create(recursive: true);

    final fileName = originalPath.split('/').last;
    final destPath = '${soundsDir.path}/$fileName';

    if (!File(destPath).existsSync()) {
      await File(originalPath).copy(destPath);
    }
    return destPath;
  }

  static void _onNotificationTap(NotificationResponse _) {
    // Navigation on tap is handled by router — payload = taskId
    // Deep link routing can be added here with Navigator key
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true; // iOS handles via permission_handler
  }
}
