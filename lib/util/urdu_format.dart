import 'app_clock.dart';

/// Urdu formatting helpers for elder screens. Every function returns pure
/// Urdu script with Urdu digits (۰-۹) and Urdu punctuation.
class UrduFmt {
  UrduFmt._();

  static const _digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  /// Converts every ASCII digit in [v.toString()] to ۰-۹.
  static String digits(Object v) {
    final s = v.toString();
    final b = StringBuffer();
    for (final r in s.runes) {
      if (r >= 0x30 && r <= 0x39) {
        b.write(_digits[r - 0x30]);
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString();
  }

  /// Two-digit zero padded, in Urdu digits ("۰۵").
  static String pad2(int v) => digits(v.toString().padLeft(2, '0'));

  static const weekdays = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
  static const months = [
    'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون',
    'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر',
  ];

  /// DateTime.weekday is 1 = Monday .. 7 = Sunday.
  static String weekday(DateTime d) => weekdays[d.weekday - 1];
  static String month(int m) => months[m - 1];

  /// "۳ اکتوبر ۲۰۲۶"
  static String date(DateTime d) => '${digits(d.day)} ${month(d.month)} ${digits(d.year)}';

  /// "ہفتہ، ۳ اکتوبر"
  static String dayDate(DateTime d) => '${weekday(d)}، ${digits(d.day)} ${month(d.month)}';

  /// Part of day word: صبح / دوپہر / سہ پہر / شام / رات.
  static String period(DateTime t) {
    final h = t.hour;
    if (h >= 4 && h < 12) return 'صبح';
    if (h >= 12 && h < 16) return 'دوپہر';
    if (h >= 16 && h < 18) return 'سہ پہر';
    if (h >= 18 && h < 20) return 'شام';
    return 'رات';
  }

  /// "صبح ۹:۴۱"
  static String time(DateTime t) {
    var h = t.hour % 12;
    if (h == 0) h = 12;
    return '${period(t)} ${digits(h)}:${pad2(t.minute)}';
  }

  /// Clock without period: "۹:۴۱"
  static String clock(DateTime t) {
    var h = t.hour % 12;
    if (h == 0) h = 12;
    return '${digits(h)}:${pad2(t.minute)}';
  }

  /// Greeting by hour (urdu-rules §7): صبح بخیر 05-11, السلام علیکم 11-16,
  /// شام بخیر 16-20, شب بخیر 20-05.
  static String greeting(DateTime t) {
    final h = t.hour;
    if (h >= 5 && h < 11) return 'صبح بخیر';
    if (h >= 11 && h < 16) return 'السلام علیکم';
    if (h >= 16 && h < 20) return 'شام بخیر';
    return 'شب بخیر';
  }

  /// "آج جمعہ ہے"
  static String todayIs(DateTime t) => 'آج ${weekday(t)} ہے';

  /// "ابھی", "۵ منٹ پہلے", "۲ گھنٹے پہلے", "کل", "۳ دن پہلے".
  static String relative(DateTime then, [DateTime? now]) {
    final n = now ?? AppClock.now();
    final diff = n.difference(then);
    if (diff.inSeconds < 60) return 'ابھی';
    if (diff.inMinutes < 60) return '${digits(diff.inMinutes)} منٹ پہلے';
    if (diff.inHours < 24 && n.day == then.day) return '${digits(diff.inHours)} گھنٹے پہلے';
    final today = DateTime(n.year, n.month, n.day);
    final thenDay = DateTime(then.year, then.month, then.day);
    final days = today.difference(thenDay).inDays;
    if (days == 0) return '${digits(diff.inHours)} گھنٹے پہلے';
    if (days == 1) return 'کل';
    return '${digits(days)} دن پہلے';
  }

  /// "۵ منٹ", "۱ گھنٹہ", "۲ گھنٹے".
  static String duration(int minutes) {
    if (minutes < 60) return '${digits(minutes)} منٹ';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final hs = h == 1 ? '۱ گھنٹہ' : '${digits(h)} گھنٹے';
    return m == 0 ? hs : '$hs ${digits(m)} منٹ';
  }

  /// "۳۲۰ میٹر"
  static String meters(num m) => '${digits(m.round())} میٹر';
}
