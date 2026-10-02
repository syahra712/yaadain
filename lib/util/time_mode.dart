import 'app_clock.dart';
import 'prayer.dart';

/// The elder home has three looks. day = default; evening = from Asr;
/// night = from Isha + 1 hour until Fajr.
enum TimeMode { day, evening, night }

TimeMode timeModeAt([DateTime? t]) {
  final now = t ?? AppClock.now();
  final today = PrayerTimes.forDate(now);
  if (now.isBefore(today.fajr)) return TimeMode.night;
  if (!now.isBefore(today.isha.add(const Duration(hours: 1)))) return TimeMode.night;
  if (!now.isBefore(today.asr)) return TimeMode.evening;
  return TimeMode.day;
}

/// The route the elder phone should rest on at [t].
String elderRouteForTime([DateTime? t]) {
  switch (timeModeAt(t)) {
    case TimeMode.night:
      return '/elder/night';
    case TimeMode.day:
    case TimeMode.evening:
      return '/elder';
  }
}
