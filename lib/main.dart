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
  
  // Request notification permissions (Android 13+)
  await NotificationService.requestPermission();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
