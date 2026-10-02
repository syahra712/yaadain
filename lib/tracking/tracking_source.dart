import 'dart:async';

/// Where the elder's home zone is (centre + radius). Passed to a source on
/// [TrackingSource.start].
class HomePoint {
  final double lat;
  final double lng;
  final double radiusM;
  const HomePoint(this.lat, this.lng, this.radiusM);
}

/// Latest known state of the elder. [distanceM]/[bearingDeg] are measured
/// from home (bearing 0 = north, clockwise).
class ElderStatus {
  final double lat;
  final double lng;
  final DateTime at;
  final int? battery; // percent, null if unknown
  final bool inside;
  final double distanceM;
  final double bearingDeg;

  const ElderStatus({
    required this.lat,
    required this.lng,
    required this.at,
    this.battery,
    required this.inside,
    required this.distanceM,
    required this.bearingDeg,
  });
}

/// A raised alert. [ackBy] set means a family member has acknowledged it.
/// [resolution] is '' while active, then 'found' | 'returned' on the final
/// emission (after which the stream emits null).
class ActiveAlert {
  final String id;
  final DateTime raisedAt;
  final String kind; // zone_exit | help
  final double distanceM;
  final double bearingDeg;
  final int? battery;
  final String? unusualReason; // English, e.g. "Not a usual outing time"
  final String? ackBy; // English name
  final DateTime? ackAt;
  final int? etaMin;
  final String resolution;

  const ActiveAlert({
    required this.id,
    required this.raisedAt,
    this.kind = 'zone_exit',
    this.distanceM = 0,
    this.bearingDeg = 0,
    this.battery,
    this.unusualReason,
    this.ackBy,
    this.ackAt,
    this.etaMin,
    this.resolution = '',
  });

  bool get isAcknowledged => ackBy != null;
  bool get isResolved => resolution.isNotEmpty;

  ActiveAlert copyWith({String? ackBy, DateTime? ackAt, int? etaMin, String? resolution, double? distanceM, double? bearingDeg, int? battery}) =>
      ActiveAlert(
        id: id,
        raisedAt: raisedAt,
        kind: kind,
        distanceM: distanceM ?? this.distanceM,
        bearingDeg: bearingDeg ?? this.bearingDeg,
        battery: battery ?? this.battery,
        unusualReason: unusualReason,
        ackBy: ackBy ?? this.ackBy,
        ackAt: ackAt ?? this.ackAt,
        etaMin: etaMin ?? this.etaMin,
        resolution: resolution ?? this.resolution,
      );
}

/// "Bilal: I'm on my way". The elder phone reacts by showing ImSafe.
class Visit {
  final String by; // English name
  final String? memberId;
  final int etaMin;
  final DateTime at;
  const Visit({required this.by, this.memberId, required this.etaMin, required this.at});
}

/// One interface, two backends (config.dart): scripted [DemoTrackingSource]
/// and [FirestoreTrackingSource]. All streams are broadcast; each also has a
/// synchronous `current*` getter so a screen can render before the first event.
abstract class TrackingSource {
  bool get isDemo;

  Stream<ElderStatus?> get status;
  Stream<ActiveAlert?> get alert;
  Stream<Visit?> get visit;

  ElderStatus? get currentStatus;
  ActiveAlert? get currentAlert;
  Visit? get currentVisit;

  /// Begin listening / simulating for [familyCode] around [home].
  Future<void> start({required String familyCode, required HomePoint home});
  Future<void> stop();

  // ── Elder device ──────────────────────────────────────────────────────
  Future<void> publishStatus({
    required double lat,
    required double lng,
    int? battery,
    required bool inside,
    required double distanceM,
    required double bearingDeg,
  });

  Future<void> raiseAlert({
    String kind = 'zone_exit',
    required double distanceM,
    required double bearingDeg,
    int? battery,
    String? unusualReason,
  });

  /// Elder pressed the help button (Madad).
  Future<void> raiseHelp();

  // ── Family devices ────────────────────────────────────────────────────
  Future<void> acknowledge({required String by});
  Future<void> onMyWay({required String by, String? memberId, int etaMin = 8});

  /// Close the alert: he was found / is back home.
  Future<void> markFound({String resolution = 'found'});

  // ── Demo-only (no-ops on Firestore except [reset]) ─────────────────────
  Future<void> simulateLeaving();
  Future<void> fireAlertNow();
  Future<void> reset();

  void dispose();
}
