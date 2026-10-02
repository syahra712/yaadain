import 'package:flutter/material.dart';

import '../theme.dart';

/// Jaali lattice (44px tile, white stroke at low opacity) painted over a
/// teal surface. Wrap in [ClipRect]/[Positioned.fill]; it never takes input.
class JaaliPattern extends StatelessWidget {
  final double opacity;
  final bool fadeBottom;
  final Color color;

  const JaaliPattern({super.key, this.opacity = 0.08, this.fadeBottom = true, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    Widget w = IgnorePointer(
      child: CustomPaint(painter: _JaaliPainter(color.withOpacity(opacity)), size: Size.infinite),
    );
    if (fadeBottom) {
      w = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.transparent],
        ).createShader(r),
        child: w,
      );
    }
    return w;
  }
}

class _JaaliPainter extends CustomPainter {
  final Color color;
  _JaaliPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const t = 44.0;
    final tile = Path()
      ..addRect(const Rect.fromLTWH(12, 12, 20, 20))
      ..moveTo(22, 7.9)
      ..lineTo(36.1, 22)
      ..lineTo(22, 36.1)
      ..lineTo(7.9, 22)
      ..close()
      ..moveTo(0, 22)
      ..lineTo(7.9, 22)
      ..moveTo(36.1, 22)
      ..lineTo(44, 22)
      ..moveTo(22, 0)
      ..lineTo(22, 7.9)
      ..moveTo(22, 36.1)
      ..lineTo(22, 44);
    for (double y = 0; y < size.height; y += t) {
      for (double x = 0; x < size.width; x += t) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawPath(tile, p);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_JaaliPainter old) => old.color != color;
}

/// The Yaadain mark: white square + white diamond, dark ring, clay dot.
class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _LogoPainter()));
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final white = Paint()..color = Colors.white;
    canvas.drawPath(Path()..addRect(const Rect.fromLTWH(24, 24, 52, 52)), white);
    canvas.drawPath(
      Path()
        ..moveTo(50, 13.2)
        ..lineTo(86.8, 50)
        ..lineTo(50, 86.8)
        ..lineTo(13.2, 50)
        ..close(),
      white,
    );
    canvas.drawCircle(const Offset(50, 50), 15, Paint()..color = YaadainTheme.primaryDark);
    canvas.drawCircle(const Offset(50, 50), 8, Paint()..color = YaadainTheme.accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
