import 'urdu_format.dart';

/// A tabular (arithmetical) Islamic calendar date. Real moon sighting can
/// differ by a day, so callers pass [offsetDays] (-1, 0, +1; stored in
/// AppSettings.hijriOffsetDays).
class HijriDate {
  final int year;
  final int month; // 1..12
  final int day;
  const HijriDate(this.year, this.month, this.day);

  static const monthsUr = [
    'محرم', 'صفر', 'ربیع الاول', 'ربیع الثانی', 'جمادی الاول', 'جمادی الثانی',
    'رجب', 'شعبان', 'رمضان', 'شوال', 'ذوالقعدہ', 'ذوالحجہ',
  ];
  static const monthsEn = [
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani', 'Jumada al-Awwal', 'Jumada al-Thani',
    'Rajab', 'Shaban', 'Ramadan', 'Shawwal', 'Dhul Qadah', 'Dhul Hijjah',
  ];

  String get monthUr => monthsUr[month - 1];
  String get monthEn => monthsEn[month - 1];

  /// "۲۰ ربیع الثانی ۱۴۴۸"
  String get urdu => '${UrduFmt.digits(day)} $monthUr ${UrduFmt.digits(year)}';

  /// "20 Rabi al-Thani 1448"
  String get english => '$day $monthEn $year';

  /// Tabular civil Islamic calendar from a Gregorian date.
  /// [offsetDays] shifts the result (moon-sighting correction).
  factory HijriDate.fromGregorian(DateTime g, {int offsetDays = 0}) {
    final d = DateTime(g.year, g.month, g.day).add(Duration(days: offsetDays));
    final jd = _gregorianToJdn(d.year, d.month, d.day);
    var l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    final m = (24 * l) ~/ 709;
    final dd = l - (709 * m) ~/ 24;
    final y = 30 * n + j - 30;
    return HijriDate(y, m, dd);
  }

  static int _gregorianToJdn(int y, int m, int d) {
    final a = (14 - m) ~/ 12;
    final yy = y + 4800 - a;
    final mm = m + 12 * a - 3;
    return d + (153 * mm + 2) ~/ 5 + 365 * yy + yy ~/ 4 - yy ~/ 100 + yy ~/ 400 - 32045;
  }
}
