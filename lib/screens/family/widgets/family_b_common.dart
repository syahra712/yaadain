import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../services/platform/platform.dart';

/// Shared private helpers for the family-b screens (AddRelative, Answers,
/// Routine, RecordHello). English only.

/// "0:09", "1:05".
String fbClock(int sec) {
  final s = sec < 0 ? 0 : sec;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// "9:00 am", "1:00 pm".
String fbTime(DateTime t) {
  var h = t.hour % 12;
  if (h == 0) h = 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'am' : 'pm'}';
}

void fbSnack(BuildContext context, String text) {
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(SnackBar(
    content: EnText(text, size: 14, weight: FontWeight.w700, color: Colors.white),
    behavior: SnackBarBehavior.floating,
    backgroundColor: YaadainTheme.ink,
    duration: const Duration(seconds: 3),
  ));
}

// ── Recording ───────────────────────────────────────────────────────────

/// Records through [Svc.audio] with a hard cap of [maxSec]; also plays the
/// result back. Safe when the mic is missing or denied (sets [error]).
class FbRecorder extends ChangeNotifier {
  final int maxSec;
  FbRecorder({required this.maxSec});

  String? path;
  int seconds = 0;
  bool recording = false;
  bool playing = false;
  bool hitLimit = false;
  String? error;

  Timer? _timer;
  StreamSubscription<bool>? _sub;
  bool _disposed = false;

  bool get hasRecording => path != null && !recording;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    if (recording) return;
    error = null;
    hitLimit = false;
    try {
      await Svc.audio.stop();
      final ok = await Svc.audio.hasMicPermission();
      if (!ok) {
        error = 'Allow the microphone to record.';
        _notify();
        return;
      }
      final p = await Svc.audio.startRecording();
      if (p == null) {
        error = 'Recording is not available right now.';
        _notify();
        return;
      }
      path = null;
      seconds = 0;
      recording = true;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        seconds++;
        if (seconds >= maxSec) {
          hitLimit = true;
          stop();
        } else {
          _notify();
        }
      });
    } catch (_) {
      recording = false;
      error = 'Recording is not available right now.';
    }
    _notify();
  }

  Future<void> stop() async {
    if (!recording) return;
    _timer?.cancel();
    _timer = null;
    recording = false;
    String? p;
    try {
      p = await Svc.audio.stopRecording();
    } catch (_) {}
    if (p == null || seconds < 1) {
      path = null;
      seconds = 0;
      hitLimit = false;
      error = 'Nothing was recorded. Try again.';
    } else {
      path = p;
    }
    _notify();
  }

  Future<void> togglePlay([String? other]) async {
    final p = other ?? path;
    if (p == null) return;
    try {
      if (playing) {
        await Svc.audio.stop();
        playing = false;
      } else {
        _sub ??= Svc.audio.playing.listen((v) {
          playing = v;
          _notify();
        });
        playing = true;
        _notify();
        await Svc.audio.play(p);
      }
    } catch (_) {
      playing = false;
      error = 'That recording cannot be played.';
    }
    _notify();
  }

  Future<void> stopPlayback() async {
    if (!playing) return;
    playing = false;
    try {
      await Svc.audio.stop();
    } catch (_) {}
    _notify();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    recording = false;
    path = null;
    seconds = 0;
    hitLimit = false;
    error = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _sub?.cancel();
    if (recording) {
      try {
        Svc.audio.stopRecording();
      } catch (_) {}
    }
    try {
      Svc.audio.stop();
    } catch (_) {}
    super.dispose();
  }
}

/// Deterministic bar waveform (the "voice" shape). [live] makes the bars move
/// with [tick].
class FbWaveform extends StatelessWidget {
  final int seed;
  final double height;
  final Color color;
  final bool flat;
  final int tick;
  const FbWaveform({super.key, this.seed = 7, this.height = 48, this.color = YaadainTheme.primary, this.flat = false, this.tick = 0});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _WavePainter(seed, color, flat, tick)),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final int seed;
  final Color color;
  final bool flat;
  final int tick;
  _WavePainter(this.seed, this.color, this.flat, this.tick);

  @override
  void paint(Canvas canvas, Size size) {
    const pitch = 7.4, bw = 4.4;
    final n = math.max(1, ((size.width - bw) / pitch).floor() + 1);
    final rnd = math.Random(seed * 7919 + tick * 31);
    final p = Paint()..color = color;
    for (var i = 0; i < n; i++) {
      final r = rnd.nextDouble();
      final lo = size.height * .28, hi = size.height;
      final h = flat ? 6.0 : (r < .12 ? hi : lo + (hi - lo) * r * r);
      final x = 1.5 + i * pitch;
      final y = (size.height - h) / 2;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, bw, h), const Radius.circular(2.2)), p);
    }
  }

  @override
  bool shouldRepaint(_WavePainter o) => o.seed != seed || o.color != color || o.flat != flat || o.tick != tick;
}

// ── Inputs and buttons ──────────────────────────────────────────────────

class FbLabel extends StatelessWidget {
  final String text;
  const FbLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: EnText(text, size: 13, weight: FontWeight.w800, color: YaadainTheme.bodyDim),
      );
}

class FbHelper extends StatelessWidget {
  final String text;
  final bool error;
  const FbHelper(this.text, {super.key, this.error = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: EnText(text,
            size: 13,
            weight: error ? FontWeight.w700 : FontWeight.w600,
            color: error ? YaadainTheme.accentDark : YaadainTheme.muted,
            height: 1.35),
      );
}

/// 52 px labelled text field matching the boards.
class FbField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? helper;
  final String? error;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final TextCapitalization capitalization;
  final String? hint;
  const FbField({
    super.key,
    required this.label,
    required this.controller,
    this.helper,
    this.error,
    this.keyboardType,
    this.onChanged,
    this.capitalization = TextCapitalization.words,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c, double w) =>
        OutlineInputBorder(borderRadius: YaadainTheme.radius12, borderSide: BorderSide(color: c, width: w));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FbLabel(label),
        SizedBox(
          height: 52,
          child: TextField(
            controller: controller,
            expands: true,
            maxLines: null,
            minLines: null,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: YaadainTheme.primary,
            style: YaadainTheme.en(16, weight: FontWeight.w600, color: YaadainTheme.ink)
                .copyWith(fontFamilyFallback: const [YaadainTheme.urduFont]),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: YaadainTheme.en(16, weight: FontWeight.w600, color: YaadainTheme.sepia),
              filled: true,
              fillColor: YaadainTheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              enabledBorder: b(error != null ? YaadainTheme.accentDark : YaadainTheme.line, 1),
              focusedBorder: b(error != null ? YaadainTheme.accentDark : YaadainTheme.primary, 1.5),
              border: b(YaadainTheme.line, 1),
            ),
          ),
        ),
        if (error != null) FbHelper(error!, error: true) else if (helper != null) FbHelper(helper!),
      ],
    );
  }
}

/// 56 px / radius 20 primary action (Save, Send).
class FbBigButton extends StatelessWidget {
  final String label;
  final YI? icon;
  final VoidCallback? onTap;
  final bool busy;
  const FbBigButton(this.label, {super.key, this.icon, this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: enabled ? YaadainTheme.primary : YaadainTheme.primary.withOpacity(.4),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (busy)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              else if (icon != null)
                YIcon(icon!, size: 20, color: Colors.white),
              if (busy || icon != null) const SizedBox(width: 8),
              Flexible(child: EnText(label, size: 16, weight: FontWeight.w800, color: Colors.white, maxLines: 1)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Outlined / tonal button, [height] 40 to 52.
class FbSmallButton extends StatelessWidget {
  final String label;
  final YI? icon;
  final VoidCallback? onTap;
  final double height;
  final bool tonal;
  final bool filled;
  const FbSmallButton(this.label,
      {super.key, this.icon, this.onTap, this.height = 44, this.tonal = false, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final bg = filled ? YaadainTheme.primary : (tonal ? YaadainTheme.primarySoft : YaadainTheme.surface);
    final fg = filled ? Colors.white : (tonal ? YaadainTheme.primaryDark : YaadainTheme.ink);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: Material(
          color: bg,
          borderRadius: YaadainTheme.radius12,
          child: InkWell(
            borderRadius: YaadainTheme.radius12,
            onTap: onTap,
            child: Container(
              height: height,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: (tonal || filled)
                  ? null
                  : BoxDecoration(borderRadius: YaadainTheme.radius12, border: Border.all(color: YaadainTheme.stroke, width: 1.5)),
              child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[YIcon(icon!, size: 16, color: fg), const SizedBox(width: 6)],
                Flexible(child: EnText(label, size: 14, weight: FontWeight.w800, color: fg, maxLines: 1)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section heading used by Answers and Routine ("Fraunces 20/600", 40 px row).
class FbSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const FbSectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          children: [
            Expanded(child: EnText(title, size: 20, weight: FontWeight.w600, display: true, height: 1.2)),
            if (action != null)
              InkWell(
                onTap: onAction,
                borderRadius: YaadainTheme.radius12,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  child: EnText(action!, size: 14, weight: FontWeight.w800, color: YaadainTheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Round 40 px icon button (play / record again).
class FbRoundButton extends StatelessWidget {
  final YI icon;
  final String label;
  final VoidCallback? onTap;
  final bool tonal;
  final bool filled;
  const FbRoundButton({super.key, required this.icon, required this.label, this.onTap, this.tonal = false, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : (tonal ? YaadainTheme.primaryDark : YaadainTheme.ink);
    final bg = filled ? YaadainTheme.primary : (tonal ? YaadainTheme.primarySoft : YaadainTheme.surface);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Opacity(
            opacity: onTap == null ? .45 : 1,
            child: Material(
              color: bg,
              shape: CircleBorder(side: (tonal || filled) ? BorderSide.none : const BorderSide(color: YaadainTheme.stroke, width: 1.5)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(width: 40, height: 40, child: Center(child: YIcon(icon, size: 18, color: fg))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FbDashedCircle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = YaadainTheme.stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final r = size.width / 2 - 1;
    final c = size.center(Offset.zero);
    const dash = 7.0, gap = 5.0;
    final circ = 2 * math.pi * r;
    final n = (circ / (dash + gap)).floor();
    for (var i = 0; i < n; i++) {
      final a0 = i * (dash + gap) / r;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, dash / r, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 96 px round button with a soft outer ring (record / stop / play).
class FbBigCircle extends StatelessWidget {
  final YI icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color? ring;
  const FbBigCircle({super.key, required this.icon, required this.label, this.onTap, this.color = YaadainTheme.primary, this.ring});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: 116,
        height: 116,
        alignment: Alignment.center,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: ring ?? YaadainTheme.primarySoft, spreadRadius: 10)],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(child: YIcon(icon, size: 40, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
