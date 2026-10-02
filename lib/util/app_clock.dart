import 'package:flutter/foundation.dart';

/// The single source of "now". Every screen and util calls [AppClock.now]
/// instead of DateTime.now() so the presenter (and tests) can preview
/// evening / night, and the goldens are deterministic.
class AppClock {
  AppClock._();

  static DateTime? _frozen;
  static Duration _offset = Duration.zero;

  /// Bumped whenever the clock is re-pointed, so listeners can rebuild.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static DateTime now() => _frozen ?? DateTime.now().add(_offset);

  /// Freeze time at [t] (tests, goldens).
  static void freeze(DateTime t) {
    _frozen = t;
    _offset = Duration.zero;
    revision.value++;
  }

  /// Make "now" read as [t] right now, then keep ticking (presenter preview).
  static void jumpTo(DateTime t) {
    _frozen = null;
    _offset = t.difference(DateTime.now());
    revision.value++;
  }

  /// Preview a time of day on today's date, keep ticking.
  static void previewTime(int hour, int minute) {
    final n = DateTime.now();
    jumpTo(DateTime(n.year, n.month, n.day, hour, minute));
  }

  /// Back to the real device clock.
  static void reset() {
    _frozen = null;
    _offset = Duration.zero;
    revision.value++;
  }

  static bool get isOverridden => _frozen != null || _offset != Duration.zero;
}
