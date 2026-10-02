import 'dart:async';

import '../services/platform/real.dart' show bearingDeg, haversineM;
import '../util/app_clock.dart';
import 'tracking_source.dart';

/// Scripted local simulation. No network, no GPS.
///
/// Timeline after [simulateLeaving] (tick every second):
///   t=0     he is at 128 m from home, still inside
///   t~12 s  crosses the 150 m ring (status.inside = false)
///   t=60 s  alert fires (battery 64%), later 61%
///   t=90 s  reaches ~320 m north-east and holds
/// [fireAlertNow] jumps straight to the alert for a live demo.
class DemoTrackingSource implements TrackingSource {
  static const double _dLat = 0.00203; // ~226 m north
  static const double _dLng = 0.00224; // ~226 m east at Karachi's latitude

  final DateTime Function() _now;
  DemoTrackingSource({DateTime Function()? now}) : _now = now ?? DateTime.now;

  HomePoint _home = const HomePoint(24.9215, 67.0916, 150);

  final _status = StreamController<ElderStatus?>.broadcast();
  final _alert = StreamController<ActiveAlert?>.broadcast();
  final _visit = StreamController<Visit?>.broadcast();

  ElderStatus? _curStatus;
  ActiveAlert? _curAlert;
  Visit? _curVisit;

  Timer? _timer;
  int _t = 0;
  int _alertSeq = 0;

  @override
  bool get isDemo => true;
  @override
  Stream<ElderStatus?> get status => _status.stream;
  @override
  Stream<ActiveAlert?> get alert => _alert.stream;
  @override
  Stream<Visit?> get visit => _visit.stream;
  @override
  ElderStatus? get currentStatus => _curStatus;
  @override
  ActiveAlert? get currentAlert => _curAlert;
  @override
  Visit? get currentVisit => _curVisit;

  @override
  Future<void> start({required String familyCode, required HomePoint home}) async {
    _home = home;
    _emitStatus(_atHome());
    // Re-stamp the at-home fix when the presenter previews another time, so
    // family screens don't read "updated 7 h ago".
    AppClock.revision.removeListener(_refreshHome);
    AppClock.revision.addListener(_refreshHome);
  }

  void _refreshHome() {
    if (_timer != null || _curAlert != null) return;
    if (_curStatus?.inside ?? true) _emitStatus(_atHome());
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  ElderStatus _atHome() => ElderStatus(
        lat: _home.lat,
        lng: _home.lng,
        at: _now(),
        battery: 64,
        inside: true,
        distanceM: 0,
        bearingDeg: 0,
      );

  ElderStatus _at(double p, int battery) {
    final lat = _home.lat + _dLat * p;
    final lng = _home.lng + _dLng * p;
    final d = haversineM(_home.lat, _home.lng, lat, lng);
    return ElderStatus(
      lat: lat,
      lng: lng,
      at: _now(),
      battery: battery,
      inside: d <= _home.radiusM,
      distanceM: d,
      bearingDeg: bearingDeg(_home.lat, _home.lng, lat, lng),
    );
  }

  void _emitStatus(ElderStatus s) {
    _curStatus = s;
    if (!_status.isClosed) _status.add(s);
  }

  void _emitAlert(ActiveAlert? a) {
    _curAlert = a != null && a.isResolved ? null : a;
    if (!_alert.isClosed) _alert.add(a);
    if (a != null && a.isResolved && !_alert.isClosed) _alert.add(null);
  }

  void _emitVisit(Visit? v) {
    _curVisit = v;
    if (!_visit.isClosed) _visit.add(v);
  }

  // ── Script ────────────────────────────────────────────────────────────

  @override
  Future<void> simulateLeaving() async {
    _timer?.cancel();
    _emitVisit(null);
    _emitAlert(null);
    _t = 0;
    _emitStatus(_at(0.4, 64));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    _t++;
    final p = 0.4 + 0.6 * (_t >= 90 ? 1.0 : _t / 90.0);
    final battery = _t >= 60 ? 61 : 64;
    _emitStatus(_at(p, battery));
    if (_t == 60 && _curAlert == null) _raiseFromStatus();
    if (_t >= 90) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _raiseFromStatus() {
    final s = _curStatus ?? _at(1, 61);
    _alertSeq++;
    _emitAlert(ActiveAlert(
      id: 'demo-alert-$_alertSeq',
      raisedAt: _now(),
      kind: 'zone_exit',
      distanceM: s.distanceM,
      bearingDeg: s.bearingDeg,
      battery: s.battery,
      unusualReason: 'Not a usual outing time',
    ));
  }

  @override
  Future<void> fireAlertNow() async {
    if (_curAlert != null) return;
    _timer?.cancel();
    _timer = null;
    _t = 60;
    _emitVisit(null);
    _emitStatus(_at(0.8, 61));
    _raiseFromStatus();
  }

  // ── Actions ───────────────────────────────────────────────────────────

  @override
  Future<void> acknowledge({required String by}) async {
    final a = _curAlert;
    if (a == null || a.isAcknowledged) return;
    _emitAlert(a.copyWith(ackBy: by, ackAt: _now()));
  }

  @override
  Future<void> onMyWay({required String by, String? memberId, int etaMin = 8}) async {
    final a = _curAlert;
    if (a != null) _emitAlert(a.copyWith(ackBy: by, ackAt: _now(), etaMin: etaMin));
    _emitVisit(Visit(by: by, memberId: memberId, etaMin: etaMin, at: _now()));
  }

  @override
  Future<void> markFound({String resolution = 'found'}) async {
    _timer?.cancel();
    _timer = null;
    final a = _curAlert;
    _emitStatus(_atHome());
    if (a != null) _emitAlert(a.copyWith(resolution: resolution));
    _emitVisit(null);
  }

  @override
  Future<void> reset() async {
    _timer?.cancel();
    _timer = null;
    _t = 0;
    _emitAlert(null);
    _emitVisit(null);
    _emitStatus(_atHome());
  }

  // Elder-side publishing is a no-op in the demo: the script owns the state.
  @override
  Future<void> publishStatus({
    required double lat,
    required double lng,
    int? battery,
    required bool inside,
    required double distanceM,
    required double bearingDeg,
  }) async {}

  @override
  Future<void> raiseAlert({
    String kind = 'zone_exit',
    required double distanceM,
    required double bearingDeg,
    int? battery,
    String? unusualReason,
  }) async {
    if (_curAlert != null) return;
    _alertSeq++;
    _emitAlert(ActiveAlert(
      id: 'demo-alert-$_alertSeq',
      raisedAt: _now(),
      kind: kind,
      distanceM: distanceM,
      bearingDeg: bearingDeg,
      battery: battery,
      unusualReason: unusualReason,
    ));
  }

  @override
  Future<void> raiseHelp() async {
    if (_curAlert != null) return;
    _alertSeq++;
    _emitAlert(ActiveAlert(
      id: 'demo-alert-$_alertSeq',
      raisedAt: _now(),
      kind: 'help',
      distanceM: _curStatus?.distanceM ?? 0,
      bearingDeg: _curStatus?.bearingDeg ?? 0,
      battery: _curStatus?.battery,
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    AppClock.revision.removeListener(_refreshHome);
    _status.close();
    _alert.close();
    _visit.close();
  }
}
