import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme.dart';

/// A place drawn on the radar (another safe zone). Offsets are metres from
/// home: x = east, y = north.
class RadarPlace {
  final String label;
  final double eastM;
  final double northM;
  const RadarPlace(this.label, this.eastM, this.northM);
}

/// Metres east / north of [from] for [to] (small-distance approximation).
({double east, double north}) offsetMeters(
    double fromLat, double fromLng, double toLat, double toLng) {
  const mPerDegLat = 111320.0;
  final mPerDegLng = mPerDegLat * math.cos(fromLat * math.pi / 180);
  return (
    east: (toLng - fromLng) * mPerDegLng,
    north: (toLat - fromLat) * mPerDegLat
  );
}

/// Compass words for a bearing (0 = north, clockwise): "north-east".
String bearingWords(double deg) {
  const names = [
    'north',
    'north-east',
    'east',
    'south-east',
    'south',
    'south-west',
    'west',
    'north-west'
  ];
  final i = (((deg % 360) + 360) % 360 / 45).round() % 8;
  return names[i];
}

/// Geometry presets that match the two boards.
class RadarGeometry {
  final double width;
  final double height;
  final double cy;
  final double zonePx; // pixel radius of the home zone
  final double bgRadius;
  final double tickInner;
  final double labelRadius;
  const RadarGeometry({
    required this.width,
    required this.height,
    required this.cy,
    required this.zonePx,
    required this.bgRadius,
    required this.tickInner,
    required this.labelRadius,
  });

  /// WhereIsAbu board: 326 x 212.
  static const compact = RadarGeometry(
      width: 326,
      height: 212,
      cy: 112,
      zonePx: 43.5,
      bgRadius: 110,
      tickInner: 81,
      labelRadius: 105);

  /// AlertDetail board: 326 x 226 (a larger home ring).
  static const large = RadarGeometry(
      width: 326,
      height: 226,
      cy: 113,
      zonePx: 51,
      bgRadius: 117,
      tickInner: 86,
      labelRadius: 106);
}

/// The family-side "radar": home ring, compass ticks, nearby zones and his dot
/// by bearing and distance. No trail is ever drawn. Dot movement is animated
/// so live updates glide instead of jump.
class SafetyRadar extends StatelessWidget {
  final RadarGeometry geometry;
  final double homeRadiusM;
  final double? distanceM; // null: position unknown, no dot
  final double bearingDeg;
  final bool outside;
  final List<RadarPlace> places;
  final String? landmark;

  const SafetyRadar({
    super.key,
    this.geometry = RadarGeometry.compact,
    required this.homeRadiusM,
    required this.distanceM,
    required this.bearingDeg,
    required this.outside,
    this.places = const [],
    this.landmark,
  });

  Offset? _dotPx() {
    final d = distanceM;
    if (d == null) return null;
    final g = geometry;
    final px =
        math.min(d / math.max(homeRadiusM, 1) * g.zonePx, g.zonePx * 2.9);
    final a = bearingDeg * math.pi / 180;
    return Offset(px * math.sin(a), -px * math.cos(a));
  }

  @override
  Widget build(BuildContext context) {
    final dot = _dotPx();
    final g = geometry;
    return AspectRatio(
      aspectRatio: g.width / g.height,
      child: TweenAnimationBuilder<Offset>(
        tween:
            Tween<Offset>(begin: dot ?? Offset.zero, end: dot ?? Offset.zero),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        builder: (context, o, _) => CustomPaint(
          painter: _RadarPainter(
            g: g,
            homeRadiusM: homeRadiusM,
            dot: dot == null ? null : o,
            outside: outside,
            places: places,
            landmark: landmark,
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final RadarGeometry g;
  final double homeRadiusM;
  final Offset? dot;
  final bool outside;
  final List<RadarPlace> places;
  final String? landmark;

  _RadarPainter({
    required this.g,
    required this.homeRadiusM,
    required this.dot,
    required this.outside,
    required this.places,
    required this.landmark,
  });

  static const _stroke = YaadainTheme.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / g.width);
    final c = Offset(g.width / 2, g.cy);

    // Soft disc and dashed rings (2x and 3x the home ring).
    canvas.drawCircle(
        c, g.bgRadius, Paint()..color = YaadainTheme.paper.withOpacity(0.55));
    _dashedCircle(canvas, c, g.zonePx * 2);
    _dashedCircle(canvas, c, g.zonePx * 3);

    // Compass ticks + letters.
    final tick = Paint()
      ..color = _stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.butt;
    for (final e in const [
      ('N', 0.0, -1.0),
      ('E', 1.0, 0.0),
      ('S', 0.0, 1.0),
      ('W', -1.0, 0.0)
    ]) {
      final dx = e.$2, dy = e.$3;
      canvas.drawLine(c + Offset(dx, dy) * g.tickInner,
          c + Offset(dx, dy) * (g.tickInner + 12), tick);
      _text(canvas, e.$1, c + Offset(dx, dy) * g.labelRadius, 11,
          FontWeight.w800, _stroke,
          center: true);
    }

    // Home zone.
    canvas.drawCircle(
        c, g.zonePx, Paint()..color = YaadainTheme.primary.withOpacity(0.35));
    canvas.drawCircle(
        c,
        g.zonePx,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = YaadainTheme.primary);
    // Radius pill.
    final pill = RRect.fromRectAndRadius(
        Rect.fromLTWH(c.dx + g.zonePx * 0.62, c.dy + g.zonePx * 0.66, 46, 20),
        const Radius.circular(10));
    canvas.drawRRect(pill, Paint()..color = YaadainTheme.surface);
    canvas.drawRRect(
        pill,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = YaadainTheme.line);
    _text(
        canvas,
        '${homeRadiusM.round()} m',
        Offset(pill.left + 8, pill.top + 3),
        11,
        FontWeight.w800,
        YaadainTheme.primaryDark);

    // Other places (dot + label).
    final pxPerM = g.zonePx / math.max(homeRadiusM, 1);
    final maxPx = g.zonePx * 2.9;
    for (final p in places) {
      var o = Offset(p.eastM * pxPerM, -p.northM * pxPerM);
      if (o.distance > maxPx) continue;
      _place(canvas, c + o, p.label);
    }
    if (landmark != null) {
      final o =
          Offset(math.sin(60 * math.pi / 180), -math.cos(60 * math.pi / 180)) *
              (330 * pxPerM);
      _place(canvas, c + o, landmark!);
    }

    // Home glyph.
    canvas.drawCircle(c, 15, Paint()..color = YaadainTheme.surface);
    canvas.drawCircle(
        c,
        15,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = YaadainTheme.line);
    final house = Path()
      ..moveTo(-6, -1)
      ..lineTo(0, -6)
      ..relativeLineTo(6, 5)
      ..relativeLineTo(0, 6.5)
      ..relativeLineTo(-4, 0)
      ..lineTo(2, 2)
      ..relativeLineTo(-4, 0)
      ..relativeLineTo(0, 3.5)
      ..relativeLineTo(-4, 0)
      ..close();
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawPath(
        house,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = YaadainTheme.ink);
    canvas.restore();

    // His dot.
    final d = dot;
    if (d != null) {
      final p = c + d;
      final col = outside ? YaadainTheme.accentDark : YaadainTheme.primary;
      if (outside) {
        _dashedLine(canvas, c + (d / d.distance) * 18, p, col);
      }
      canvas.drawCircle(p, 26, Paint()..color = col.withOpacity(0.10));
      canvas.drawCircle(p, 16, Paint()..color = col.withOpacity(0.18));
      canvas.drawCircle(p, 7.5, Paint()..color = col);
      canvas.drawCircle(
          p,
          7.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white);
    }
  }

  void _place(Canvas canvas, Offset p, String label) {
    canvas.drawCircle(p, 4, Paint()..color = Colors.white);
    canvas.drawCircle(
        p,
        4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _stroke);
    final tp = TextPainter(
      text: TextSpan(
          text: label,
          style: YaadainTheme.nunito(11, FontWeight.w700,
              color: YaadainTheme.muted, height: 1.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    // Keep the label inside the card padding and off his dot and halo.
    final x = (p.dx - tp.width / 2).clamp(16.0, g.width - 16 - tp.width);
    final blocked = dot == null
        ? null
        : Rect.fromCircle(center: Offset(g.width / 2, g.cy) + dot!, radius: 32);
    for (final y in [p.dy + 8, p.dy - 8 - tp.height]) {
      final r = Rect.fromLTWH(x, y, tp.width, tp.height);
      if (blocked == null || !blocked.overlaps(r.inflate(2))) {
        tp.paint(canvas, Offset(x, y));
        return;
      }
    }
    // No clear spot: the dot is on this place, so skip the label.
  }

  void _dashedCircle(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = YaadainTheme.line;
    final circ = 2 * math.pi * r;
    final n = (circ / 8).floor();
    for (var i = 0; i < n; i++) {
      final a0 = i / n * 2 * math.pi;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r), a0, 3 / r, false, paint);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Color col) {
    final paint = Paint()
      ..color = col
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final len = (b - a).distance;
    if (len < 1) return;
    final dir = (b - a) / len;
    for (double t = 0; t < len; t += 7) {
      canvas.drawLine(a + dir * t, a + dir * math.min(t + 2, len), paint);
    }
  }

  void _text(
      Canvas canvas, String s, Offset at, double size, FontWeight w, Color col,
      {bool center = false, bool top = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: YaadainTheme.nunito(size, w, color: col, height: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? at.dx - tp.width / 2 : at.dx;
    final dy = top ? at.dy : at.dy - (center ? tp.height / 2 : 0);
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _RadarPainter o) =>
      o.dot != dot ||
      o.outside != outside ||
      o.homeRadiusM != homeRadiusM ||
      o.landmark != landmark ||
      o.places.length != places.length ||
      o.g != g;
}
