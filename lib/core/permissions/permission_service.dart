import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionService {
  PermissionService._();
  static final instance = PermissionService._();

  Future<bool> requestMicrophone() async {
    final status = await ph.Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> hasMicrophone() async {
    return (await ph.Permission.microphone.status).isGranted;
  }

  Future<bool> requestStorage() async {
    // Android 13+ uses READ_MEDIA_AUDIO, older uses READ_EXTERNAL_STORAGE
    final status = await ph.Permission.audio.request();
    if (status.isGranted) return true;
    return (await ph.Permission.storage.request()).isGranted;
  }

  Future<bool> requestNotification() async {
    final status = await ph.Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> hasNotification() async {
    return (await ph.Permission.notification.status).isGranted;
  }

  Future<void> openSettings() async {
    await ph.openAppSettings();
  }

  /// Returns a user-friendly message explaining why a permission is needed.
  String microphoneRationale() =>
      'NoteTask Pro needs microphone access to record voice memos attached to your notes and tasks.';

  String storageRationale() =>
      'NoteTask Pro needs access to your audio files so you can select a custom notification sound.';

  String notificationRationale() =>
      'NoteTask Pro needs notification permission to send reminders for your tasks at the scheduled time.';
}
