import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../state/app_state.dart';
import 'widgets/family_b_common.dart';

/// Family: record a short hello (max 40 s) and send it to the elder as a
/// voice letter. Route `/family/record`.
class RecordHelloScreen extends StatefulWidget {
  final String? memberId;
  const RecordHelloScreen({super.key, this.memberId});

  @override
  State<RecordHelloScreen> createState() => _RecordHelloScreenState();
}

class _RecordHelloScreenState extends State<RecordHelloScreen> {
  static const int _max = 40;
  final FbRecorder _rec = FbRecorder(maxSec: _max);
  bool _sending = false;
  bool _announcedLimit = false;

  @override
  void initState() {
    super.initState();
    _rec.addListener(_onRec);
  }

  void _onRec() {
    if (_rec.hitLimit && !_rec.recording && !_announcedLimit) {
      _announcedLimit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) fbSnack(context, 'That is the 40 second limit. Your hello is ready.');
      });
    }
  }

  @override
  void dispose() {
    _rec.removeListener(_onRec);
    _rec.dispose();
    super.dispose();
  }

  String _senderId(AppState app) {
    final id = widget.memberId ?? app.settings.contributorMemberId;
    if (id != null && id.isNotEmpty) return id;
    return 'guest';
  }

  Future<void> _send() async {
    if (_sending || !_rec.hasRecording) return;
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final elder = app.elderNameEn;
    setState(() => _sending = true);
    try {
      await _rec.stopPlayback();
      await app.addLetter(_senderId(app), audioTempPath: _rec.path, durationSec: _rec.seconds);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(
        content: EnText('Sent to $elder.', size: 14, weight: FontWeight.w700, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        backgroundColor: YaadainTheme.ink,
      ));
      if (nav.canPop()) nav.pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        fbSnack(context, 'Could not send that hello. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final elder = app.elderNameEn;
    return AnimatedBuilder(
      animation: _rec,
      builder: (context, _) {
        final recording = _rec.recording;
        final done = _rec.hasRecording;
        final status = recording
            ? 'Recording · tap to stop'
            : done
                ? (_rec.playing ? 'Playing · tap to stop' : 'Recorded · tap to listen')
                : 'Tap the button and speak';
        final big = recording
            ? FbBigCircle(icon: YI.pause, label: 'Stop recording', onTap: _rec.stop, ring: YaadainTheme.accentDark.withOpacity(.14), color: YaadainTheme.accentDark)
            : done
                ? FbBigCircle(
                    icon: _rec.playing ? YI.pause : YI.play,
                    label: _rec.playing ? 'Stop' : 'Play',
                    onTap: _rec.togglePlay,
                  )
                : FbBigCircle(icon: YI.mic, label: 'Start recording', onTap: _rec.start);
        return FamilyScaffold(
          showDemo: false,
          header: const FamilyAppBar(showDemo: false),
          bodyPadding: const EdgeInsets.fromLTRB(YaadainTheme.familyGutter, 8, YaadainTheme.familyGutter, 24),
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (done) ...[
                SizedBox(
                  height: 48,
                  child: FbSmallButton('Re-record', icon: YI.refresh, height: 48, onTap: _sending ? null : () {
                    _announcedLimit = false;
                    _rec.reset();
                    _rec.start();
                  }),
                ),
                const SizedBox(height: 12),
              ],
              FbBigButton('Send to $elder', icon: YI.send, onTap: done && !recording ? _send : null, busy: _sending),
              const SizedBox(height: 10),
              const EnText('He will see “new voice” on his phone.',
                  size: 13, weight: FontWeight.w600, color: YaadainTheme.muted, align: TextAlign.center),
              const SizedBox(height: 12),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EnText('Record a hello\nfor $elder', size: 30, weight: FontWeight.w600, display: true, height: 1.15),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(color: YaadainTheme.primarySoft, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: EdgeInsets.only(top: 2), child: YIcon(YI.volume, size: 20, color: YaadainTheme.primaryDark)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EnText('Say your name and how you are related. He hears it when he taps your face.',
                              size: 15, weight: FontWeight.w600, color: YaadainTheme.primaryDark, height: 1.4),
                          SizedBox(height: 4),
                          EnText('Keep it under 40 seconds.', size: 15, weight: FontWeight.w800, color: YaadainTheme.primaryDark, height: 1.4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    FbWaveform(
                      seed: _rec.path?.hashCode ?? 12,
                      height: 72,
                      flat: !recording && !done,
                      color: recording || done ? YaadainTheme.primary : YaadainTheme.line,
                      tick: recording ? _rec.seconds : 0,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(fbClock(_rec.seconds),
                            style: YaadainTheme.en(44, weight: FontWeight.w800, height: 1.1)
                                .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                        const SizedBox(width: 6),
                        EnText('of ${fbClock(_max)}', size: 14, weight: FontWeight.w700, color: YaadainTheme.muted),
                      ],
                    ),
                    const SizedBox(height: 6),
                    EnText(status, size: 14, weight: FontWeight.w700, color: YaadainTheme.muted),
                    if (_rec.error != null && !done && !recording) ...[
                      const SizedBox(height: 6),
                      EnText(_rec.error!, size: 13, weight: FontWeight.w700, color: YaadainTheme.accentDark, align: TextAlign.center),
                    ],
                    const SizedBox(height: 22),
                    big,
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
