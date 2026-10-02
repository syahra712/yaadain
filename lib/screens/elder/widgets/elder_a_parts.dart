import 'dart:io';

import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../design/svg_path.dart';

/// Shared private pieces of the elder-a screens (home, night, routine prompt,
/// sukoon): exact board icons, board illustrations and the tall Urdu buttons.

// ───────────────────────── icons ─────────────────────────

String _circ(double cx, double cy, double r) =>
    'M${cx - r} ${cy}a$r $r 0 1 0 ${2 * r} 0a$r $r 0 1 0 ${-2 * r} 0z';

/// Stroke icon path data lifted from the boards (24 viewBox).
class EldPaths {
  EldPaths._();
  static final home = [
    'M3 10.5L12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z'
  ];
  static final users = [
    'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2',
    _circ(9, 7, 4),
    'M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75',
  ];
  static final moon = ['M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z'];
  static final nightMoon = ['M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z'];
  static final utensils = [
    'M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2M7 2v20M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7'
  ];
  static final calendar = [
    'M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z',
    'M16 2v4M8 2v4M3 10h18',
  ];
  static final whoIs = [
    _circ(10, 8, 4),
    'M2 21v-2a5 5 0 0 1 5-5h4',
    _circ(17.5, 16.5, 3.5),
    'M20.5 19.5 22 21'
  ];
  static final chat = [
    'M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z'
  ];
  static final audioLines = ['M2 10v3M6 6v11M10 3v18M14 8v7M18 5v13M22 10v3'];
  static final leaf = [
    'M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z',
    'M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12'
  ];
  static final shield = ['M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z'];
  static final eye = [
    'M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z',
    _circ(12, 12, 3)
  ];
  static final chevronLeft = ['M15 18l-6-6 6-6'];
  static final play = ['M7 4.5v15l13-7.5z'];
  static final pause = ['M6 5h4v14H6z', 'M14 5h4v14h-4z'];
  static final check = ['M20 6L9 17l-5-5'];
  static final clock = [_circ(12, 12, 10), 'M12 6v6l4 2'];
  static final phone = [
    'M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z'
  ];
  static final waves = [
    'M2 10c2-3 4-3 6 0s4 3 6 0 4-3 6 0',
    'M2 16c2-3 4-3 6 0s4 3 6 0 4-3 6 0'
  ];

  /// Speaker whose waves open to the LEFT (RTL screens); first path is filled.
  static final speaker = [
    'M13 5l5 4h4v6h-4l-5 4z',
    'M8.5 8.5a5 5 0 0 0 0 7',
    'M5 5a10 10 0 0 0 0 14'
  ];
}

final Map<String, Path> _pathCache = {};
Path _path(String d) => _pathCache.putIfAbsent(d, () => parseSvgPath(d));

/// Draws board stroke icons. [fill] fills every path with [color];
/// [fillFirst] fills only the first path (the speaker body).
class EldIcon extends StatelessWidget {
  final List<String> paths;
  final double size;
  final Color color;
  final double stroke;
  final bool fill;
  final bool fillFirst;

  const EldIcon(this.paths,
      {super.key,
      this.size = 24,
      required this.color,
      this.stroke = 2,
      this.fill = false,
      this.fillFirst = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
            painter: _IconPainter(paths, color, stroke, fill, fillFirst)),
      );
}

class _IconPainter extends CustomPainter {
  final List<String> paths;
  final Color color;
  final double stroke;
  final bool fill;
  final bool fillFirst;
  _IconPainter(this.paths, this.color, this.stroke, this.fill, this.fillFirst);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final solid = Paint()..color = color;
    for (var i = 0; i < paths.length; i++) {
      final p = _path(paths[i]);
      if (fill || (fillFirst && i == 0)) canvas.drawPath(p, solid);
      if (!fill) canvas.drawPath(p, line);
    }
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) =>
      old.color != color || old.paths != paths || old.stroke != stroke;
}

// ───────────────────────── illustrations ─────────────────────────

class _ScenePainter extends CustomPainter {
  final Size design;
  final void Function(Canvas c) draw;
  _ScenePainter(this.design, this.draw);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / design.width, size.height / design.height);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => false;
}

Paint _fill(Color c, [double o = 1]) => Paint()..color = c.withOpacity(o);
Paint _stroke(Color c, double w, [double o = 1]) => Paint()
  ..color = c.withOpacity(o)
  ..style = PaintingStyle.stroke
  ..strokeWidth = w;
Rect _el(double cx, double cy, double rx, double ry) =>
    Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);

/// Illustrations that stand in for photographs on the boards.
enum EldArt { homeScene, medicineScene, mosque }

class EldArtView extends StatelessWidget {
  final EldArt art;
  final double? width;
  final double? height;
  final double radius;
  final bool shadow;
  const EldArtView(this.art,
      {super.key,
      this.width,
      this.height,
      this.radius = 28,
      this.shadow = false});

  Size get _design => switch (art) {
        EldArt.homeScene => const Size(342, 160),
        EldArt.medicineScene => const Size(342, 220),
        EldArt.mosque => const Size(64, 64),
      };

  @override
  Widget build(BuildContext context) {
    final d = _design;
    final child = AspectRatio(
      aspectRatio: d.width / d.height,
      child: CustomPaint(painter: _ScenePainter(d, (c) => _draw(c))),
    );
    Widget w =
        ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
    if (shadow) {
      w = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A2C2620), blurRadius: 28, offset: Offset(0, 10))
          ],
        ),
        child: w,
      );
    }
    if (width != null || height != null) {
      w = SizedBox(width: width, height: height, child: w);
    }
    return ExcludeSemantics(child: w);
  }

  void _draw(Canvas c) {
    switch (art) {
      case EldArt.homeScene:
        c.drawRect(const Rect.fromLTWH(0, 0, 342, 160),
            _fill(const Color(0xFFE3E8D6)));
        c.drawCircle(const Offset(268, 52), 26, _fill(const Color(0xFFF1E6CC)));
        c.drawCircle(const Offset(268, 52), 18, _fill(YaadainTheme.gold, .55));
        c.drawRect(const Rect.fromLTWH(0, 112, 342, 48),
            _fill(const Color(0xFFF1E6CC)));
        c.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(40, 56, 150, 60), const Radius.circular(4)),
            _fill(Colors.white));
        c.drawPath(parseSvgPath('M34 58h162l-10-14H44z'),
            _fill(YaadainTheme.accentDark, .85));
        for (final r in const [
          Rect.fromLTWH(56, 70, 34, 46),
          Rect.fromLTWH(104, 72, 36, 44)
        ]) {
          c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width / 2)),
              _fill(YaadainTheme.primarySoft));
        }
        final lat = _stroke(YaadainTheme.primary, 1.5, .5);
        c.drawPath(parseSvgPath('M73 70v46M56 93h34M62 80h22M62 106h22'), lat);
        c.drawPath(
            parseSvgPath('M122 72v44M104 94h36M110 82h24M110 106h24'), lat);
        c.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(154, 78, 22, 38), const Radius.circular(3)),
            _fill(YaadainTheme.attentionSoft));
        c.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(226, 86, 10, 36), const Radius.circular(3)),
            _fill(YaadainTheme.stroke));
        c.drawOval(_el(231, 70, 48, 30), _fill(YaadainTheme.primary, .82));
        c.drawOval(_el(256, 84, 34, 22), _fill(YaadainTheme.primaryDark, .7));
        c.drawOval(_el(206, 86, 30, 20), _fill(const Color(0xFF475326), .55));
        c.drawOval(_el(120, 136, 70, 8), _fill(YaadainTheme.line));
        c.drawPath(parseSvgPath('M20 130c30-6 60-6 90 0'),
            _stroke(YaadainTheme.gold, 2, .5));
      case EldArt.medicineScene:
        c.drawRect(const Rect.fromLTWH(0, 0, 342, 220), _fill(Colors.white));
        c.drawRect(const Rect.fromLTWH(0, 150, 342, 70),
            _fill(const Color(0xFFF1E6CC)));
        c.drawOval(_el(118, 160, 78, 22), _fill(const Color(0xFFE3E8D6)));
        c.drawOval(_el(118, 154, 78, 22), _fill(Colors.white));
        c.drawOval(_el(118, 154, 78, 22), _stroke(YaadainTheme.line, 2));
        c.drawOval(_el(118, 150, 26, 11), _fill(YaadainTheme.line));
        c.drawOval(_el(118, 146, 26, 11), _fill(Colors.white));
        c.drawOval(_el(118, 146, 26, 11), _stroke(YaadainTheme.stroke, 1.5));
        c.drawPath(
            parseSvgPath('M94 146h48'), _stroke(YaadainTheme.stroke, 1.5));
        final glass = parseSvgPath(
            'M232 72h66l-8 92a10 10 0 0 1-10 9h-30a10 10 0 0 1-10-9z');
        c.drawPath(glass, _fill(YaadainTheme.paper));
        c.drawPath(glass, _stroke(YaadainTheme.stroke, 2));
        c.drawPath(
            parseSvgPath('M238 108h54l-5 56a8 8 0 0 1-8 7h-28a8 8 0 0 1-8-7z'),
            _fill(YaadainTheme.primarySoft));
        c.drawPath(
            parseSvgPath('M240 108h50'), _stroke(YaadainTheme.primary, 2, .5));
      case EldArt.mosque:
        c.drawRect(
            const Rect.fromLTWH(0, 0, 64, 64), _fill(YaadainTheme.primarySoft));
        c.drawRect(const Rect.fromLTWH(0, 44, 64, 20),
            _fill(YaadainTheme.primaryDark, .85));
        c.drawPath(parseSvgPath('M14 44V34a18 18 0 0 1 36 0v10z'),
            _fill(Colors.white));
        c.drawPath(parseSvgPath('M32 16v-6'), _stroke(YaadainTheme.gold, 2));
        c.drawCircle(const Offset(32, 9), 2.5, _fill(YaadainTheme.gold));
        c.drawPath(parseSvgPath('M50 14a7 7 0 1 0 2 10 6 6 0 1 1-2-10z'),
            _fill(const Color(0xFFF1E6CC)));
    }
  }
}

// ───────────────────────── buttons / tiles ─────────────────────────

/// A pill-less board button: any height / label size (the shared
/// ElderButton is fixed at 64/80 and 24px).
class EldBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final Color bg;
  final Color fg;
  final Color? border;
  final double borderWidth;
  final double height;
  final double size;
  final bool shadow;

  const EldBtn(
    this.label, {
    super.key,
    this.onTap,
    this.icon,
    this.bg = YaadainTheme.surface,
    this.fg = YaadainTheme.ink,
    this.border,
    this.borderWidth = 1,
    this.height = 64,
    this.size = 24,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(20);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: shadow
              ? [
                  BoxShadow(
                      color: bg.withOpacity(.22),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ]
              : null,
        ),
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: r,
            side: border == null
                ? BorderSide.none
                : BorderSide(color: border!, width: borderWidth),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: height, minWidth: double.infinity),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 14)],
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: size / 3),
                        child: UrduText(label,
                            size: size,
                            color: fg,
                            height: 2.0,
                            align: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round teal play disc (64) used on the memory card and voice tile.
class EldPlayDisc extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final double size;
  const EldPlayDisc(
      {super.key, this.onTap, required this.label, this.size = 64});

  @override
  Widget build(BuildContext context) => Semantics(
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
              width: size,
              height: size,
              child: Center(
                  child: EldIcon(EldPaths.play,
                      size: 28, color: Colors.white, fill: true)),
            ),
          ),
        ),
      );
}

/// Photo-or-illustration thumbnail: an existing image file, else [fallback].
class EldPhotoOr extends StatelessWidget {
  final String? path;
  final double size;
  final double radius;
  final Widget fallback;
  const EldPhotoOr(
      {super.key,
      required this.path,
      required this.size,
      required this.radius,
      required this.fallback});

  @override
  Widget build(BuildContext context) {
    final p = path;
    var ok = false;
    if (p != null && p.isNotEmpty) {
      try {
        ok = File(p).existsSync();
      } catch (_) {}
    }
    if (!ok) return SizedBox(width: size, height: size, child: fallback);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(File(p!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback),
    );
  }
}

// ───────────────────────── Urdu formatting ─────────────────────────

/// "۱ بجے" / "۶:۴۵ بجے" (12-hour, no am/pm: the meal / prayer names the time).
String eldBaje(DateTime t) {
  var h = t.hour % 12;
  if (h == 0) h = 12;
  final d = _digits('$h');
  if (t.minute == 0) return '$d بجے';
  return '$d:${_digits(t.minute.toString().padLeft(2, '0'))} بجے';
}

String _digits(String s) {
  const u = '۰۱۲۳۴۵۶۷۸۹';
  return s.split('').map((c) {
    final i = '0123456789'.indexOf(c);
    return i < 0 ? c : u[i];
  }).join();
}

final RegExp _latinRe = RegExp(r'[A-Za-z]');

/// True when [s] has Latin letters (never shown on an Urdu screen).
bool eldHasLatin(String s) => _latinRe.hasMatch(s);
