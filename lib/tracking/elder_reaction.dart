import 'dart:async';

import 'package:flutter/material.dart';

import '../models/care.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../util/app_clock.dart';
import '../util/time_mode.dart';

/// Makes the ELDER phone react to what the tracking source reports, without
/// any screen having to listen:
///
///  * alert raised (not resolved)  -> `/elder/madad`   (once per alert id)
///  * a family visit arrives       -> `/elder/safe`    with [ImSafeArgs]
///  * alert resolved / visit ends  -> back to the root route
///  * a routine item is due        -> `/elder/routine-prompt` with [RoutinePromptArgs]
///  * time of day changes          -> swaps the root between `/elder` and `/elder/night`
///
/// Started once in main.dart. Does nothing on family devices. It pushes through
/// [appNavigatorKey] and reads the top route from [RouteTracker].
class ElderReaction {
  final AppState app;
  final GlobalKey<NavigatorState> navKey;
  final RouteTracker tracker;

  ElderReaction(this.app,
      {GlobalKey<NavigatorState>? navKey, RouteTracker? tracker})
      : navKey = navKey ?? appNavigatorKey,
        tracker = tracker ?? RouteTracker.instance;

  StreamSubscription<RoutineItem>? _promptSub;
  Timer? _timer;
  String? _madadAlertId;
  String? _visitKey;
  bool _started = false;
  static ElderReaction? _current;

  /// Call after a deliberate goRoot() (demo view switch, time preview): forgets
  /// what was already shown so an alert or visit that is still active opens
  /// its screen again on the fresh root.
  static void rearm() {
    final r = _current;
    if (r == null) return;
    r._madadAlertId = null;
    r._visitKey = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => r.check());
  }

  void start() {
    if (_started) return;
    _started = true;
    _current = this;
    app.addListener(check);
    AppClock.revision.addListener(check);
    _promptSub = app.routinePrompts.listen(_onPrompt);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => check());
  }

  void dispose() {
    if (!_started) return;
    _started = false;
    if (_current == this) _current = null;
    app.removeListener(check);
    AppClock.revision.removeListener(check);
    _promptSub?.cancel();
    _timer?.cancel();
  }

  NavigatorState? get _nav => navKey.currentState;
  String? get _route => tracker.name;

  static bool _isCrisis(String? r) => r == Routes.madad || r == Routes.imSafe;

  /// Re-evaluates everything. Safe to call any time (listeners, timers, tests).
  void check() {
    final nav = _nav;
    if (nav == null || !app.ready || !app.isElder) return;
    final route = _route;
    if (route == null || route == Routes.boot) return;

    final alert = app.activeAlert;
    final visit = app.currentVisit;
    final alertActive = alert != null && !alert.isResolved;

    // A visit takes priority over Madad: help is on its way.
    if (visit != null) {
      final key = '${visit.by}@${visit.at.millisecondsSinceEpoch}';
      if (_visitKey != key) {
        _visitKey = key;
        if (route != Routes.imSafe) {
          nav.pushNamedAndRemoveUntil(
            Routes.imSafe,
            (r) => r.isFirst,
            arguments: ImSafeArgs(
                byName: visit.by,
                memberId: visit.memberId,
                etaMin: visit.etaMin),
          );
        }
      }
      if (alertActive) _madadAlertId = alert.id;
      return;
    }

    if (alertActive) {
      if (_madadAlertId != alert.id) {
        _madadAlertId = alert.id;
        if (route != Routes.madad) {
          nav.pushNamedAndRemoveUntil(Routes.madad, (r) => r.isFirst);
        }
      }
      return;
    }

    // Nothing active: close any crisis screen that the reaction opened.
    if (_madadAlertId != null || _visitKey != null) {
      _madadAlertId = null;
      _visitKey = null;
      if (_isCrisis(route)) nav.popUntil((r) => r.isFirst);
      return;
    }

    // Time-of-day root swap (only when resting on a root screen).
    if (Routes.elderRoots.contains(route)) {
      final want = elderRouteForTime(app.now);
      if (want != route) goRoot(want);
    }
  }

  void _onPrompt(RoutineItem item) {
    final nav = _nav;
    if (nav == null || !app.isElder) return;
    final route = _route;
    if (_isCrisis(route) || route == Routes.ifFound || route == Routes.routinePrompt) return;
    nav.pushNamed(Routes.routinePrompt, arguments: RoutinePromptArgs(item.id));
  }
}
