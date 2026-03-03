import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class AudioRecorderService {
  static final _recorder = AudioRecorder();
  static bool _isRecording = false;
  static String? _currentRecordingPath;

  static bool get isRecording => _isRecording;

  static Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<String?> startRecording() async {
    if (_isRecording) return null;

    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${docsDir.path}/recordings');
      await recordingsDir.create(recursive: true);

      final fileName = '${const Uuid().v4()}.m4a';
      final filePath = '${recordingsDir.path}/$fileName';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _isRecording = true;
      _currentRecordingPath = filePath;
      return filePath;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      _currentRecordingPath = null;
      return path;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      return null;
    }
  }

  static Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      // Ignore errors
    } finally {
      _isRecording = false;
      _currentRecordingPath = null;
    }
  }

  static Future<void> dispose() async {
    await _recorder.dispose();
  }
}
