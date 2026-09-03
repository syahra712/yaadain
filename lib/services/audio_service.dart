import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records real family voices and plays them back. Intentionally simple:
/// one recorder, one player, so the elder screens can just say "play this".
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  String? _currentlyPlaying;
  String? get currentlyPlaying => _currentlyPlaying;

  Stream<PlayerState> get playerState => _player.onPlayerStateChanged;

  Future<bool> hasMicPermission() => _recorder.hasPermission();

  /// Starts recording to a temp file; returns the temp path being written.
  Future<String> startRecording() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: path,
    );
    return path;
  }

  Future<bool> get isRecording => _recorder.isRecording();

  /// Stops and returns the recorded temp file path (or null if nothing).
  Future<String?> stopRecording() => _recorder.stop();

  Future<void> play(String path) async {
    _currentlyPlaying = path;
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stop() async {
    _currentlyPlaying = null;
    await _player.stop();
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
