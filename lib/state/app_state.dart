import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/demo_seed.dart';
import '../data/repository.dart';
import '../models/app_settings.dart';
import '../models/elder_profile.dart';
import '../models/episode_log.dart';
import '../models/family_member.dart';
import '../services/firebase_sync_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

/// Thin ChangeNotifier over the Repository so the UI rebuilds on changes.
class AppState extends ChangeNotifier {
  final Repository repo = Repository.instance;
  late SyncService sync;
  bool ready = false;

  StreamSubscription<List<FamilyMember>>? _memberSub;
  bool _syncStarted = false;

  Timer? _safeZoneTimer;
  bool? _wasInsideSafeZone;
  StreamSubscription<Map<String, dynamic>?>? _alertSub;
  Map<String, dynamic>? _lastAlert;
  Map<String, dynamic>? get lastSafeZoneAlert => _lastAlert;

  StreamSubscription<Map<String, dynamic>?>? _configSub;

  Future<void> init() async {
    await repo.init();
    // Use the cloud when Firebase is up; otherwise stay fully local.
    sync = Firebase.apps.isNotEmpty ? FirebaseSyncService(repo) : LocalSyncService(repo);
    // Preview-only: fill an empty store with a sample family (never saved).
    if (kUseDemoSeed && repo.members.isEmpty) {
      repo.members.addAll(demoFamily(repo.newId));
      if (repo.elder.name.isEmpty) repo.elder.name = 'دادا جان';
      if ((repo.elder.romanName ?? '').isEmpty) repo.elder.romanName = 'Dada Jaan';
    }
    ready = true;
    notifyListeners();
    _startSyncIfNeeded();
    _startSafeZoneMonitorIfNeeded();
    _startSafeZoneConfigWatchIfNeeded();
    if (role == DeviceRole.family) unawaited(_refreshElderName());
  }

  /// Elder device: a family member is meant to set the safe zone remotely
  /// (they know the elder's home, not the other way round). Listen for it
  /// and apply locally the moment it changes.
  void _startSafeZoneConfigWatchIfNeeded() {
    if (role != DeviceRole.elder || _configSub != null || !sync.isConnected) return;
    _configSub = sync.watchSafeZoneConfig().listen((cfg) {
      if (cfg == null) return;
      final lat = (cfg['lat'] as num?)?.toDouble();
      final lng = (cfg['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      final radius = (cfg['radiusMeters'] as num?)?.toDouble();
      final address = cfg['address'] as String?;
      final changed = elder.homeLat != lat ||
          elder.homeLng != lng ||
          (radius != null && elder.safeRadiusMeters != radius) ||
          elder.homeAddress != address;
      if (!changed) return;
      elder.homeLat = lat;
      elder.homeLng = lng;
      if (radius != null) elder.safeRadiusMeters = radius;
      elder.homeAddress = address;
      repo.save();
      notifyListeners();
      _startSafeZoneMonitorIfNeeded();
    });
  }

  /// Family device: pull the elder's name (only — never their coordinates)
  /// so alerts and the family view can address them by name. One-shot;
  /// called on join and on every app launch in case it was missed before.
  Future<void> _refreshElderName() async {
    if (!sync.isConnected) return;
    try {
      final e = await sync.fetchElderName();
      final name = e['name'];
      final roman = e['romanName'];
      if ((name ?? '').isEmpty && (roman ?? '').isEmpty) return;
      if (name != null && name.isNotEmpty) repo.elder.name = name;
      if (roman != null && roman.isNotEmpty) repo.elder.romanName = roman;
      await repo.save();
      notifyListeners();
    } catch (_) {
      /* best-effort — banner falls back to whatever name is already cached */
    }
  }

  /// Elder device with a safe zone set: periodically compares position to the
  /// home circle and, on a boundary crossing, pushes an alert doc that family
  /// devices are watching. Family device: listens for that alert and fires a
  /// real local notification. Foreground-only (this device/app must be
  /// running) — there's no background service, by the same deliberate
  /// restraint as the rest of the safe-zone feature.
  void _startSafeZoneMonitorIfNeeded() {
    if (role == DeviceRole.elder && elder.hasSafeZone && _safeZoneTimer == null) {
      _safeZoneTimer = Timer.periodic(const Duration(minutes: 2), (_) => _checkSafeZoneOnce());
      unawaited(_checkSafeZoneOnce());
    }
    if (role == DeviceRole.family && _alertSub == null && sync.isConnected) {
      _alertSub = sync.watchSafeZoneAlert().listen((alert) {
        if (alert != null && alert['outside'] == true && alert != _lastAlert) {
          final dist = (alert['distanceMeters'] as num?)?.toStringAsFixed(0) ?? '?';
          unawaited(NotificationService.instance.showSafeZoneAlert(
            'Safe zone alert',
            '${elder.romanName ?? elder.name} may have left the safe zone ($dist m from home).',
          ));
        }
        _lastAlert = alert;
        notifyListeners();
      });
    }
  }

  Future<void> _checkSafeZoneOnce() async {
    if (!elder.hasSafeZone) return;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final pos = await Geolocator.getCurrentPosition();
      final d = Geolocator.distanceBetween(elder.homeLat!, elder.homeLng!, pos.latitude, pos.longitude);
      final inside = d <= elder.safeRadiusMeters;
      if (_wasInsideSafeZone == true && !inside) {
        unawaited(sync.pushSafeZoneAlert(outside: true, distanceMeters: d));
      } else if (_wasInsideSafeZone == false && inside) {
        unawaited(sync.pushSafeZoneAlert(outside: false, distanceMeters: d));
      }
      _wasInsideSafeZone = inside;
    } catch (_) {
      /* best-effort; try again next tick */
    }
  }

  /// Once a role + family code exist and the cloud is connected, mirror the
  /// family's members into the local store in realtime.
  void _startSyncIfNeeded() {
    if (_syncStarted || !sync.isConnected) return;
    if (role == DeviceRole.unset || settings.familyCode == null) return;
    _syncStarted = true;
    _memberSub = sync.watchMembers().listen((members) async {
      repo.members
        ..clear()
        ..addAll(members);
      await repo.save();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _memberSub?.cancel();
    _safeZoneTimer?.cancel();
    _alertSub?.cancel();
    _configSub?.cancel();
    super.dispose();
  }

  AppSettings get settings => repo.settings;
  DeviceRole get role => repo.settings.role;

  /// Elder device: create a family and adopt the elder role.
  Future<String> becomeElderDevice() async {
    final code = await sync.createFamily();
    repo.settings
      ..role = DeviceRole.elder
      ..familyCode = code;
    await repo.save();
    unawaited(sync.pushElder(repo.elder));
    notifyListeners();
    _startSyncIfNeeded();
    _startSafeZoneConfigWatchIfNeeded();
    return code;
  }

  /// Family device: join an existing family by code. If [email] is given
  /// (from Google Sign-In) and the family has an email allow-list, the
  /// account must be on it. Returns null on success, or a message to show.
  Future<String?> becomeFamilyDevice(String code, String contributorName, {String? email}) async {
    final normalized = code.trim().toUpperCase();
    final ok = await sync.joinFamily(normalized);
    if (!ok) return 'That family code was not found.';
    final allow = await sync.fetchAuthorizedEmails(normalized);
    if (allow.isNotEmpty) {
      if (email == null) {
        return 'This family only accepts approved Google accounts. Sign in with Google to continue.';
      }
      if (!allow.contains(email.toLowerCase())) {
        return '$email isn\'t on this family\'s approved list yet. Ask them to add it in Family setup → Invite family.';
      }
    }
    repo.settings
      ..role = DeviceRole.family
      ..familyCode = normalized
      ..contributorName = contributorName.trim()
      ..signedInEmail = email;
    await repo.save();
    // Pull whatever the family already has.
    final remote = await sync.fetchMembers();
    if (sync.isConnected) {
      repo.members
        ..clear()
        ..addAll(remote);
      await repo.save();
    }
    notifyListeners();
    _startSyncIfNeeded();
    _startSafeZoneMonitorIfNeeded();
    unawaited(_refreshElderName());
    return null;
  }

  /// Switch this device back to the role picker (e.g. to re-link).
  Future<void> resetRole() async {
    await _memberSub?.cancel();
    _memberSub = null;
    _syncStarted = false;
    _safeZoneTimer?.cancel();
    _safeZoneTimer = null;
    await _alertSub?.cancel();
    _alertSub = null;
    await _configSub?.cancel();
    _configSub = null;
    _wasInsideSafeZone = null;
    _lastAlert = null;
    repo.settings
      ..role = DeviceRole.unset
      ..familyCode = null
      ..contributorName = null
      ..signedInEmail = null;
    await repo.save();
    notifyListeners();
  }

  ElderProfile get elder => repo.elder;
  List<FamilyMember> get members => List.unmodifiable(repo.members);
  bool get roman => repo.elder.preferRomanScript;

  List<String> get authorizedEmails => List.unmodifiable(repo.settings.authorizedEmails);

  /// Elder device: set which Google accounts may join this family by code.
  Future<void> setAuthorizedEmails(List<String> emails) async {
    repo.settings.authorizedEmails = emails.map((e) => e.trim().toLowerCase()).toList();
    await repo.save();
    notifyListeners();
    unawaited(sync.setAuthorizedEmails(repo.settings.authorizedEmails));
  }

  Future<void> saveElder() async {
    await repo.save();
    notifyListeners();
    unawaited(sync.pushElder(elder));
    if (elder.hasSafeZone) {
      unawaited(sync.pushSafeZoneConfig(
        lat: elder.homeLat!,
        lng: elder.homeLng!,
        address: elder.homeAddress,
        radiusMeters: elder.safeRadiusMeters,
      ));
    }
    _startSafeZoneMonitorIfNeeded();
  }

  Future<void> toggleScript() async {
    repo.elder.preferRomanScript = !repo.elder.preferRomanScript;
    await repo.save();
    notifyListeners();
  }

  Future<void> upsertMember(FamilyMember m) async {
    await repo.upsertMember(m);
    notifyListeners();
    unawaited(sync.pushMember(m)); // syncs to the family when connected
  }

  Future<void> removeMember(String id) async {
    await repo.removeMember(id);
    notifyListeners();
    unawaited(sync.deleteMember(id));
  }

  FamilyMember? memberById(String id) => repo.memberById(id);

  List<Episode> get episodes => List.unmodifiable(repo.episodes);

  void logEpisode(Episode e) {
    repo.episodes.add(e);
    // Keep the log bounded and persist quietly.
    if (repo.episodes.length > 500) {
      repo.episodes.removeRange(0, repo.episodes.length - 500);
    }
    repo.save();
    notifyListeners();
  }
}
