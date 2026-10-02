import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config.dart';
import '../data/demo_seed.dart';
import '../data/repository.dart';
import '../models/app_settings.dart';
import '../models/care.dart';
import '../models/elder_profile.dart';
import '../models/episode_log.dart';
import '../models/family_member.dart';
import '../services/firebase_gate.dart';
import '../services/firebase_sync_service.dart';
import '../services/platform/platform.dart';
import '../services/sync_service.dart';
import '../tracking/demo_tracking_source.dart';
import '../tracking/firestore_tracking_source.dart';
import '../tracking/tracking_source.dart';
import '../util/app_clock.dart';
import '../util/hijri.dart';
import '../util/prayer.dart';
import '../util/time_mode.dart';
import '../util/urdu_format.dart';

/// The three phone views the presenter can switch between on ONE phone.
enum DemoView { elder, bilal, fatima }

/// Counts for the Weekly report (last 7 days, ending now).
class WeeklyStats {
  final int questions;
  final int questionsAfterAsr;
  final Map<String, int> byQuestion; // day|where|bilal|food|medicine|ruqayya
  final int ruqayyaAfterMaghrib;
  final int calmPlays;
  final int zoneExits;
  final int nightPickups;
  final int voicesPlayed;
  final Map<String, int> voicesByMember; // memberId -> plays
  final int dosesTaken; // last 7 completed days
  final int dosesTotal;
  const WeeklyStats({
    required this.questions,
    required this.questionsAfterAsr,
    required this.byQuestion,
    required this.ruqayyaAfterMaghrib,
    required this.calmPlays,
    required this.zoneExits,
    required this.nightPickups,
    required this.voicesPlayed,
    required this.voicesByMember,
    required this.dosesTaken,
    required this.dosesTotal,
  });
}

/// Thin ChangeNotifier over the Repository so the UI rebuilds on changes.
/// Provide with `ChangeNotifierProvider(create: (_) => AppState()..init())`.
class AppState extends ChangeNotifier {
  AppState({Repository? repo, TrackingSource? tracking})
      : repo = repo ?? Repository.instance,
        _tracking = tracking {
    sync = LocalSyncService(this.repo);
    AppClock.revision.addListener(_onClock);
  }

  /// A ready-to-render state with the full demo family, no disk, no timers.
  /// Used by the golden harness and widget tests.
  factory AppState.seeded({
    DateTime? now,
    DemoView view = DemoView.elder,
    bool seeded = true,
    TrackingSource? tracking,
  }) {
    final repo = Repository.create()..initMemory();
    final s = AppState(repo: repo, tracking: tracking ?? DemoTrackingSource(now: AppClock.now));
    if (seeded) applyDemoSeed(repo, now: now);
    s._applyView(view);
    if (!seeded) {
      repo.settings.contributorName = null;
    }
    s.ready = true;
    final fam = repo.settings.familyCode ?? kDemoFamilyCode;
    repo.settings.familyCode = fam;
    unawaited(s.tracking.start(familyCode: fam, home: s.homePoint));
    s._attachTracking();
    return s;
  }

  final Repository repo;
  late SyncService sync;
  bool ready = false;

  TrackingSource? _tracking;
  TrackingSource get tracking => _tracking ??= DemoTrackingSource(now: AppClock.now);

  StreamSubscription<List<FamilyMember>>? _memberSub;
  StreamSubscription<Map<String, dynamic>?>? _configSub;
  StreamSubscription<ElderStatus?>? _statusSub;
  StreamSubscription<ActiveAlert?>? _alertSub;
  StreamSubscription<Visit?>? _visitSub;
  bool _syncStarted = false;
  bool _trackingStarted = false;

  Timer? _gpsTimer;
  Timer? _routineTimer;
  bool? _wasInside;
  final Set<String> _notifiedAlerts = {};
  final Set<String> _promptedToday = {};
  final StreamController<RoutineItem> _prompts = StreamController<RoutineItem>.broadcast();

  // ── Boot ──────────────────────────────────────────────────────────────

  /// Loads the store and wires background work. Never throws.
  Future<void> init() async {
    try {
      await repo.init();
    } catch (_) {}
    try {
      sync = FirebaseGate.available ? FirebaseSyncService(repo) : LocalSyncService(repo);
    } catch (_) {
      sync = LocalSyncService(repo);
    }
    ready = true;
    notifyListeners();
    startBackground();
    if (role == DeviceRole.family) unawaited(_refreshElderName());
  }

  /// Starts sync, tracking, the elder GPS monitor and routine prompts for the
  /// current role. Safe to call again after a role change.
  void startBackground() {
    _startSyncIfNeeded();
    _startConfigWatchIfNeeded();
    unawaited(startTracking());
    _startRoutineTimer();
    _startGpsMonitorIfNeeded();
  }

  void _onClock() => notifyListeners();

  /// Rebuild listeners after mutating settings/care objects directly.
  void refresh() => notifyListeners();

  @override
  void dispose() {
    AppClock.revision.removeListener(_onClock);
    _memberSub?.cancel();
    _configSub?.cancel();
    _statusSub?.cancel();
    _alertSub?.cancel();
    _visitSub?.cancel();
    _gpsTimer?.cancel();
    _routineTimer?.cancel();
    _prompts.close();
    _tracking?.dispose();
    super.dispose();
  }

  // ── Basic getters ─────────────────────────────────────────────────────

  AppSettings get settings => repo.settings;
  DeviceRole get role => repo.settings.role;
  bool get isElder => role == DeviceRole.elder;
  bool get isFamily => role == DeviceRole.family;
  bool get isCaregiver => role == DeviceRole.family && repo.settings.isCaregiver;
  ElderProfile get elder => repo.elder;
  CareData get care => repo.care;
  List<FamilyMember> get members => List.unmodifiable(repo.members);
  List<FamilyMember> get livingMembers => repo.members.where((m) => !m.isDeceased).toList();
  FamilyMember? memberById(String id) => repo.memberById(id);
  bool get hasFamily => repo.members.isNotEmpty;
  bool get roman => repo.elder.preferRomanScript; // legacy; elder UI is Urdu only
  List<String> get authorizedEmails => List.unmodifiable(repo.settings.authorizedEmails);

  /// Real clock unless the presenter previewed another time.
  DateTime get now => AppClock.now();
  TimeMode get timeMode => timeModeAt(now);
  PrayerDay get prayerToday => PrayerTimes.forDate(now);
  HijriDate get hijriToday => HijriDate.fromGregorian(now, offsetDays: repo.settings.hijriOffsetDays);

  /// "YD-7F3K" (the stored code has no prefix).
  String get familyCodeDisplay {
    final c = repo.settings.familyCode;
    return c == null || c.isEmpty ? '' : '$kFamilyCodePrefix${c.toUpperCase()}';
  }

  /// Elder name for English screens ("Dada Jaan"), never empty.
  String get elderNameEn => (repo.elder.romanName ?? '').isNotEmpty ? repo.elder.romanName! : 'Dada Jaan';

  /// Elder name for Urdu screens ("دادا جان"), never empty, never Latin.
  String get elderNameUr {
    final n = repo.elder.name;
    return RegExp(r'[؀-ۿ]').hasMatch(n) ? n : 'دادا جان';
  }

  /// Name of the person using this device (English), for attribution.
  String get myNameEn {
    final n = repo.settings.contributorName;
    if (n != null && n.trim().isNotEmpty) return n.trim();
    return isElder ? elderNameEn : 'Family';
  }

  FamilyMember? get primaryContact {
    for (final m in repo.members) {
      if (m.isPrimaryContact && !m.isDeceased) return m;
    }
    for (final m in repo.members) {
      if (!m.isDeceased && (m.phone ?? '').isNotEmpty) return m;
    }
    return null;
  }

  // ── Role / onboarding ─────────────────────────────────────────────────

  Future<String> becomeElderDevice() async {
    String code;
    try {
      code = await sync.createFamily().timeout(const Duration(seconds: 5));
    } catch (_) {
      code = SyncService.generateCode();
    }
    repo.settings
      ..role = DeviceRole.elder
      ..isCaregiver = false
      ..familyCode = code;
    await repo.save();
    try {
      unawaited(sync.pushElder(repo.elder));
    } catch (_) {}
    notifyListeners();
    startBackground();
    return code;
  }

  /// Family device: join by code. Returns null on success or a message.
  Future<String?> becomeFamilyDevice(String code, String contributorName, {String? email, bool caregiver = false}) async {
    final normalized = code.trim().toUpperCase().replaceFirst(kFamilyCodePrefix, '');
    bool ok;
    try {
      ok = await sync.joinFamily(normalized).timeout(const Duration(seconds: 8));
    } catch (_) {
      return "Couldn't reach the family. Check the internet connection and try again.";
    }
    if (!ok) return 'That family code was not found.';
    final allow = await sync.fetchAuthorizedEmails(normalized).timeout(const Duration(seconds: 6), onTimeout: () => <String>[]);
    if (allow.isNotEmpty) {
      if (email == null) {
        return 'This family only accepts approved Google accounts. Sign in with Google to continue.';
      }
      if (!allow.contains(email.toLowerCase())) {
        return "$email isn't on this family's approved list yet. Ask them to add it.";
      }
    }
    repo.settings
      ..role = DeviceRole.family
      ..isCaregiver = caregiver
      ..familyCode = normalized
      ..contributorName = contributorName.trim()
      ..signedInEmail = email;
    await repo.save();
    final remote = sync.isConnected
        ? await sync.fetchMembers().timeout(const Duration(seconds: 8), onTimeout: () => <FamilyMember>[])
        : <FamilyMember>[];
    if (sync.isConnected) {
      _mergeRemote(remote);
      await repo.save();
    }
    notifyListeners();
    startBackground();
    unawaited(_refreshElderName());
    return null;
  }

  Future<void> setCaregiver(bool v) async {
    repo.settings.isCaregiver = v;
    await repo.save();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    repo.settings.onboarded = true;
    await repo.save();
    notifyListeners();
  }

  /// Back to the role picker (keeps family data).
  Future<void> resetRole() async {
    await _stopBackground();
    repo.settings
      ..role = DeviceRole.unset
      ..isCaregiver = false
      ..familyCode = null
      ..contributorName = null
      ..contributorMemberId = null
      ..signedInEmail = null;
    await repo.save();
    notifyListeners();
  }

  Future<void> _stopBackground() async {
    await _memberSub?.cancel();
    _memberSub = null;
    _syncStarted = false;
    await _configSub?.cancel();
    _configSub = null;
    _gpsTimer?.cancel();
    _gpsTimer = null;
    _routineTimer?.cancel();
    _routineTimer = null;
    await _statusSub?.cancel();
    await _alertSub?.cancel();
    await _visitSub?.cancel();
    _statusSub = _alertSub = _visitSub = null;
    _trackingStarted = false;
    try {
      await tracking.stop();
    } catch (_) {}
    _wasInside = null;
  }

  // ── Permissions (called from the Permissions onboarding screen) ───────

  /// Elder phone: ask for location (fine/coarse). Returns whether granted.
  Future<bool> requestLocationPermission() async {
    final ok = await Svc.location.ensurePermission();
    if (ok) _startGpsMonitorIfNeeded();
    return ok;
  }

  Future<bool> requestNotificationPermission() => Svc.notify.requestPermission();
  Future<bool> requestMicPermission() => Svc.audio.hasMicPermission();

  // ── Cloud sync (members + remote safe zone) ───────────────────────────

  void _startSyncIfNeeded() {
    if (_syncStarted || !sync.isConnected) return;
    if (role == DeviceRole.unset || repo.settings.familyCode == null) return;
    _syncStarted = true;
    _memberSub = sync.watchMembers().listen((remote) async {
      _mergeRemote(remote);
      await repo.save();
      notifyListeners();
    }, onError: (_) {});
  }

  /// Remote members are authoritative for existence and the legacy fields;
  /// local-only richer fields (kinship, nicknames, tint, ...) are kept.
  void _mergeRemote(List<FamilyMember> remote) {
    if (remote.isEmpty) return;
    final byId = {for (final m in repo.members) m.id: m};
    final merged = <FamilyMember>[];
    for (final r in remote) {
      final local = byId[r.id];
      if (local != null) {
        local.mergeRemote(r);
        merged.add(local);
      } else {
        merged.add(r);
      }
    }
    repo.members
      ..clear()
      ..addAll(merged);
  }

  void _startConfigWatchIfNeeded() {
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
    }, onError: (_) {});
  }

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
    } catch (_) {}
  }

  Future<void> setAuthorizedEmails(List<String> emails) async {
    repo.settings.authorizedEmails = emails.map((e) => e.trim().toLowerCase()).toList();
    await repo.save();
    notifyListeners();
    unawaited(sync.setAuthorizedEmails(repo.settings.authorizedEmails));
  }

  // ── Elder profile ─────────────────────────────────────────────────────

  Future<void> saveElder() async {
    await repo.save();
    notifyListeners();
    try {
      unawaited(sync.pushElder(elder));
      if (elder.hasSafeZone) {
        unawaited(sync.pushSafeZoneConfig(
          lat: elder.homeLat!,
          lng: elder.homeLng!,
          address: elder.homeAddress,
          radiusMeters: elder.safeRadiusMeters,
        ));
      }
    } catch (_) {}
  }

  Future<void> toggleScript() async {
    repo.elder.preferRomanScript = !repo.elder.preferRomanScript;
    await repo.save();
    notifyListeners();
  }

  // ── Members ───────────────────────────────────────────────────────────

  Future<void> upsertMember(FamilyMember m) async {
    await repo.upsertMember(m);
    notifyListeners();
    try {
      unawaited(sync.pushMember(m));
    } catch (_) {}
  }

  Future<void> removeMember(String id) async {
    await repo.removeMember(id);
    care.circle.removeWhere((c) => c.memberId == id);
    care.letters.removeWhere((l) => l.memberId == id);
    await repo.save();
    notifyListeners();
    try {
      unawaited(sync.deleteMember(id));
    } catch (_) {}
  }

  String newId() => repo.newId();

  /// Stores a captured file permanently and returns its path (or null).
  Future<String?> storeMedia(String? tempPath) => repo.ensureStored(tempPath);

  // ── Poochhein answers ─────────────────────────────────────────────────

  Answer answerFor(String questionId) {
    for (final a in care.answers) {
      if (a.questionId == questionId) return a;
    }
    final a = Answer(questionId: questionId);
    care.answers.add(a);
    return a;
  }

  /// Urdu answer text for the elder, with `{day}` / `{part}` filled from the
  /// live clock. The "medicine" answer is always computed from the Routine.
  /// Empty string means "no answer yet" (show the calm empty state).
  String answerText(String questionId) {
    if (questionId == 'medicine') return medicineAnswerUr();
    final t = answerFor(questionId).textUr;
    if (t.trim().isEmpty) return '';
    final n = now;
    return t.replaceAll('{day}', UrduFmt.weekday(n)).replaceAll('{part}', UrduFmt.period(n));
  }

  /// "اگلی دوا شام ۶:۴۵ پر ہے۔" or "آج کی سب دوائیں لے لی ہیں۔"
  String medicineAnswerUr() {
    final next = nextRoutineItem(kind: RoutineKind.medicine);
    if (next == null) return 'آج کی سب دوائیں لے لی ہیں۔';
    return 'اگلی دوا ${UrduFmt.time(routineDueAt(next))} پر ہے۔';
  }

  Future<void> saveAnswer(
    String questionId, {
    String? textUr,
    String? audioTempPath,
    String? byName,
    int? durationSec,
  }) async {
    final a = answerFor(questionId);
    if (textUr != null) a.textUr = textUr;
    if (audioTempPath != null) {
      final stored = await repo.ensureStored(audioTempPath);
      a.audioPath = stored;
      a.durationSec = durationSec ?? a.durationSec;
    }
    a.byName = byName ?? (myNameEn);
    a.recordedAt = now;
    await repo.save();
    notifyListeners();
  }

  Future<void> clearAnswer(String questionId) async {
    final a = answerFor(questionId);
    a.textUr = '';
    a.audioPath = null;
    a.recordedAt = null;
    a.durationSec = 0;
    a.byName = '';
    await repo.save();
    notifyListeners();
  }

  /// Elder asked a Poochhein question: bump the counter, log the episode.
  Future<void> recordQuestionAsked(String questionId) async {
    answerFor(questionId).askedCount++;
    logEpisode(Episode(category: 'question', severity: questionId == 'ruqayya' ? 2 : 1, at: now, question: questionId));
  }

  // ── Routine ───────────────────────────────────────────────────────────

  List<RoutineItem> get routine => List.unmodifiable(care.routine);

  /// When [item] is due on the day of [day] (default today); prayer-anchored
  /// items follow the Karachi table.
  DateTime routineDueAt(RoutineItem item, [DateTime? day]) {
    final d = day ?? now;
    if (item.anchor != null) {
      for (final p in Prayer.values) {
        if (p.name == item.anchor) {
          return PrayerTimes.forDate(d).at(p).add(Duration(minutes: item.anchorOffsetMin));
        }
      }
    }
    return DateTime(d.year, d.month, d.day, item.hour, item.minute);
  }

  RoutineLog? routineLogToday(String itemId) {
    final key = RoutineLog.dayKey(now);
    for (final l in care.routineLogs) {
      if (l.itemId == itemId && l.day == key) return l;
    }
    return null;
  }

  /// The next enabled item today that is not yet logged and not long past.
  RoutineItem? nextRoutineItem({RoutineKind? kind}) {
    final n = now;
    final items = care.routine.where((i) => i.enabled && (kind == null || i.kind == kind)).toList()
      ..sort((a, b) => routineDueAt(a).compareTo(routineDueAt(b)));
    for (final i in items) {
      if (routineLogToday(i.id) != null) continue;
      if (routineDueAt(i).isBefore(n.subtract(const Duration(minutes: 90)))) continue;
      return i;
    }
    return null;
  }

  Future<void> markRoutine(String itemId, String status, {String? by}) async {
    final key = RoutineLog.dayKey(now);
    care.routineLogs.removeWhere((l) => l.itemId == itemId && l.day == key);
    care.routineLogs.add(RoutineLog(itemId: itemId, day: key, status: status, at: now, by: by ?? myNameEn));
    await repo.save();
    notifyListeners();
  }

  Future<void> saveRoutineItem(RoutineItem item) async {
    final i = care.routine.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      care.routine[i] = item;
    } else {
      care.routine.add(item);
    }
    await repo.save();
    notifyListeners();
  }

  Future<void> removeRoutineItem(String id) async {
    care.routine.removeWhere((e) => e.id == id);
    await repo.save();
    notifyListeners();
  }

  Future<void> saveRoutineConfig({bool? quietAfterIsha, bool? nightPickupNudge, bool? promptsOn}) async {
    final c = care.routineConfig;
    if (quietAfterIsha != null) c.quietAfterIsha = quietAfterIsha;
    if (nightPickupNudge != null) c.nightPickupNudge = nightPickupNudge;
    if (promptsOn != null) c.promptsOn = promptsOn;
    await repo.save();
    notifyListeners();
  }

  /// Doses/meals over the last 7 completed days (excludes walks).
  ({int taken, int total}) routineWeek() {
    final n = now;
    final from = RoutineLog.dayKey(DateTime(n.year, n.month, n.day).subtract(const Duration(days: 7)));
    final to = RoutineLog.dayKey(DateTime(n.year, n.month, n.day));
    final ids = care.routine.where((i) => i.kind != RoutineKind.walk).map((i) => i.id).toSet();
    var taken = 0, total = 0;
    for (final l in care.routineLogs) {
      if (!ids.contains(l.itemId)) continue;
      if (l.day.compareTo(from) < 0 || l.day.compareTo(to) >= 0) continue;
      total++;
      if (l.status == 'taken') taken++;
    }
    return (taken: taken, total: total);
  }

  /// Elder-side prompts (due items); ElderReaction opens /elder/routine-prompt.
  Stream<RoutineItem> get routinePrompts => _prompts.stream;

  /// Presenter: fire a prompt right now for the next (or first) item.
  void testRoutinePrompt() {
    final item = nextRoutineItem() ?? (care.routine.isNotEmpty ? care.routine.first : null);
    if (item != null && !_prompts.isClosed) _prompts.add(item);
  }

  void _startRoutineTimer() {
    _routineTimer?.cancel();
    if (role != DeviceRole.elder) return;
    _routineTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkRoutineDue());
  }

  void _checkRoutineDue() {
    if (!care.routineConfig.promptsOn || _prompts.isClosed) return;
    final n = now;
    final day = RoutineLog.dayKey(n);
    _promptedToday.removeWhere((k) => !k.startsWith(day));
    if (care.routineConfig.quietAfterIsha && !n.isBefore(prayerToday.isha)) return;
    for (final i in care.routine) {
      if (!i.enabled) continue;
      final due = routineDueAt(i);
      final key = '$day/${i.id}';
      if (n.isBefore(due) || n.isAfter(due.add(const Duration(minutes: 30)))) continue;
      if (_promptedToday.contains(key) || routineLogToday(i.id) != null) continue;
      _promptedToday.add(key);
      _prompts.add(i);
      break;
    }
  }

  // ── Consent ───────────────────────────────────────────────────────────

  ConsentRecord? get consent => care.consent;

  Future<void> saveConsent(ConsentRecord c) async {
    care.consent = c;
    await repo.save();
    notifyListeners();
  }

  // ── Care circle ───────────────────────────────────────────────────────

  List<CircleMember> get circle => List.unmodifiable(care.circle);
  Handoff? get handoff => care.handoff;

  CircleMember? circleEntry(String memberId) {
    for (final c in care.circle) {
      if (c.memberId == memberId) return c;
    }
    return null;
  }

  /// Whoever is on shift now (24h shifts may wrap midnight).
  CircleMember? get onShiftNow {
    final h = now.hour;
    for (final c in care.circle) {
      final s = c.shiftStartHour, e = c.shiftEndHour;
      if (s == null || e == null) continue;
      final on = s < e ? (h >= s && h < e) : (h >= s || h < e);
      if (on) return c;
    }
    return null;
  }

  Future<void> saveCircleMember(CircleMember c) async {
    final i = care.circle.indexWhere((e) => e.memberId == c.memberId);
    if (i >= 0) {
      care.circle[i] = c;
    } else {
      care.circle.add(c);
    }
    await repo.save();
    notifyListeners();
  }

  Future<void> removeCircleMember(String memberId) async {
    care.circle.removeWhere((c) => c.memberId == memberId);
    await repo.save();
    notifyListeners();
  }

  Future<void> saveHandoff(String text, {String? shiftLabel}) async {
    care.handoff = Handoff(text: text.trim(), byName: myNameEn, shiftLabel: shiftLabel ?? care.handoff?.shiftLabel ?? '', at: now);
    await repo.save();
    notifyListeners();
  }

  // ── Voice letters ─────────────────────────────────────────────────────

  /// Newest first.
  List<VoiceLetter> get letters => (List.of(care.letters)..sort((a, b) => b.at.compareTo(a.at)));
  List<VoiceLetter> get unseenLetters => letters.where((l) => !l.seen).toList();

  Future<VoiceLetter> addLetter(String memberId, {String? audioTempPath, int durationSec = 0}) async {
    final stored = audioTempPath == null ? null : await repo.ensureStored(audioTempPath);
    final l = VoiceLetter(id: newId(), memberId: memberId, at: now, durationSec: durationSec, audioPath: stored);
    care.letters.add(l);
    await repo.save();
    notifyListeners();
    return l;
  }

  Future<void> markLetterSeen(String id) async {
    for (final l in care.letters) {
      if (l.id == id && !l.seen) {
        l.seen = true;
      }
    }
    await repo.save();
    notifyListeners();
  }

  /// Elder taps play on a letter: plays audio if any, marks seen, counts it.
  Future<void> playLetter(VoiceLetter l) async {
    l.seen = true;
    l.playCount++;
    logEpisode(Episode(category: 'voice_played', at: now, note: l.memberId));
    final p = l.audioPath;
    if (p != null) await Svc.audio.play(p);
  }

  // ── Safe zones ────────────────────────────────────────────────────────

  List<SafeZone> get zones => List.unmodifiable(care.zones);

  SafeZone? get homeZone {
    for (final z in care.zones) {
      if (z.id == DemoIds.zoneHome || z.name.toLowerCase() == 'home') return z;
    }
    return null;
  }

  /// Home centre + radius: from the Home zone, else the elder profile, else
  /// the demo home (so the demo radar always has a centre).
  HomePoint get homePoint {
    final z = homeZone;
    if (z != null) return HomePoint(z.lat, z.lng, z.radiusM);
    if (elder.hasSafeZone) return HomePoint(elder.homeLat!, elder.homeLng!, elder.safeRadiusMeters);
    return const HomePoint(kDemoHomeLat, kDemoHomeLng, 150);
  }

  Future<void> saveZone(SafeZone z) async {
    final i = care.zones.indexWhere((e) => e.id == z.id);
    if (i >= 0) {
      care.zones[i] = z;
    } else {
      care.zones.add(z);
    }
    if (z.name.toLowerCase() == 'home' || z.id == DemoIds.zoneHome) {
      elder.homeLat = z.lat;
      elder.homeLng = z.lng;
      elder.safeRadiusMeters = z.radiusM;
    }
    await repo.save();
    notifyListeners();
    try {
      if (elder.hasSafeZone) {
        unawaited(sync.pushSafeZoneConfig(
          lat: elder.homeLat!,
          lng: elder.homeLng!,
          address: elder.homeAddress,
          radiusMeters: elder.safeRadiusMeters,
        ));
      }
    } catch (_) {}
  }

  Future<void> removeZone(String id) async {
    care.zones.removeWhere((z) => z.id == id);
    await repo.save();
    notifyListeners();
  }

  Future<void> setNightRule(bool v) async {
    care.nightRule = v;
    await repo.save();
    notifyListeners();
  }

  // ── Episodes ──────────────────────────────────────────────────────────

  List<Episode> get episodes => List.unmodifiable(repo.episodes);

  void logEpisode(Episode e) {
    repo.episodes.add(e);
    if (repo.episodes.length > 800) {
      repo.episodes.removeRange(0, repo.episodes.length - 800);
    }
    repo.save();
    notifyListeners();
  }

  List<Episode> episodesSince(DateTime from) => repo.episodes.where((e) => !e.at.isBefore(from)).toList();

  WeeklyStats weeklyStats() {
    final n = now;
    final from = n.subtract(const Duration(days: 7));
    final es = episodesSince(from);
    final byQ = <String, int>{};
    var afterAsr = 0, ruqMaghrib = 0, calm = 0, exits = 0, nights = 0, voices = 0;
    final byMember = <String, int>{};
    for (final e in es) {
      final p = PrayerTimes.forDate(e.at);
      switch (e.category) {
        case 'question':
          final q = e.question ?? 'unknown';
          byQ[q] = (byQ[q] ?? 0) + 1;
          if (!e.at.isBefore(p.asr)) afterAsr++;
          if (q == 'ruqayya' && !e.at.isBefore(p.maghrib)) ruqMaghrib++;
          break;
        case 'calm':
          calm++;
          break;
        case 'zone_exit':
          exits++;
          break;
        case 'night_pickup':
          nights++;
          break;
        case 'voice_played':
          voices++;
          final m = e.note ?? '';
          if (m.isNotEmpty) byMember[m] = (byMember[m] ?? 0) + 1;
          break;
      }
    }
    final week = routineWeek();
    return WeeklyStats(
      questions: byQ.values.fold(0, (a, b) => a + b),
      questionsAfterAsr: afterAsr,
      byQuestion: byQ,
      ruqayyaAfterMaghrib: ruqMaghrib,
      calmPlays: calm,
      zoneExits: exits,
      nightPickups: nights,
      voicesPlayed: voices,
      voicesByMember: byMember,
      dosesTaken: week.taken,
      dosesTotal: week.total,
    );
  }

  // ── Tracking ──────────────────────────────────────────────────────────

  ElderStatus? get elderStatus => tracking.currentStatus;
  ActiveAlert? get activeAlert => tracking.currentAlert;
  Visit? get currentVisit => tracking.currentVisit;
  List<AlertRecord> get alertHistory => (List.of(care.alerts)..sort((a, b) => b.at.compareTo(a.at)));

  /// Creates the backend (Firestore only if configured AND Firebase is up,
  /// else the demo source) and starts listening. Idempotent.
  Future<void> startTracking() async {
    if (_trackingStarted || role == DeviceRole.unset) return;
    if (_tracking == null) {
      final useFs = !kTrackingIsDemo && FirestoreTrackingSource.available;
      _tracking = useFs ? FirestoreTrackingSource() : DemoTrackingSource(now: AppClock.now);
    }
    _trackingStarted = true;
    _attachTracking();
    try {
      await tracking.start(familyCode: repo.settings.familyCode ?? kDemoFamilyCode, home: homePoint);
    } catch (_) {}
  }

  void _attachTracking() {
    _statusSub?.cancel();
    _alertSub?.cancel();
    _visitSub?.cancel();
    _statusSub = tracking.status.listen((_) => notifyListeners());
    _alertSub = tracking.alert.listen(_onAlert);
    _visitSub = tracking.visit.listen((_) => notifyListeners());
  }

  void _onAlert(ActiveAlert? a) {
    if (a != null) {
      var rec = care.alerts.where((r) => r.id == a.id).firstOrNull;
      final isNew = rec == null;
      if (rec == null) {
        rec = AlertRecord(id: a.id, at: a.raisedAt, kind: a.kind);
        care.alerts.add(rec);
        if (a.kind == 'zone_exit') {
          repo.episodes.add(Episode(category: 'zone_exit', severity: 2, at: a.raisedAt));
        } else {
          repo.episodes.add(Episode(category: 'distress', severity: 3, at: a.raisedAt));
        }
      }
      rec
        ..distanceM = a.distanceM
        ..bearingDeg = a.bearingDeg
        ..ackBy = a.ackBy ?? rec.ackBy
        ..ackAt = a.ackAt ?? rec.ackAt
        ..etaMin = a.etaMin ?? rec.etaMin;
      if (a.isResolved) {
        rec
          ..resolvedAt = now
          ..resolution = a.resolution;
        repo.episodes.add(Episode(category: 'zone_return', at: now));
      }
      // One system notification per alert id, family devices only.
      if (isNew && role == DeviceRole.family && !a.isResolved && _notifiedAlerts.add(a.id)) {
        final dist = a.distanceM.round();
        unawaited(Svc.notify.show(
          a.kind == 'help' ? 'Help requested' : 'Safe zone alert',
          a.kind == 'help'
              ? '$elderNameEn pressed the help button.'
              : '$elderNameEn may have left the safe zone ($dist m from home).',
        ));
      }
      repo.save();
    }
    notifyListeners();
  }

  /// Family: acknowledge the active alert as this device's user.
  Future<void> acknowledgeAlert() => tracking.acknowledge(by: myNameEn);

  /// Family: "I'm on my way" -> the elder phone shows ImSafe.
  Future<void> imOnMyWay({int etaMin = 8}) =>
      tracking.onMyWay(by: myNameEn, memberId: repo.settings.contributorMemberId, etaMin: etaMin);

  /// Family: mark found / back home, closing the alert.
  Future<void> markFound({String resolution = 'found'}) => tracking.markFound(resolution: resolution);

  /// Elder: the help button (Madad).
  Future<void> raiseHelp() async {
    // The episode is logged once, by _onAlert, when the help alert appears.
    if (tracking.currentAlert != null) return;
    await tracking.raiseHelp();
  }

  // ── Real GPS monitor (Firestore backend only) ─────────────────────────

  void _startGpsMonitorIfNeeded() {
    // In demo mode the script owns the state; the real GPS would false-alert
    // on a presenter's phone / emulator.
    if (kTrackingIsDemo) return;
    if (!FirestoreTrackingSource.available) return;
    if (role != DeviceRole.elder || _gpsTimer != null) return;
    _gpsTimer = Timer.periodic(const Duration(minutes: 2), (_) => _gpsCheck());
    unawaited(_gpsCheck(firstRun: true));
  }

  Future<void> _gpsCheck({bool firstRun = false}) async {
    final home = homePoint;
    try {
      // Ask for permission up front on the elder phone (inventory §7).
      final ok = firstRun ? await Svc.location.ensurePermission() : await Svc.location.hasPermission();
      if (!ok) return;
      final fix = await Svc.location.current();
      if (fix == null) return;
      final d = Svc.location.distanceBetween(home.lat, home.lng, fix.lat, fix.lng);
      final b = Svc.location.bearingBetween(home.lat, home.lng, fix.lat, fix.lng);
      final inside = d <= home.radiusM;
      unawaited(tracking.publishStatus(lat: fix.lat, lng: fix.lng, inside: inside, distanceM: d, bearingDeg: b));
      final active = tracking.currentAlert;
      // Starts-outside case: no previous reading (_wasInside == null) and
      // already outside counts as a boundary crossing.
      if (!inside && _wasInside != false && active == null) {
        await tracking.raiseAlert(distanceM: d, bearingDeg: b, unusualReason: _unusualReason());
      } else if (inside && _wasInside == false && active != null) {
        await tracking.markFound(resolution: 'returned');
      }
      _wasInside = inside;
    } catch (_) {/* try again next tick */}
  }

  String? _unusualReason() {
    final n = now;
    final p = prayerToday;
    if (n.isBefore(p.fajr) || !n.isBefore(p.isha)) return 'Outside after dark';
    return null;
  }

  // ── Presenter / demo controls ─────────────────────────────────────────

  bool get hasDemoData => repo.members.any((m) => m.id == DemoIds.bilal);

  /// Fills the store with the BRIEF family (replaces local data).
  Future<void> loadDemoFamily({DemoView view = DemoView.elder}) async {
    applyDemoSeed(repo);
    repo.settings
      ..familyCode = kDemoFamilyCode
      ..onboarded = true;
    _applyView(view);
    await repo.save();
    _trackingStarted = false;
    await tracking.reset();
    notifyListeners();
    startBackground();
  }

  /// Presenter reset: clears the live alert, visit and clock preview and
  /// re-seeds the demo data if it was loaded.
  Future<void> resetDemo() async {
    AppClock.reset();
    await tracking.reset();
    care.alerts.removeWhere((a) => a.id.startsWith('demo-alert'));
    _notifiedAlerts.clear();
    _promptedToday.clear();
    if (hasDemoData) {
      applyDemoSeed(repo);
    }
    await repo.save();
    notifyListeners();
  }

  /// Wipe everything: empty install, role picker again.
  Future<void> resetAll() async {
    await _stopBackground();
    AppClock.reset();
    await repo.wipe();
    _notifiedAlerts.clear();
    _promptedToday.clear();
    notifyListeners();
  }

  /// Switches this phone to a role view for the one-phone demo. The caller
  /// (DemoControls) then navigates to that role's root route.
  Future<void> switchView(DemoView v) async {
    _applyView(v);
    await repo.save();
    notifyListeners();
    startBackground();
  }

  void _applyView(DemoView v) {
    final s = repo.settings;
    switch (v) {
      case DemoView.elder:
        s
          ..role = DeviceRole.elder
          ..isCaregiver = false
          ..contributorName = null
          ..contributorMemberId = null;
        break;
      case DemoView.bilal:
        s
          ..role = DeviceRole.family
          ..isCaregiver = true
          ..contributorName = 'Bilal'
          ..contributorMemberId = DemoIds.bilal;
        break;
      case DemoView.fatima:
        s
          ..role = DeviceRole.family
          ..isCaregiver = false
          ..contributorName = 'Fatima'
          ..contributorMemberId = DemoIds.fatima;
        break;
    }
  }

  /// Which demo view this phone is currently showing.
  DemoView get currentView {
    if (role == DeviceRole.elder) return DemoView.elder;
    return isCaregiver ? DemoView.bilal : DemoView.fatima;
  }

  /// Presenter: preview a time of day on the real date. Rebuilds listeners.
  void previewTime(int hour, int minute) {
    AppClock.previewTime(hour, minute);
    notifyListeners();
  }

  void clearTimePreview() {
    AppClock.reset();
    notifyListeners();
  }

  // ── Route helpers ─────────────────────────────────────────────────────

  /// The root route for the current role and time (used at boot and on
  /// view switches). Unset -> /splash.
  String get initialRoute {
    switch (role) {
      case DeviceRole.unset:
        return '/splash';
      case DeviceRole.elder:
        return elderRouteForTime(now);
      case DeviceRole.family:
        return isCaregiver ? '/care' : '/family';
    }
  }
}
