import 'urdu_format.dart';

enum Prayer { fajr, zuhr, asr, maghrib, isha }

extension PrayerNames on Prayer {
  String get ur => const {
        Prayer.fajr: 'فجر',
        Prayer.zuhr: 'ظہر',
        Prayer.asr: 'عصر',
        Prayer.maghrib: 'مغرب',
        Prayer.isha: 'عشاء',
      }[this]!;
  String get en => const {
        Prayer.fajr: 'Fajr',
        Prayer.zuhr: 'Zuhr',
        Prayer.asr: 'Asr',
        Prayer.maghrib: 'Maghrib',
        Prayer.isha: 'Isha',
      }[this]!;
}

/// Prayer times for one date.
class PrayerDay {
  final DateTime fajr, zuhr, asr, maghrib, isha;
  const PrayerDay(this.fajr, this.zuhr, this.asr, this.maghrib, this.isha);

  DateTime at(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return fajr;
      case Prayer.zuhr:
        return zuhr;
      case Prayer.asr:
        return asr;
      case Prayer.maghrib:
        return maghrib;
      case Prayer.isha:
        return isha;
    }
  }

  /// The next prayer strictly after [now]; null once Isha has passed.
  Prayer? nextAfter(DateTime now) {
    for (final p in Prayer.values) {
      if (at(p).isAfter(now)) return p;
    }
    return null;
  }

  /// The most recent prayer whose time has begun, or null before Fajr.
  Prayer? current(DateTime now) {
    Prayer? c;
    for (final p in Prayer.values) {
      if (!at(p).isAfter(now)) c = p;
    }
    return c;
  }

  /// Urdu clock for a prayer, e.g. "۴:۴۰" (no period word; prayers are
  /// named, so the hour is unambiguous).
  String urduClock(Prayer p) => UrduFmt.clock(at(p));
}

/// A static, APPROXIMATE Karachi timetable for September-October 2026,
/// linearly interpolated between anchor dates. Good enough for a calm
/// "next prayer" hint and the evening / night mode; not a religious
/// authority. Outside Sep 1 - Oct 31 the nearest anchor is used.
class PrayerTimes {
  PrayerTimes._();

  // [month, day, fajr, zuhr, asr, maghrib, isha] in minutes; asr/maghrib/isha
  // are minutes past 12:00 (pm).
  static const List<List<int>> _anchors = [
    [9, 1, 290, 752, 297, 415, 495], // 4:50  12:32  4:57(pm=16:57) 6:55pm 8:15pm
    [9, 15, 298, 749, 290, 405, 485],
    [10, 3, 305, 745, 280, 390, 470], // 5:05  12:25  4:40  6:30  7:50
    [10, 15, 311, 741, 272, 380, 460],
    [10, 31, 320, 739, 260, 365, 445],
  ];

  static PrayerDay forDate(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final pts = <DateTime>[
      for (final a in _anchors) DateTime(d.year, a[0], a[1]),
    ];
    int lo = 0;
    double t = 0;
    if (!day.isAfter(pts.first)) {
      lo = 0;
      t = 0;
    } else if (!day.isBefore(pts.last)) {
      lo = pts.length - 2;
      t = 1;
    } else {
      for (var i = 0; i < pts.length - 1; i++) {
        if (!day.isBefore(pts[i]) && day.isBefore(pts[i + 1])) {
          lo = i;
          final span = pts[i + 1].difference(pts[i]).inHours;
          t = day.difference(pts[i]).inHours / span;
          break;
        }
      }
    }
    int lerp(int col, {int add = 0}) {
      final a = _anchors[lo][col] + add;
      final b = _anchors[lo + 1][col] + add;
      return (a + (b - a) * t).round();
    }

    DateTime mk(int minutes) => DateTime(d.year, d.month, d.day).add(Duration(minutes: minutes));
    return PrayerDay(
      mk(lerp(2)),
      mk(lerp(3)),
      mk(lerp(4, add: 720)),
      mk(lerp(5, add: 720)),
      mk(lerp(6, add: 720)),
    );
  }
}
