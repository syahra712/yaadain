import 'dart:math' as math;
import 'dart:ui';

/// Minimal SVG path-data parser (M L H V C S Q T A Z, absolute + relative)
/// used by the icon set. Arcs use Flutter's own SVG-style arcToPoint.
Path parseSvgPath(String d) {
  final p = _Scanner(d);
  final path = Path();
  double x = 0, y = 0, sx = 0, sy = 0;
  double? lcx, lcy; // last cubic control (for S)
  double? lqx, lqy; // last quad control (for T)
  String cmd = 'M';
  bool first = true;
  while (true) {
    p.skipSep();
    if (p.done) break;
    if (p.isCommand) {
      cmd = p.takeCommand();
    } else if (first) {
      break; // malformed
    }
    first = false;
    final rel = cmd.toLowerCase() == cmd;
    switch (cmd.toLowerCase()) {
      case 'm':
        final nx = p.number() + (rel ? x : 0);
        final ny = p.number() + (rel ? y : 0);
        path.moveTo(nx, ny);
        x = sx = nx;
        y = sy = ny;
        cmd = rel ? 'l' : 'L';
        lcx = lcy = lqx = lqy = null;
        break;
      case 'l':
        final nx = p.number() + (rel ? x : 0);
        final ny = p.number() + (rel ? y : 0);
        path.lineTo(nx, ny);
        x = nx;
        y = ny;
        lcx = lcy = lqx = lqy = null;
        break;
      case 'h':
        final nx = p.number() + (rel ? x : 0);
        path.lineTo(nx, y);
        x = nx;
        lcx = lcy = lqx = lqy = null;
        break;
      case 'v':
        final ny = p.number() + (rel ? y : 0);
        path.lineTo(x, ny);
        y = ny;
        lcx = lcy = lqx = lqy = null;
        break;
      case 'c':
        final x1 = p.number() + (rel ? x : 0), y1 = p.number() + (rel ? y : 0);
        final x2 = p.number() + (rel ? x : 0), y2 = p.number() + (rel ? y : 0);
        final nx = p.number() + (rel ? x : 0), ny = p.number() + (rel ? y : 0);
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        lcx = x2;
        lcy = y2;
        lqx = lqy = null;
        x = nx;
        y = ny;
        break;
      case 's':
        final x2 = p.number() + (rel ? x : 0), y2 = p.number() + (rel ? y : 0);
        final nx = p.number() + (rel ? x : 0), ny = p.number() + (rel ? y : 0);
        final x1 = lcx == null ? x : 2 * x - lcx;
        final y1 = lcy == null ? y : 2 * y - lcy;
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        lcx = x2;
        lcy = y2;
        lqx = lqy = null;
        x = nx;
        y = ny;
        break;
      case 'q':
        final x1 = p.number() + (rel ? x : 0), y1 = p.number() + (rel ? y : 0);
        final nx = p.number() + (rel ? x : 0), ny = p.number() + (rel ? y : 0);
        path.quadraticBezierTo(x1, y1, nx, ny);
        lqx = x1;
        lqy = y1;
        lcx = lcy = null;
        x = nx;
        y = ny;
        break;
      case 't':
        final nx = p.number() + (rel ? x : 0), ny = p.number() + (rel ? y : 0);
        final x1 = lqx == null ? x : 2 * x - lqx;
        final y1 = lqy == null ? y : 2 * y - lqy;
        path.quadraticBezierTo(x1, y1, nx, ny);
        lqx = x1;
        lqy = y1;
        lcx = lcy = null;
        x = nx;
        y = ny;
        break;
      case 'a':
        final rx = p.number().abs(), ry = p.number().abs();
        final rot = p.number();
        final large = p.flag();
        final sweep = p.flag();
        final nx = p.number() + (rel ? x : 0), ny = p.number() + (rel ? y : 0);
        if (rx == 0 || ry == 0) {
          path.lineTo(nx, ny);
        } else {
          path.arcToPoint(
            Offset(nx, ny),
            radius: Radius.elliptical(rx, ry),
            rotation: rot * math.pi / 180,
            largeArc: large,
            clockwise: sweep,
          );
        }
        x = nx;
        y = ny;
        lcx = lcy = lqx = lqy = null;
        break;
      case 'z':
        path.close();
        x = sx;
        y = sy;
        lcx = lcy = lqx = lqy = null;
        break;
      default:
        return path;
    }
  }
  return path;
}

class _Scanner {
  final String s;
  int i = 0;
  _Scanner(this.s);

  bool get done => i >= s.length;

  void skipSep() {
    while (i < s.length) {
      final c = s.codeUnitAt(i);
      if (c == 0x20 || c == 0x2C || c == 0x0A || c == 0x09 || c == 0x0D) {
        i++;
      } else {
        break;
      }
    }
  }

  bool get isCommand {
    final c = s.codeUnitAt(i);
    return (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);
  }

  String takeCommand() => s[i++];

  double number() {
    skipSep();
    final start = i;
    if (i < s.length && (s[i] == '-' || s[i] == '+')) i++;
    var seenDot = false;
    while (i < s.length) {
      final c = s.codeUnitAt(i);
      if (c >= 0x30 && c <= 0x39) {
        i++;
      } else if (c == 0x2E && !seenDot) {
        seenDot = true;
        i++;
      } else if ((c == 0x65 || c == 0x45) && i > start) {
        i++;
        if (i < s.length && (s[i] == '-' || s[i] == '+')) i++;
      } else {
        break;
      }
    }
    return double.tryParse(s.substring(start, i)) ?? 0;
  }

  bool flag() {
    skipSep();
    final c = i < s.length ? s[i] : '0';
    i++;
    return c == '1';
  }
}
