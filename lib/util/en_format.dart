import 'app_clock.dart';

/// English formatting helpers for family / caregiver screens (Latin digits).
class EnFmt {
  EnFmt._();

  static const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String weekday(DateTime d) => weekdays[d.weekday - 1];
  static String weekdayShort(DateTime d) => weekdays[d.weekday - 1].substring(0, 3);
  static String month(int m) => months[m - 1];
  static String monthShort(int m) => months[m - 1].substring(0, 3);

  /// "3 October 2026"
  static String date(DateTime d) => '${d.day} ${month(d.month)} ${d.year}';

  /// "Saturday, 3 October"
  static String dayDate(DateTime d) => '${weekday(d)}, ${d.day} ${month(d.month)}';

  /// "9:41 AM"
  static String time(DateTime t) {
    var h = t.hour % 12;
    if (h == 0) h = 12;
    final ap = t.hour < 12 ? 'AM' : 'PM';
    return '$h:${t.minute.toString().padLeft(2, '0')} $ap';
  }

  static String greeting(DateTime t) {
    final h = t.hour;
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    if (h >= 17 && h < 21) return 'Good evening';
    return 'Good night';
  }

  /// "just now", "5 min ago", "2 h ago", "Yesterday", "3 days ago".
  static String relative(DateTime then, [DateTime? now]) {
    final n = now ?? AppClock.now();
    final diff = n.difference(then);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    final today = DateTime(n.year, n.month, n.day);
    final thenDay = DateTime(then.year, then.month, then.day);
    final days = today.difference(thenDay).inDays;
    if (days == 0) return '${diff.inHours} h ago';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  /// "5 min", "1 h", "1 h 20 min"
  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  /// "320 m" / "1.2 km"
  static String distance(num m) {
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  /// "0300 1234567" style kept as given; helper to build tel: uri digits.
  static String telDigits(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');
}
