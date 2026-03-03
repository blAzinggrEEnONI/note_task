import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notetask_pro/core/audio/audio_player_service.dart';
import 'package:notetask_pro/shared/models/models.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Recording recording;
  final VoidCallback? onDelete;
  const AudioPlayerWidget({super.key, required this.recording, this.onDelete});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  @override
  void initState() {
    super.initState();
    _positionSub = AudioPlayerService.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSub = AudioPlayerService.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await AudioPlayerService.pause();
      setState(() => _isPlaying = false);
    } else {
      await AudioPlayerService.play(widget.recording.filePath);
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCurrentlyPlaying = AudioPlayerService.currentPlayingPath == widget.recording.filePath;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isCurrentlyPlaying && _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 24,
            ),
            onPressed: _togglePlay,
            color: cs.primary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCurrentlyPlaying && _duration > Duration.zero)
                  LinearProgressIndicator(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0,
                    backgroundColor: cs.surfaceContainerHighest,
                  )
                else
                  LinearProgressIndicator(
                    value: 0,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                const SizedBox(height: 4),
                Text(
                  isCurrentlyPlaying && _duration > Duration.zero
                      ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
                      : 'Audio recording',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: widget.onDelete,
              color: cs.error,
            ),
        ],
      ),
    );
  }
}
