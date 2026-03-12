import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:notetask_pro/app/app.dart';
import 'package:notetask_pro/core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop SQLite FFI init
  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Init notifications (timezone + channels)
  await NotificationService.init();

  // Request notification permissions (Android 13+ / API 33+)
  await NotificationService.requestPermission();

  // Request exact alarm permission (Android 12+ / API 31+)
  // This is needed for precise scheduled reminders
  if (Platform.isAndroid) {
    await NotificationService.requestExactAlarmPermission();
  }

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
