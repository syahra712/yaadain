import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme.dart';

/// Self-contained record / re-record / preview control. Reports the recorded
/// file path (a temp file) up via [onRecorded]; the caller imports it into
/// permanent media storage on save.
class VoiceRecorder extends StatefulWidget {
  final String? initialPath; // existing recording, if editing
  final String hint;
  final ValueChanged<String?> onRecorded;

  const VoiceRecorder({
    super.key,
    this.initialPath,
    required this.hint,
    required this.onRecorded,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final _audio = AudioService.instance;
  String? _path;
  bool _recording = false;
  bool _playing = false;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath;
    _audio.playerState.listen((_) {
      if (mounted && _audio.currentlyPlaying == null && _playing) {
        setState(() => _playing = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final p = await _audio.stopRecording();
      _timer?.cancel();
      setState(() {
        _recording = false;
        if (p != null) _path = p;
      });
      widget.onRecorded(_path);
    } else {
      if (!await _audio.hasMicPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission needed')),
          );
        }
        return;
      }
      await _audio.startRecording();
      _seconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
      setState(() => _recording = true);
    }
  }

  Future<void> _togglePlay() async {
    if (_path == null) return;
    if (_playing) {
      await _audio.stop();
      setState(() => _playing = false);
    } else {
      await _audio.play(_path!);
      setState(() => _playing = true);
    }
  }

  void _clear() {
    _audio.stop();
    setState(() {
      _path = null;
      _playing = false;
    });
    widget.onRecorded(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasClip = _path != null && File(_path!).existsSync();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.hint, style: const TextStyle(color: YaadainTheme.muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoundBtn(
                color: _recording ? YaadainTheme.danger : YaadainTheme.primary,
                icon: _recording ? Icons.stop : Icons.mic,
                onTap: _toggleRecord,
              ),
              const SizedBox(width: 12),
              if (_recording)
                Text('Recording… ${_seconds}s',
                    style: const TextStyle(color: YaadainTheme.danger))
              else if (hasClip) ...[
                _RoundBtn(
                  color: YaadainTheme.accent,
                  icon: _playing ? Icons.stop : Icons.play_arrow,
                  onTap: _togglePlay,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                ),
              ] else
                const Text('Tap the mic to record'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      );
}
