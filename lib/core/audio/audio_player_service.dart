import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  static final _player = AudioPlayer();
  static String? _currentPlayingPath;
  static bool _isPlaying = false;

  static bool get isPlaying => _isPlaying;
  static String? get currentPlayingPath => _currentPlayingPath;

  static Future<void> play(String filePath) async {
    try {
      if (_isPlaying && _currentPlayingPath == filePath) {
        await pause();
        return;
      }

      if (_isPlaying) {
        await stop();
      }

      await _player.play(DeviceFileSource(filePath));
      _isPlaying = true;
      _currentPlayingPath = filePath;

      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _currentPlayingPath = null;
      });
    } catch (e) {
      _isPlaying = false;
      _currentPlayingPath = null;
    }
  }

  static Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  static Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentPlayingPath = null;
  }

  static Future<void> dispose() async {
    await _player.dispose();
  }

  static Stream<Duration> get positionStream => _player.onPositionChanged;
  static Stream<Duration> get durationStream => _player.onDurationChanged;
}
