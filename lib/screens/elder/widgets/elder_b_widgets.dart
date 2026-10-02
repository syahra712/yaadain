import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../models/family_member.dart';
import '../../../models/relationship.dart';
import '../../../services/platform/platform.dart';

/// Greyscale memorial tint (board FamilyTree / WhoIsThis).
const AvatarTint kMemorialTint =
    AvatarTint(Color(0xFFE7E1D7), Color(0xFF857A68));

/// True when the relative is a junior (child, grandchild, niece/nephew,
/// in-law of the next generation): singular verbs. Seniors and peers take the
/// honorific plural (urdu-rules section 5).
bool isJunior(FamilyMember m) {
  const juniors = {
    'beta',
    'beti',
    'bahu',
    'damaad',
    'pota',
    'poti',
    'nawasa',
    'nawasi',
    'bhateeja',
    'bhateeji',
    'bhanja',
    'bhanji',
  };
  return juniors.contains(m.relationshipId);
}

bool isFemale(FamilyMember m) => m.relationship?.gender == Gender.female;

/// "آپ کو ”ابو“ کہتا ہے" with the right gender / honorific agreement.
/// Empty string when nothing is recorded or the person has passed away.
String callsHimLine(FamilyMember m) {
  final c = m.callsHimUr.trim();
  if (c.isEmpty || m.isDeceased) return '';
  final String verb;
  if (isJunior(m)) {
    verb = isFemale(m) ? 'کہتی ہے' : 'کہتا ہے';
  } else {
    verb = 'کہتے ہیں';
  }
  return 'آپ کو ”$c“ $verb';
}

/// Name for an elder screen, and whether a separate kinship line is useful.
bool hasOwnName(FamilyMember m) =>
    m.nameUr.trim().isNotEmpty && !hasLatinLetters(m.nameUr);

/// Face with tint, photo, optional memorial ring and optional speaker badge.
class EbFace extends StatelessWidget {
  final FamilyMember member;
  final double size;
  final bool badge;
  const EbFace(this.member,
      {super.key, required this.size, this.badge = false});

  @override
  Widget build(BuildContext context) {
    final m = member;
    final tint = m.isDeceased ? kMemorialTint : m.avatarTint;
    final fs = size * 0.36;
    final path = m.photoPath;
    final hasPhoto = path != null && path.isNotEmpty && _exists(path);
    Widget face = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint.bg,
        boxShadow: m.isDeceased
            ? const [
                BoxShadow(color: Colors.white, spreadRadius: 3),
                BoxShadow(color: YaadainTheme.sepia, spreadRadius: 6),
              ]
            : null,
      ),
      child: hasPhoto
          ? ClipOval(
              child: Image.file(File(path),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _mono(tint, fs)),
            )
          : _mono(tint, fs),
    );
    final hasBadge = badge && m.hasVoice;
    if (!hasBadge) return SizedBox(width: size, height: size, child: face);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: face),
          Positioned(
            left: -2,
            bottom: -2,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: YaadainTheme.primary,
                border: Border.all(color: Colors.white, width: 3),
              ),
              alignment: Alignment.center,
              child: const YIcon(YI.volumeMirrored,
                  size: 18, color: Colors.white, strokeWidth: 2.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mono(AvatarTint tint, double fs) {
    final t = Avatar.monogramFor(member, urdu: true);
    return Transform.translate(
      offset: Offset(0, -fs * 0.1),
      child: Text(
        t,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: YaadainTheme.urduFont,
          fontSize: fs,
          height: 1.4,
          fontWeight: FontWeight.w400,
          color: tint.fg,
        ),
      ),
    );
  }

  static bool _exists(String p) {
    try {
      return File(p).existsSync();
    } catch (_) {
      return false;
    }
  }
}

/// Section heading with a gold rule and a small gold diamond.
/// [stacked] puts the rule on its own line (long headings).
class EbSectionTitle extends StatelessWidget {
  final String text;
  final bool stacked;
  const EbSectionTitle(this.text, {super.key, this.stacked = false});

  @override
  Widget build(BuildContext context) {
    final rule = [
      Expanded(
          child:
              Container(height: 1, color: YaadainTheme.gold.withOpacity(0.6))),
      Transform.rotate(
        angle: 0.785398,
        child: Container(width: 6, height: 6, color: YaadainTheme.gold),
      ),
    ];
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UrduText(text,
              size: 28, color: YaadainTheme.primaryDark, height: 1.8),
          const SizedBox(height: 2),
          Row(textDirection: TextDirection.rtl, children: [
            Expanded(
                child: Container(
                    height: 1, color: YaadainTheme.gold.withOpacity(0.6))),
            const SizedBox(width: 12),
            Transform.rotate(
                angle: 0.785398,
                child:
                    Container(width: 6, height: 6, color: YaadainTheme.gold)),
          ]),
        ],
      );
    }
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        UrduText(text, size: 28, color: YaadainTheme.primaryDark, height: 2.0),
        const SizedBox(width: 12),
        rule[0],
        const SizedBox(width: 12),
        rule[1],
      ],
    );
  }
}

/// 64px round teal play / pause button.
class EbPlayCircle extends StatelessWidget {
  final bool playing;
  final VoidCallback onTap;
  final String label;
  const EbPlayCircle(
      {super.key,
      required this.playing,
      required this.onTap,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: YaadainTheme.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
                child: YIcon(playing ? YI.pause : YI.play,
                    size: 28, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

/// Bar waveform. [progress] 0..1 paints the leading bars teal, the rest line.
class EbWaveform extends StatelessWidget {
  final double progress;
  final bool expand;
  const EbWaveform({super.key, required this.progress, this.expand = true});

  static const _h = [
    8,
    14,
    22,
    30,
    18,
    26,
    34,
    20,
    12,
    24,
    32,
    16,
    10,
    22,
    28,
    14,
    20,
    30,
    12,
    18,
    26,
    10,
    16,
    24,
    12,
    8
  ];

  @override
  Widget build(BuildContext context) {
    final lit = (progress.clamp(0.0, 1.0) * _h.length).round();
    return SizedBox(
      height: 40,
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < _h.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: Center(
                child: Container(
                  height: _h[i].toDouble(),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i < lit ? YaadainTheme.primary : YaadainTheme.line,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Plays one recording at a time and tells the screen what is playing.
/// A missing recording is never an error: a short "played" state is shown
/// (when [pretendSeconds] > 0) or nothing at all.
class EbPlayer extends ChangeNotifier {
  String? key;
  double progress = 0;
  Timer? _tick;
  StreamSubscription<bool>? _sub;
  bool _disposed = false;
  DateTime? _startedAt;
  int _totalMs = 0;
  bool _sawPlaying = false;

  bool isPlaying(String k) => key == k;

  Future<void> start(String k,
      {String? path, int seconds = 0, int minSeconds = 2}) async {
    await stop(notify: false);
    key = k;
    progress = 0;
    _startedAt = DateTime.now();
    final secs = seconds <= 0 ? minSeconds : seconds.clamp(minSeconds, 60);
    _totalMs = secs * 1000;
    _sawPlaying = false;
    if (path != null && path.isNotEmpty) {
      try {
        _sub = Svc.audio.playing.listen((p) {
          if (p) {
            _sawPlaying = true;
          } else if (_sawPlaying) {
            _finish();
          }
        });
        await Svc.audio.play(path);
      } catch (_) {}
    }
    _tick = Timer.periodic(const Duration(milliseconds: 120), (_) {
      final e = DateTime.now().difference(_startedAt!).inMilliseconds;
      progress = (e / _totalMs).clamp(0.0, 1.0);
      if (e >= _totalMs + 400) {
        _finish();
      } else {
        _notify();
      }
    });
    _notify();
  }

  void _finish() {
    _tick?.cancel();
    _sub?.cancel();
    _tick = null;
    _sub = null;
    key = null;
    progress = 0;
    _notify();
  }

  Future<void> stop({bool notify = true}) async {
    final had = key != null;
    _tick?.cancel();
    _sub?.cancel();
    _tick = null;
    _sub = null;
    key = null;
    progress = 0;
    if (had) {
      try {
        await Svc.audio.stop();
      } catch (_) {}
    }
    if (notify) _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _sub?.cancel();
    try {
      Svc.audio.stop();
    } catch (_) {}
    super.dispose();
  }
}

/// Calm centred note for empty states.
class EbEmptyNote extends StatelessWidget {
  final String text;
  const EbEmptyNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
        child: UrduText(text,
            size: 28, color: YaadainTheme.muted, align: TextAlign.center),
      );
}
