// Care data beyond the family tree: Poochhein answers, routine, consent,
// care circle, voice letters, safe zones and alert history.
// All plain JSON-friendly classes; persisted under key "care" in data.json.

DateTime? _dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;
List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
    ((v ?? []) as List)
        .whereType<Map>()
        .map((e) => f(Map<String, dynamic>.from(e)))
        .toList();

// ── Poochhein answers ───────────────────────────────────────────────────

/// The six fixed questions the elder can ask (Urdu text is what he sees).
class PoochheinQuestion {
  final String id; // day | where | bilal | food | medicine | ruqayya
  final String textUr;
  final String textEn; // for the caregiver editor (English)
  const PoochheinQuestion(this.id, this.textUr, this.textEn);
}

const List<PoochheinQuestion> kQuestions = [
  PoochheinQuestion('day', 'آج کون سا دن ہے؟', 'What day is it today?'),
  PoochheinQuestion('where', 'میں کہاں ہوں؟', 'Where am I?'),
  PoochheinQuestion('bilal', 'بلال کہاں ہے؟', 'Where is Bilal?'),
  PoochheinQuestion('food', 'کھانا کب ملے گا؟', 'When is the meal?'),
  PoochheinQuestion('medicine', 'دوا کب لینی ہے؟', 'When is my medicine?'),
  PoochheinQuestion('ruqayya', 'رقیہ کہاں ہیں؟', 'Where is Ruqayya?'),
];

PoochheinQuestion? questionById(String id) {
  for (final q in kQuestions) {
    if (q.id == id) return q;
  }
  return null;
}

/// One recorded/typed answer. [textUr] may contain `{day}` / `{part}`
/// placeholders for the "day" question (filled live by AppState.answerText).
class Answer {
  final String questionId;
  String textUr;
  String? audioPath;
  String byName; // English, e.g. "Bilal"
  DateTime? recordedAt;
  int durationSec;
  int askedCount; // times asked this week

  Answer({
    required this.questionId,
    this.textUr = '',
    this.audioPath,
    this.byName = '',
    this.recordedAt,
    this.durationSec = 0,
    this.askedCount = 0,
  });

  bool get hasText => textUr.trim().isNotEmpty;
  bool get isRecorded => recordedAt != null;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'textUr': textUr,
        'audioPath': audioPath,
        'byName': byName,
        'recordedAt': recordedAt?.toIso8601String(),
        'durationSec': durationSec,
        'askedCount': askedCount,
      };

  factory Answer.fromJson(Map<String, dynamic> j) => Answer(
        questionId: (j['questionId'] ?? '') as String,
        textUr: (j['textUr'] ?? '') as String,
        audioPath: j['audioPath'] as String?,
        byName: (j['byName'] ?? '') as String,
        recordedAt: _dt(j['recordedAt']),
        durationSec: ((j['durationSec'] ?? 0) as num).toInt(),
        askedCount: ((j['askedCount'] ?? 0) as num).toInt(),
      );
}

// ── Routine ─────────────────────────────────────────────────────────────

enum RoutineKind { medicine, meal, walk }

class RoutineItem {
  final String id;
  RoutineKind kind;
  String titleEn; // "Morning medicine"
  String titleUr; // "صبح کی دوا"
  String detail; // "Donepezil 10 mg" (English)
  int hour; // 24h fixed time (used when [anchor] is null)
  int minute;

  /// Optional prayer anchor: 'maghrib' etc. + [anchorOffsetMin] minutes.
  String? anchor;
  int anchorOffsetMin;
  bool enabled;

  RoutineItem({
    required this.id,
    required this.kind,
    required this.titleEn,
    required this.titleUr,
    this.detail = '',
    this.hour = 9,
    this.minute = 0,
    this.anchor,
    this.anchorOffsetMin = 0,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'titleEn': titleEn,
        'titleUr': titleUr,
        'detail': detail,
        'hour': hour,
        'minute': minute,
        'anchor': anchor,
        'anchorOffsetMin': anchorOffsetMin,
        'enabled': enabled,
      };

  factory RoutineItem.fromJson(Map<String, dynamic> j) => RoutineItem(
        id: (j['id'] ?? '') as String,
        kind: RoutineKind.values.firstWhere((k) => k.name == j['kind'],
            orElse: () => RoutineKind.medicine),
        titleEn: (j['titleEn'] ?? '') as String,
        titleUr: (j['titleUr'] ?? '') as String,
        detail: (j['detail'] ?? '') as String,
        hour: ((j['hour'] ?? 9) as num).toInt(),
        minute: ((j['minute'] ?? 0) as num).toInt(),
        anchor: j['anchor'] as String?,
        anchorOffsetMin: ((j['anchorOffsetMin'] ?? 0) as num).toInt(),
        enabled: (j['enabled'] ?? true) as bool,
      );
}

/// taken | skipped | missed
class RoutineLog {
  final String itemId;
  final String day; // yyyy-mm-dd
  String status;
  DateTime? at;
  String by; // English name or ''

  RoutineLog(
      {required this.itemId,
      required this.day,
      required this.status,
      this.at,
      this.by = ''});

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'day': day,
        'status': status,
        'at': at?.toIso8601String(),
        'by': by
      };

  factory RoutineLog.fromJson(Map<String, dynamic> j) => RoutineLog(
        itemId: (j['itemId'] ?? '') as String,
        day: (j['day'] ?? '') as String,
        status: (j['status'] ?? 'missed') as String,
        at: _dt(j['at']),
        by: (j['by'] ?? '') as String,
      );
}

class RoutineConfig {
  bool quietAfterIsha;
  bool nightPickupNudge; // 1-5 am
  bool promptsOn;
  RoutineConfig(
      {this.quietAfterIsha = true,
      this.nightPickupNudge = true,
      this.promptsOn = true});

  Map<String, dynamic> toJson() => {
        'quietAfterIsha': quietAfterIsha,
        'nightPickupNudge': nightPickupNudge,
        'promptsOn': promptsOn
      };

  factory RoutineConfig.fromJson(Map<String, dynamic> j) => RoutineConfig(
        quietAfterIsha: (j['quietAfterIsha'] ?? true) as bool,
        nightPickupNudge: (j['nightPickupNudge'] ?? true) as bool,
        promptsOn: (j['promptsOn'] ?? true) as bool,
      );
}

// ── Consent ─────────────────────────────────────────────────────────────

class ConsentRecord {
  DateTime agreedAt;
  List<String> presentNames; // English
  bool statusShared;
  bool zonesShared;
  bool lastPositionBilalOnly;
  int historyDays;
  DateTime askAgainAt;
  String hisResponseEn; // "That's fine"
  String hisResponseUr; // "ٹھیک ہے"

  ConsentRecord({
    required this.agreedAt,
    this.presentNames = const [],
    this.statusShared = true,
    this.zonesShared = true,
    this.lastPositionBilalOnly = true,
    this.historyDays = 7,
    required this.askAgainAt,
    this.hisResponseEn = "That's fine",
    this.hisResponseUr = 'ٹھیک ہے',
  });

  Map<String, dynamic> toJson() => {
        'agreedAt': agreedAt.toIso8601String(),
        'presentNames': presentNames,
        'statusShared': statusShared,
        'zonesShared': zonesShared,
        'lastPositionBilalOnly': lastPositionBilalOnly,
        'historyDays': historyDays,
        'askAgainAt': askAgainAt.toIso8601String(),
        'hisResponseEn': hisResponseEn,
        'hisResponseUr': hisResponseUr,
      };

  factory ConsentRecord.fromJson(Map<String, dynamic> j) => ConsentRecord(
        agreedAt: _dt(j['agreedAt']) ?? DateTime.now(),
        presentNames: ((j['presentNames'] ?? []) as List)
            .map((e) => e.toString())
            .toList(),
        statusShared: (j['statusShared'] ?? true) as bool,
        zonesShared: (j['zonesShared'] ?? true) as bool,
        lastPositionBilalOnly: (j['lastPositionBilalOnly'] ?? true) as bool,
        historyDays: ((j['historyDays'] ?? 7) as num).toInt(),
        askAgainAt: _dt(j['askAgainAt']) ??
            DateTime.now().add(const Duration(days: 90)),
        hisResponseEn: (j['hisResponseEn'] ?? "That's fine") as String,
        hisResponseUr: (j['hisResponseUr'] ?? 'ٹھیک ہے') as String,
      );
}

// ── Care circle ─────────────────────────────────────────────────────────

/// A person in the care circle (English-only surface).
class CircleMember {
  final String memberId; // FamilyMember.id
  String roleLabel; // "Primary caregiver", "Family"
  bool canSeeStatus;
  bool canSeeZones;
  bool canSeeLastPosition;
  bool isEverything; // caregiver: sees and edits all
  String? shiftLabel; // "First call", "First alert", "Night"
  int? shiftStartHour; // 24h
  int? shiftEndHour;
  int escalationOrder; // 0 = first; 99 = not in chain
  int escalateAfterMin;

  CircleMember({
    required this.memberId,
    this.roleLabel = 'Family',
    this.canSeeStatus = true,
    this.canSeeZones = false,
    this.canSeeLastPosition = false,
    this.isEverything = false,
    this.shiftLabel,
    this.shiftStartHour,
    this.shiftEndHour,
    this.escalationOrder = 99,
    this.escalateAfterMin = 0,
  });

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'roleLabel': roleLabel,
        'canSeeStatus': canSeeStatus,
        'canSeeZones': canSeeZones,
        'canSeeLastPosition': canSeeLastPosition,
        'isEverything': isEverything,
        'shiftLabel': shiftLabel,
        'shiftStartHour': shiftStartHour,
        'shiftEndHour': shiftEndHour,
        'escalationOrder': escalationOrder,
        'escalateAfterMin': escalateAfterMin,
      };

  factory CircleMember.fromJson(Map<String, dynamic> j) => CircleMember(
        memberId: (j['memberId'] ?? '') as String,
        roleLabel: (j['roleLabel'] ?? 'Family') as String,
        canSeeStatus: (j['canSeeStatus'] ?? true) as bool,
        canSeeZones: (j['canSeeZones'] ?? false) as bool,
        canSeeLastPosition: (j['canSeeLastPosition'] ?? false) as bool,
        isEverything: (j['isEverything'] ?? false) as bool,
        shiftLabel: j['shiftLabel'] as String?,
        shiftStartHour: (j['shiftStartHour'] as num?)?.toInt(),
        shiftEndHour: (j['shiftEndHour'] as num?)?.toInt(),
        escalationOrder: ((j['escalationOrder'] ?? 99) as num).toInt(),
        escalateAfterMin: ((j['escalateAfterMin'] ?? 0) as num).toInt(),
      );
}

class Handoff {
  String text;
  String byName;
  String shiftLabel; // "night shift"
  DateTime at;
  Handoff(
      {required this.text,
      required this.byName,
      this.shiftLabel = '',
      required this.at});

  Map<String, dynamic> toJson() => {
        'text': text,
        'byName': byName,
        'shiftLabel': shiftLabel,
        'at': at.toIso8601String()
      };

  factory Handoff.fromJson(Map<String, dynamic> j) => Handoff(
        text: (j['text'] ?? '') as String,
        byName: (j['byName'] ?? '') as String,
        shiftLabel: (j['shiftLabel'] ?? '') as String,
        at: _dt(j['at']) ?? DateTime.now(),
      );
}

// ── Voice letters ───────────────────────────────────────────────────────

class VoiceLetter {
  final String id;
  final String memberId; // sender
  DateTime at;
  int durationSec;
  String? audioPath;
  bool seen; // false -> shown as new on the elder phone
  int playCount;

  VoiceLetter({
    required this.id,
    required this.memberId,
    required this.at,
    this.durationSec = 0,
    this.audioPath,
    this.seen = false,
    this.playCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'at': at.toIso8601String(),
        'durationSec': durationSec,
        'audioPath': audioPath,
        'seen': seen,
        'playCount': playCount,
      };

  factory VoiceLetter.fromJson(Map<String, dynamic> j) => VoiceLetter(
        id: (j['id'] ?? '') as String,
        memberId: (j['memberId'] ?? '') as String,
        at: _dt(j['at']) ?? DateTime.now(),
        durationSec: ((j['durationSec'] ?? 0) as num).toInt(),
        audioPath: j['audioPath'] as String?,
        seen: (j['seen'] ?? false) as bool,
        playCount: ((j['playCount'] ?? 0) as num).toInt(),
      );
}

// ── Safe zones + alerts ─────────────────────────────────────────────────

class SafeZone {
  final String id;
  String name; // English ("Home")
  String nameUr; // Urdu, for the elder screens
  double lat;
  double lng;
  double radiusM;
  String ruleEn; // "Always", "Around prayer times and Friday 12-2", "Sundays"
  bool enabled;

  SafeZone({
    required this.id,
    required this.name,
    this.nameUr = '',
    required this.lat,
    required this.lng,
    this.radiusM = 150,
    this.ruleEn = 'Always',
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameUr': nameUr,
        'lat': lat,
        'lng': lng,
        'radiusM': radiusM,
        'ruleEn': ruleEn,
        'enabled': enabled,
      };

  factory SafeZone.fromJson(Map<String, dynamic> j) => SafeZone(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        nameUr: (j['nameUr'] ?? '') as String,
        lat: ((j['lat'] ?? 0) as num).toDouble(),
        lng: ((j['lng'] ?? 0) as num).toDouble(),
        radiusM: ((j['radiusM'] ?? 150) as num).toDouble(),
        ruleEn: (j['ruleEn'] ?? 'Always') as String,
        enabled: (j['enabled'] ?? true) as bool,
      );
}

/// One raised alert, kept in history.
class AlertRecord {
  final String id;
  DateTime at;
  String kind; // zone_exit | help
  double distanceM;
  double bearingDeg;
  String? ackBy;
  DateTime? ackAt;
  int? etaMin;
  DateTime? resolvedAt;
  String resolution; // '' | found | returned

  AlertRecord({
    required this.id,
    required this.at,
    this.kind = 'zone_exit',
    this.distanceM = 0,
    this.bearingDeg = 0,
    this.ackBy,
    this.ackAt,
    this.etaMin,
    this.resolvedAt,
    this.resolution = '',
  });

  bool get isActive => resolvedAt == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'kind': kind,
        'distanceM': distanceM,
        'bearingDeg': bearingDeg,
        'ackBy': ackBy,
        'ackAt': ackAt?.toIso8601String(),
        'etaMin': etaMin,
        'resolvedAt': resolvedAt?.toIso8601String(),
        'resolution': resolution,
      };

  factory AlertRecord.fromJson(Map<String, dynamic> j) => AlertRecord(
        id: (j['id'] ?? '') as String,
        at: _dt(j['at']) ?? DateTime.now(),
        kind: (j['kind'] ?? 'zone_exit') as String,
        distanceM: ((j['distanceM'] ?? 0) as num).toDouble(),
        bearingDeg: ((j['bearingDeg'] ?? 0) as num).toDouble(),
        ackBy: j['ackBy'] as String?,
        ackAt: _dt(j['ackAt']),
        etaMin: (j['etaMin'] as num?)?.toInt(),
        resolvedAt: _dt(j['resolvedAt']),
        resolution: (j['resolution'] ?? '') as String,
      );
}

// ── Container ───────────────────────────────────────────────────────────

class CareData {
  List<Answer> answers;
  List<RoutineItem> routine;
  List<RoutineLog> routineLogs;
  RoutineConfig routineConfig;
  ConsentRecord? consent;
  List<CircleMember> circle;
  Handoff? handoff;
  List<VoiceLetter> letters;
  List<SafeZone> zones;
  bool nightRule; // alert on any exit after Isha
  List<AlertRecord> alerts;

  /// "Missing pack" details for IfFound (English facts; Urdu produced by
  /// screens). Keys: height, build, beard, glasses, clothes, places (list).
  Map<String, dynamic> missingPack;

  CareData({
    List<Answer>? answers,
    List<RoutineItem>? routine,
    List<RoutineLog>? routineLogs,
    RoutineConfig? routineConfig,
    this.consent,
    List<CircleMember>? circle,
    this.handoff,
    List<VoiceLetter>? letters,
    List<SafeZone>? zones,
    this.nightRule = true,
    List<AlertRecord>? alerts,
    Map<String, dynamic>? missingPack,
  })  : answers = answers ?? [],
        routine = routine ?? [],
        routineLogs = routineLogs ?? [],
        routineConfig = routineConfig ?? RoutineConfig(),
        circle = circle ?? [],
        letters = letters ?? [],
        zones = zones ?? [],
        alerts = alerts ?? [],
        missingPack = missingPack ?? {};

  Map<String, dynamic> toJson() => {
        'answers': answers.map((e) => e.toJson()).toList(),
        'routine': routine.map((e) => e.toJson()).toList(),
        'routineLogs': routineLogs.map((e) => e.toJson()).toList(),
        'routineConfig': routineConfig.toJson(),
        'consent': consent?.toJson(),
        'circle': circle.map((e) => e.toJson()).toList(),
        'handoff': handoff?.toJson(),
        'letters': letters.map((e) => e.toJson()).toList(),
        'zones': zones.map((e) => e.toJson()).toList(),
        'nightRule': nightRule,
        'alerts': alerts.map((e) => e.toJson()).toList(),
        'missingPack': missingPack,
      };

  factory CareData.fromJson(Map<String, dynamic> j) => CareData(
        answers: _list(j['answers'], Answer.fromJson),
        routine: _list(j['routine'], RoutineItem.fromJson),
        routineLogs: _list(j['routineLogs'], RoutineLog.fromJson),
        routineConfig: j['routineConfig'] is Map
            ? RoutineConfig.fromJson(
                Map<String, dynamic>.from(j['routineConfig'] as Map))
            : RoutineConfig(),
        consent: j['consent'] is Map
            ? ConsentRecord.fromJson(
                Map<String, dynamic>.from(j['consent'] as Map))
            : null,
        circle: _list(j['circle'], CircleMember.fromJson),
        handoff: j['handoff'] is Map
            ? Handoff.fromJson(Map<String, dynamic>.from(j['handoff'] as Map))
            : null,
        letters: _list(j['letters'], VoiceLetter.fromJson),
        zones: _list(j['zones'], SafeZone.fromJson),
        nightRule: (j['nightRule'] ?? true) as bool,
        alerts: _list(j['alerts'], AlertRecord.fromJson),
        missingPack: j['missingPack'] is Map
            ? Map<String, dynamic>.from(j['missingPack'] as Map)
            : {},
      );
}
