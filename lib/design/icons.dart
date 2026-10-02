import 'package:flutter/widgets.dart';

import 'svg_path.dart';

/// Lucide-style icon names (24 viewBox, stroke 2, round caps). Never emoji.
enum YI {
  chevronLeft, chevronRight, chevronDown, arrowLeft, arrowRight, arrowUpRight, printer,
  check, checkCircle, x, plus, play, pause, send, copy, share, pencil, refresh, history,
  eye, lock, scan, search, info, trash, camera, moreHorizontal,
  home, map, mapPin, crosshair, locate, clock, calendar, users, user, userPlus,
  bell, battery, smartphone, phone, message, mic, image, fileText, barChart, globe,
  heart, pill, utensils, leaf, moon, sun, sunrise, sunset, waves, audioLines,
  helpCircle, alertTriangle, shield, shieldCheck, lifebuoy, walking,
  /// Speaker with waves opening to the RIGHT (LTR screens).
  volume,
  /// Speaker with waves opening to the LEFT (use on RTL / Urdu screens).
  volumeMirrored,
}

/// Draws a [YI] at [size] in [color].
class YIcon extends StatelessWidget {
  final YI icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  /// Flip horizontally (e.g. directional arrows on RTL screens; for the
  /// speaker use [YI.volumeMirrored] instead).
  final bool mirror;

  const YIcon(this.icon, {super.key, this.size = 24, this.color, this.strokeWidth = 2, this.mirror = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF2C2620);
    Widget w = CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(icon, c, strokeWidth),
    );
    if (mirror) w = Transform.flip(flipX: true, child: w);
    return SizedBox(width: size, height: size, child: w);
  }
}

class _IconPainter extends CustomPainter {
  final YI icon;
  final Color color;
  final double stroke;
  _IconPainter(this.icon, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final prims = _parsed(icon);
    final k = size.width / 24;
    canvas.save();
    canvas.scale(k);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final p in prims) {
      if (p.filled) canvas.drawPath(p.path, fill);
      if (p.stroked) canvas.drawPath(p.path, line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter o) => o.icon != icon || o.color != color || o.stroke != stroke;
}

class _Prim {
  final Path path;
  final bool filled;
  final bool stroked;
  _Prim(this.path, {this.filled = false, this.stroked = true});
}

final Map<YI, List<_Prim>> _cache = {};

List<_Prim> _parsed(YI i) => _cache.putIfAbsent(i, () => _build(_svg[i] ?? ''));

final RegExp _tag = RegExp(r'<(path|circle|rect|line|polyline|polygon)\b([^>]*?)/?>');
final RegExp _attr = RegExp(r'([a-z0-9]+)="([^"]*)"');

List<_Prim> _build(String svg) {
  final out = <_Prim>[];
  for (final m in _tag.allMatches(svg)) {
    final a = <String, String>{};
    for (final x in _attr.allMatches(m.group(2)!)) {
      a[x.group(1)!] = x.group(2)!;
    }
    double n(String k, [double def = 0]) => double.tryParse(a[k] ?? '') ?? def;
    final filled = a['fill'] == 'currentColor';
    final strokeToo = a['nostroke'] != '1';
    switch (m.group(1)) {
      case 'path':
        out.add(_Prim(parseSvgPath(a['d'] ?? ''), filled: filled, stroked: strokeToo));
        break;
      case 'circle':
        out.add(_Prim(Path()..addOval(Rect.fromCircle(center: Offset(n('cx'), n('cy')), radius: n('r'))),
            filled: filled, stroked: strokeToo));
        break;
      case 'rect':
        final r = n('rx');
        final rect = Rect.fromLTWH(n('x'), n('y'), n('width'), n('height'));
        out.add(_Prim(
            Path()..addRRect(r > 0 ? RRect.fromRectAndRadius(rect, Radius.circular(r)) : RRect.fromRectAndRadius(rect, Radius.zero)),
            filled: filled,
            stroked: strokeToo));
        break;
      case 'line':
        out.add(_Prim(Path()
          ..moveTo(n('x1'), n('y1'))
          ..lineTo(n('x2'), n('y2'))));
        break;
      case 'polyline':
      case 'polygon':
        final nums = (a['points'] ?? '')
            .split(RegExp(r'[\s,]+'))
            .where((s) => s.isNotEmpty)
            .map((s) => double.tryParse(s) ?? 0)
            .toList();
        final p = Path();
        for (var k = 0; k + 1 < nums.length; k += 2) {
          if (k == 0) {
            p.moveTo(nums[0], nums[1]);
          } else {
            p.lineTo(nums[k], nums[k + 1]);
          }
        }
        if (m.group(1) == 'polygon') p.close();
        out.add(_Prim(p, filled: filled, stroked: strokeToo));
        break;
    }
  }
  return out;
}

const Map<YI, String> _svg = {
  YI.chevronLeft: '<path d="M15 18l-6-6 6-6"/>',
  YI.chevronRight: '<path d="M9 18l6-6-6-6"/>',
  YI.chevronDown: '<path d="M6 9l6 6 6-6"/>',
  YI.arrowLeft: '<path d="M19 12H5M12 19l-7-7 7-7"/>',
  YI.arrowRight: '<path d="M5 12h14M12 5l7 7-7 7"/>',
  YI.arrowUpRight: '<path d="M7 17L17 7M7 7h10v10"/>',
  YI.printer: '<path d="M6 9V2h12v7"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><path d="M6 14h12v8H6z"/>',
  YI.check: '<path d="M20 6L9 17l-5-5"/>',
  YI.checkCircle: '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="M22 4L12 14.01l-3-3"/>',
  YI.x: '<path d="M18 6L6 18M6 6l12 12"/>',
  YI.plus: '<path d="M12 5v14M5 12h14"/>',
  YI.play: '<path d="M7 4.5v15l12-7.5z" fill="currentColor"/>',
  YI.pause: '<rect x="6" y="4" width="4" height="16" rx="1" fill="currentColor"/><rect x="14" y="4" width="4" height="16" rx="1" fill="currentColor"/>',
  YI.send: '<path d="M22 2L11 13"/><path d="M22 2l-7 20-4-9-9-4z"/>',
  YI.copy: '<rect x="8" y="8" width="14" height="14" rx="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>',
  YI.share: '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.59 13.51l6.83 3.98M15.41 6.51l-6.82 3.98"/>',
  YI.pencil: '<path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5z"/><path d="M15 5l4 4"/>',
  YI.refresh: '<path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.93 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/>',
  YI.history: '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l4 2"/>',
  YI.eye: '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/>',
  YI.lock: '<rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  YI.scan: '<path d="M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2"/><path d="M7 12h10"/>',
  YI.search: '<circle cx="11" cy="11" r="8"/><path d="M21 21l-4.3-4.3"/>',
  YI.info: '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>',
  YI.trash: '<path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>',
  YI.camera: '<path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/>',
  YI.moreHorizontal: '<circle cx="12" cy="12" r="1" fill="currentColor"/><circle cx="19" cy="12" r="1" fill="currentColor"/><circle cx="5" cy="12" r="1" fill="currentColor"/>',
  YI.home: '<path d="M3 10.5L12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
  YI.map: '<polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21"/><path d="M9 3v15M15 6v15"/>',
  YI.mapPin: '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0z"/><circle cx="12" cy="10" r="3"/>',
  YI.crosshair: '<circle cx="12" cy="12" r="10"/><path d="M22 12h-4M6 12H2M12 6V2M12 22v-4"/>',
  YI.locate: '<path d="M2 12h3M19 12h3M12 2v3M12 19v3"/><circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="3" fill="currentColor"/>',
  YI.clock: '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
  YI.calendar: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
  YI.users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
  YI.user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  YI.userPlus: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M19 8v6M22 11h-6"/>',
  YI.bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
  YI.battery: '<rect x="2" y="7" width="16" height="10" rx="2"/><path d="M22 11v2"/>',
  YI.smartphone: '<rect x="5" y="2" width="14" height="20" rx="2"/><path d="M12 18h.01"/>',
  YI.phone: '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>',
  YI.message: '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>',
  YI.mic: '<path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v3"/>',
  YI.image: '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="2"/><path d="M21 15l-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>',
  YI.fileText: '<path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5z"/><path d="M14 2v6h6M16 13H8M16 17H8M10 9H8"/>',
  YI.barChart: '<path d="M12 20V10M18 20V4M6 20v-4"/>',
  YI.globe: '<circle cx="12" cy="12" r="10"/><path d="M2 12h20"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>',
  YI.heart: '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7z"/>',
  YI.pill: '<path d="M10.5 20.5l10-10a4.95 4.95 0 1 0-7-7l-10 10a4.95 4.95 0 1 0 7 7z"/><path d="M8.5 8.5l7 7"/>',
  YI.utensils: '<path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2M7 2v20"/><path d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3zm0 0v7"/>',
  YI.leaf: '<path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/>',
  YI.moon: '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9z"/>',
  YI.sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/>',
  YI.sunrise: '<path d="M12 2v8M4.93 10.93l1.41 1.41M2 18h2M20 18h2M19.07 10.93l-1.41 1.41M22 22H2M8 6l4-4 4 4M16 18a4 4 0 0 0-8 0"/>',
  YI.sunset: '<path d="M12 10V2M4.93 10.93l1.41 1.41M2 18h2M20 18h2M19.07 10.93l-1.41 1.41M22 22H2M16 5l-4 4-4-4M16 18a4 4 0 0 0-8 0"/>',
  YI.waves: '<path d="M2 6c.6.5 1.2 1 2.5 1C7 7 7 5 9.5 5c2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M2 12c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M2 18c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/>',
  YI.audioLines: '<path d="M2 10v3M6 6v11M10 3v18M14 8v7M18 5v13M22 10v3"/>',
  YI.helpCircle: '<circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3M12 17h.01"/>',
  YI.alertTriangle: '<path d="M10.3 3.9L1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4M12 17h.01"/>',
  YI.shield: '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>',
  YI.shieldCheck: '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="M9 12l2 2 4-4"/>',
  YI.lifebuoy: '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="4"/><path d="M4.93 4.93l4.24 4.24M14.83 9.17l4.24-4.24M14.83 14.83l4.24 4.24M9.17 14.83l-4.24 4.24"/>',
  YI.walking: '<circle cx="12" cy="5" r="1"/><path d="M9 20l3-6 3 6M6 8l6 2 6-2M12 10v4"/>',
  YI.volume: '<path fill="currentColor" d="M11 5L6 9H2v6h4l5 4z"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07M19.07 4.93a10 10 0 0 1 0 14.14"/>',
  YI.volumeMirrored: '<path fill="currentColor" d="M13 5l5 4h4v6h-4l-5 4z"/><path d="M8.46 8.46a5 5 0 0 0 0 7.07M4.93 4.93a10 10 0 0 0 0 14.14"/>',
};
