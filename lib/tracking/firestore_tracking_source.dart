import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_gate.dart';
import 'tracking_source.dart';

/// Firestore adapter. OFF by default (see config.dart). Writes small fields
/// onto the existing family doc with merge-set:
///
///   families/{CODE}
///     status   { lat, lng, at, battery, inside, distanceM, bearingDeg }
///     lastAlert{ id, outside, kind, distanceMeters, bearingDeg, battery,
///                unusualReason, at, ackBy, ackAt, etaMin, resolution }
///     help     { at }
///     visit    { by, memberId, etaMin, at }
///     alertAck { by, at }
///
/// `lastAlert{outside,distanceMeters,at}` is the shape the existing
/// FirebaseSyncService already writes, so old and new devices interoperate.
class FirestoreTrackingSource implements TrackingSource {
  FirestoreTrackingSource();

  /// True when Firebase initialised (so the source can be used).
  static bool get available {
    return FirebaseGate.available;
  }

  DocumentReference<Map<String, dynamic>>? _doc;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  final _status = StreamController<ElderStatus?>.broadcast();
  final _alert = StreamController<ActiveAlert?>.broadcast();
  final _visit = StreamController<Visit?>.broadcast();

  ElderStatus? _curStatus;
  ActiveAlert? _curAlert;
  Visit? _curVisit;
  String? _lastVisitKey;

  @override
  bool get isDemo => false;
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
    await _sub?.cancel();
    try {
      _doc = FirebaseFirestore.instance.collection('families').doc(familyCode.toUpperCase());
      _sub = _doc!.snapshots().listen(_onSnap, onError: (_) {});
    } catch (_) {
      _doc = null; // offline / not initialised: stay quiet
    }
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  void _onSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data();
    if (d == null) return;
    // Each block has its own guard: one malformed field must not drop the rest.
    try {
      // status
      final s = d['status'];
      if (s is Map) {
        final st = ElderStatus(
          lat: (s['lat'] as num).toDouble(),
          lng: (s['lng'] as num).toDouble(),
          at: _ts(s['at']) ?? DateTime.now(),
          battery: (s['battery'] as num?)?.toInt(),
          inside: (s['inside'] ?? true) as bool,
          distanceM: ((s['distanceM'] ?? 0) as num).toDouble(),
          bearingDeg: ((s['bearingDeg'] ?? 0) as num).toDouble(),
        );
        _curStatus = st;
        _status.add(st);
      }
    } catch (_) {/* malformed status: ignore */}
    try {
      // alert
      final a = d['lastAlert'];
      if (a is Map) {
        final outside = a['outside'] == true;
        final resolution = (a['resolution'] ?? '') as String;
        final at = _ts(a['at']) ?? DateTime.now();
        final id = (a['id'] ?? at.millisecondsSinceEpoch.toString()) as String;
        if (outside && resolution.isEmpty) {
          final al = ActiveAlert(
            id: id,
            raisedAt: at,
            kind: (a['kind'] ?? 'zone_exit') as String,
            distanceM: ((a['distanceMeters'] ?? 0) as num).toDouble(),
            bearingDeg: ((a['bearingDeg'] ?? 0) as num).toDouble(),
            battery: (a['battery'] as num?)?.toInt(),
            unusualReason: a['unusualReason'] as String?,
            ackBy: a['ackBy'] as String?,
            ackAt: _ts(a['ackAt']),
            etaMin: (a['etaMin'] as num?)?.toInt(),
          );
          _curAlert = al;
          _alert.add(al);
        } else if (_curAlert != null && _curAlert!.id == id) {
          final done = _curAlert!.copyWith(resolution: resolution.isEmpty ? 'returned' : resolution);
          _curAlert = null;
          _alert.add(done);
          _alert.add(null);
        } else if (_curAlert != null && !outside) {
          final done = _curAlert!.copyWith(resolution: 'returned');
          _curAlert = null;
          _alert.add(done);
          _alert.add(null);
        }
      }
    } catch (_) {/* malformed alert: ignore */}
    try {
      // visit
      final v = d['visit'];
      if (v is Map) {
        final at = _ts(v['at']) ?? DateTime.now();
        final key = '${v['by']}-${at.millisecondsSinceEpoch}';
        if (key != _lastVisitKey) {
          _lastVisitKey = key;
          final fresh = DateTime.now().difference(at).inMinutes < 60;
          if (fresh && _curAlert != null) {
            final vis = Visit(
              by: (v['by'] ?? '') as String,
              memberId: v['memberId'] as String?,
              etaMin: ((v['etaMin'] ?? 8) as num).toInt(),
              at: at,
            );
            _curVisit = vis;
            _visit.add(vis);
          }
        }
      } else if (v == null && _curVisit != null) {
        _curVisit = null;
        _visit.add(null);
      }
    } catch (_) {
      /* malformed doc: ignore, never crash */
    }
  }

  Future<void> _merge(Map<String, dynamic> data) async {
    final doc = _doc;
    if (doc == null) return;
    try {
      await doc.set(data, SetOptions(merge: true));
    } catch (_) {/* offline: Firestore queues; errors must not surface */}
  }

  // ── Elder ─────────────────────────────────────────────────────────────

  @override
  Future<void> publishStatus({
    required double lat,
    required double lng,
    int? battery,
    required bool inside,
    required double distanceM,
    required double bearingDeg,
  }) =>
      _merge({
        'status': {
          'lat': lat,
          'lng': lng,
          'at': FieldValue.serverTimestamp(),
          'battery': battery,
          'inside': inside,
          'distanceM': distanceM,
          'bearingDeg': bearingDeg,
        }
      });

  @override
  Future<void> raiseAlert({
    String kind = 'zone_exit',
    required double distanceM,
    required double bearingDeg,
    int? battery,
    String? unusualReason,
  }) {
    final id = 'a${DateTime.now().millisecondsSinceEpoch}';
    return _merge({
      'lastAlert': {
        'id': id,
        'outside': true,
        'kind': kind,
        'distanceMeters': distanceM,
        'bearingDeg': bearingDeg,
        'battery': battery,
        'unusualReason': unusualReason,
        'at': FieldValue.serverTimestamp(),
        'ackBy': null,
        'ackAt': null,
        'etaMin': null,
        'resolution': '',
      },
      'visit': FieldValue.delete(),
    });
  }

  @override
  Future<void> raiseHelp() async {
    await _merge({
      'help': {'at': FieldValue.serverTimestamp()}
    });
    if (_curAlert == null) {
      await raiseAlert(
        kind: 'help',
        distanceM: _curStatus?.distanceM ?? 0,
        bearingDeg: _curStatus?.bearingDeg ?? 0,
        battery: _curStatus?.battery,
      );
    }
  }

  // ── Family ────────────────────────────────────────────────────────────

  @override
  Future<void> acknowledge({required String by}) => _merge({
        'alertAck': {'by': by, 'at': FieldValue.serverTimestamp()},
        'lastAlert': {'ackBy': by, 'ackAt': FieldValue.serverTimestamp()},
      });

  @override
  Future<void> onMyWay({required String by, String? memberId, int etaMin = 8}) => _merge({
        'visit': {'by': by, 'memberId': memberId, 'etaMin': etaMin, 'at': FieldValue.serverTimestamp()},
        'alertAck': {'by': by, 'at': FieldValue.serverTimestamp()},
        'lastAlert': {'ackBy': by, 'ackAt': FieldValue.serverTimestamp(), 'etaMin': etaMin},
      });

  @override
  Future<void> markFound({String resolution = 'found'}) => _merge({
        'lastAlert': {'outside': false, 'resolution': resolution, 'at': FieldValue.serverTimestamp()},
        'visit': FieldValue.delete(),
      });

  // ── Demo-only ─────────────────────────────────────────────────────────

  @override
  Future<void> simulateLeaving() async {}
  @override
  Future<void> fireAlertNow() async {}

  @override
  Future<void> reset() async {
    await _merge({
      'lastAlert': {'outside': false, 'resolution': 'reset'},
      'visit': FieldValue.delete(),
    });
    _curAlert = null;
    _curVisit = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _status.close();
    _alert.close();
    _visit.close();
  }
}
