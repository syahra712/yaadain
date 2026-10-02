import '../models/care.dart';
import '../models/episode_log.dart';
import '../models/family_member.dart';
import '../util/app_clock.dart';
import 'repository.dart';

/// Demo-family ids (stable, so tests and screens can reference them).
class DemoIds {
  DemoIds._();
  static const ruqayya = 'ruqayya';
  static const bilal = 'bilal';
  static const fatima = 'fatima';
  static const ayesha = 'ayesha';
  static const zaid = 'zaid';
  static const maryam = 'maryam';
  static const hassan = 'hassan';
  static const aslam = 'aslam';
  static const naseem = 'naseem';

  static const zoneHome = 'zone-home';
  static const zoneMasjid = 'zone-masjid';
  static const zoneAslam = 'zone-aslam';

  static const medMorning = 'med-morning';
  static const mealLunch = 'meal-lunch';
  static const medEvening = 'med-evening';
  static const walk = 'walk-evening';
}

/// Home of the demo family (House 12, Block 7, Gulshan-e-Iqbal, Karachi).
const double kDemoHomeLat = 24.9215;
const double kDemoHomeLng = 67.0916;
const String kDemoFamilyCode = '7F3K'; // shown as YD-7F3K

/// The BRIEF family, in both scripts. No photos, no audio: every screen must
/// render from this alone.
List<FamilyMember> demoMembers() => [
      FamilyMember(
        id: DemoIds.ruqayya,
        nameUr: 'رقیہ',
        nameEn: 'Ruqayya',
        relationshipId: 'biwi',
        isDeceased: true,
        callsThemUr: 'رقیہ',
        callsThemEn: 'Ruqayya',
        callsHimUr: 'اکرم',
        callsHimEn: 'Akram',
        tint: 'gold',
      ),
      FamilyMember(
        id: DemoIds.bilal,
        nameUr: 'بلال',
        nameEn: 'Bilal',
        relationshipId: 'beta',
        callsThemUr: 'بلال بیٹا',
        callsThemEn: 'Bilal beta',
        callsHimUr: 'ابو',
        callsHimEn: 'Abu',
        phone: '0300 1234567',
        isPrimaryContact: true,
        tint: 'teal',
      ),
      FamilyMember(
        id: DemoIds.fatima,
        nameUr: 'فاطمہ',
        nameEn: 'Fatima',
        relationshipId: 'beti',
        callsThemUr: 'فاطمہ بیٹی',
        callsThemEn: 'Fatima beti',
        callsHimUr: 'ابو',
        callsHimEn: 'Abu',
        phone: '0321 5550142',
        note: 'Lives in Lahore',
        tint: 'clay',
      ),
      FamilyMember(
        id: DemoIds.ayesha,
        nameUr: 'عائشہ',
        nameEn: 'Ayesha',
        relationshipId: 'bahu',
        callsThemUr: 'عائشہ بیٹی',
        callsThemEn: 'Ayesha beti',
        callsHimUr: 'ابو جی',
        callsHimEn: 'Abu ji',
        phone: '0333 5550177',
        tint: 'sage',
      ),
      FamilyMember(
        id: DemoIds.zaid,
        nameUr: 'زید',
        nameEn: 'Zaid',
        relationshipId: 'pota',
        callsThemUr: 'زید',
        callsThemEn: 'Zaid',
        callsHimUr: 'دادا جان',
        callsHimEn: 'Dada Jaan',
        tint: 'plum',
      ),
      FamilyMember(
        id: DemoIds.maryam,
        nameUr: 'مریم',
        nameEn: 'Maryam',
        relationshipId: 'poti',
        callsThemUr: 'مریم',
        callsThemEn: 'Maryam',
        callsHimUr: 'دادا جان',
        callsHimEn: 'Dada Jaan',
        tint: 'teal',
      ),
      FamilyMember(
        id: DemoIds.hassan,
        nameUr: 'حسن',
        nameEn: 'Hassan',
        relationshipId: 'nawasa',
        callsThemUr: 'حسن',
        callsThemEn: 'Hassan',
        callsHimUr: 'نانا جان',
        callsHimEn: 'Nana Jaan',
        tint: 'gold',
      ),
      FamilyMember(
        id: DemoIds.aslam,
        nameUr: 'اسلم',
        nameEn: 'Aslam',
        relationshipId: 'bhai',
        callsThemUr: 'اسلم',
        callsThemEn: 'Aslam',
        callsHimUr: 'بھائی جان',
        callsHimEn: 'Bhai jaan',
        phone: '0300 5550163',
        tint: 'sage',
      ),
      FamilyMember(
        id: DemoIds.naseem,
        nameUr: 'نسیم',
        nameEn: 'Naseem',
        relationshipId: 'behn',
        callsThemUr: 'نسیم',
        callsThemEn: 'Naseem',
        callsHimUr: 'بھائی جان',
        callsHimEn: 'Bhai jaan',
        phone: '0345 5550118',
        tint: 'plum',
      ),
    ];

/// Fills [repo] with the full demo state (family, elder, care data, a week of
/// episodes). Everything is placed relative to [now] (default: AppClock) so
/// "today", "yesterday" and "Thursday" are always real. The caller decides
/// whether to persist.
void applyDemoSeed(Repository repo, {DateTime? now}) {
  final n = now ?? AppClock.now();
  DateTime at(int dayOffset, int h, int m) {
    final d = DateTime(n.year, n.month, n.day).add(Duration(days: dayOffset));
    return DateTime(d.year, d.month, d.day, h, m);
  }

  repo.members = demoMembers();

  repo.elder
    ..name = 'دادا جان'
    ..romanName = 'Dada Jaan'
    ..homeLat = kDemoHomeLat
    ..homeLng = kDemoHomeLng
    ..safeRadiusMeters = 150
    ..homeAddress = 'House 12, Block 7, Gulshan-e-Iqbal, Karachi';

  // Familiar caregiver identity for the demo family.
  repo.settings
    ..familyCode = repo.settings.familyCode ?? kDemoFamilyCode
    ..hijriOffsetDays = 1;

  // ── Poochhein answers ───────────────────────────────────────────────
  repo.care = CareData(
    answers: [
      Answer(
        questionId: 'day',
        textUr: 'آج {day} ہے، اور ابھی {part} کا وقت ہے۔ سب خیریت ہے۔',
        byName: 'Bilal',
        recordedAt: at(-1, 21, 5),
        durationSec: 6,
        askedCount: 3,
      ),
      Answer(
        questionId: 'where',
        textUr: 'آپ اپنے گھر میں ہیں، گلشنِ اقبال، کراچی میں۔ یہ آپ کا اپنا گھر ہے۔',
        byName: 'Bilal',
        recordedAt: at(-1, 21, 8),
        durationSec: 8,
        askedCount: 3,
      ),
      Answer(
        questionId: 'bilal',
        textUr: 'بلال بیٹا کام پر گیا ہے، شام کو گھر آ جائے گا۔',
        byName: 'Bilal',
        recordedAt: at(-1, 21, 12),
        durationSec: 7,
        askedCount: 5,
      ),
      Answer(
        questionId: 'food',
        textUr: 'کھانا ایک بجے ملے گا۔ عائشہ بیٹی بنا رہی ہے۔',
        byName: 'Ayesha',
        recordedAt: at(-2, 12, 20),
        durationSec: 5,
        askedCount: 2,
      ),
      Answer(
        questionId: 'medicine',
        textUr: 'صبح کی دوا آپ نے لے لی ہے۔ اگلی دوا مغرب کے بعد ہے۔',
        askedCount: 2,
      ),
      Answer(questionId: 'ruqayya', askedCount: 4),
    ],
    routine: [
      RoutineItem(
        id: DemoIds.medMorning,
        kind: RoutineKind.medicine,
        titleEn: 'Morning medicine',
        titleUr: 'صبح کی دوا',
        detail: 'Donepezil 10 mg',
        hour: 9,
        minute: 0,
      ),
      RoutineItem(
        id: DemoIds.mealLunch,
        kind: RoutineKind.meal,
        titleEn: 'Lunch',
        titleUr: 'دوپہر کا کھانا',
        hour: 13,
        minute: 0,
      ),
      RoutineItem(
        id: DemoIds.medEvening,
        kind: RoutineKind.medicine,
        titleEn: 'Evening medicine',
        titleUr: 'شام کی دوا',
        detail: 'After Maghrib',
        hour: 18,
        minute: 45,
        anchor: 'maghrib',
        anchorOffsetMin: 15,
      ),
      RoutineItem(
        id: DemoIds.walk,
        kind: RoutineKind.walk,
        titleEn: 'Evening walk',
        titleUr: 'شام کی سیر',
        hour: 17,
        minute: 0,
      ),
    ],
    routineLogs: _routineLogs(n, at),
    routineConfig: RoutineConfig(),
    consent: ConsentRecord(
      agreedAt: DateTime(2026, 10, 2, 9, 52),
      presentNames: const ['Bilal', 'Ayesha'],
      askAgainAt: DateTime(2027, 1, 2),
    ),
    circle: [
      CircleMember(
        memberId: DemoIds.bilal,
        roleLabel: 'Primary caregiver',
        isEverything: true,
        canSeeStatus: true,
        canSeeZones: true,
        canSeeLastPosition: true,
        shiftLabel: 'First call',
        shiftStartHour: 6,
        shiftEndHour: 18,
        escalationOrder: 0,
        escalateAfterMin: 0,
      ),
      CircleMember(
        memberId: DemoIds.ayesha,
        roleLabel: 'Family',
        canSeeStatus: true,
        canSeeZones: true,
        canSeeLastPosition: true,
        shiftLabel: 'Night',
        shiftStartHour: 23,
        shiftEndHour: 6,
        escalationOrder: 1,
        escalateAfterMin: 8,
      ),
      CircleMember(
        memberId: DemoIds.fatima,
        roleLabel: 'Family',
        canSeeStatus: true,
        canSeeZones: true,
        shiftLabel: 'First alert',
        shiftStartHour: 18,
        shiftEndHour: 23,
        escalationOrder: 2,
        escalateAfterMin: 16,
      ),
      CircleMember(memberId: DemoIds.aslam, roleLabel: 'Family', canSeeStatus: true),
      CircleMember(memberId: DemoIds.naseem, roleLabel: 'Family', canSeeStatus: true),
    ],
    handoff: Handoff(
      text: "Abu didn't sleep well. Skip the afternoon walk.",
      byName: 'Ayesha',
      shiftLabel: 'night shift',
      at: at(0, 7, 30).isAfter(n) ? at(-1, 7, 30) : at(0, 7, 30),
    ),
    letters: [
      VoiceLetter(
        id: 'letter-fatima',
        memberId: DemoIds.fatima,
        at: at(0, 8, 5).isAfter(n) ? at(-1, 20, 5) : at(0, 8, 5),
        durationSec: 20,
        seen: false,
      ),
      VoiceLetter(id: 'letter-zaid', memberId: DemoIds.zaid, at: at(-1, 17, 20), durationSec: 9, seen: true, playCount: 2),
      VoiceLetter(id: 'letter-aslam', memberId: DemoIds.aslam, at: at(-4, 19, 40), durationSec: 12, seen: true, playCount: 3),
      VoiceLetter(id: 'letter-hassan', memberId: DemoIds.hassan, at: at(-9, 18, 10), durationSec: 15, seen: true, playCount: 1),
    ],
    zones: [
      SafeZone(
        id: DemoIds.zoneHome,
        name: 'Home',
        nameUr: 'گھر',
        lat: kDemoHomeLat,
        lng: kDemoHomeLng,
        radiusM: 150,
        ruleEn: 'Always',
      ),
      SafeZone(
        id: DemoIds.zoneMasjid,
        name: 'Masjid Noor',
        nameUr: 'مسجد نور',
        // North-west of home, clear of the scripted north-east walk.
        lat: 24.9236,
        lng: 67.0892,
        radiusM: 100,
        ruleEn: 'Around prayer times and Friday 12 to 2',
      ),
      SafeZone(
        id: DemoIds.zoneAslam,
        name: "Aslam's house",
        nameUr: 'اسلم کا گھر',
        lat: 24.9050,
        lng: 67.0822,
        radiusM: 150,
        ruleEn: 'Sundays',
      ),
    ],
    nightRule: true,
    alerts: [
      AlertRecord(
        id: 'alert-thu',
        at: at(-2, 16, 50),
        kind: 'zone_exit',
        distanceM: 210,
        bearingDeg: 40,
        ackBy: 'Bilal',
        ackAt: at(-2, 16, 53),
        etaMin: 6,
        resolvedAt: at(-2, 17, 20),
        resolution: 'returned',
      ),
    ],
    missingPack: {
      'fullName': 'Muhammad Akram',
      'age': 78,
      'height': '5 ft 7',
      'build': 'Slim',
      'beard': 'Grey beard',
      'glasses': 'Glasses',
      'clothes': 'White shalwar kameez and brown waistcoat',
      'places': ['Masjid Noor', 'Old office, Shahrah-e-Faisal', "Ruqayya's family home, Nazimabad"],
      'phone': '0300 1234567',
    },
  );

  repo.episodes = _episodes(n, at);
}

List<RoutineLog> _routineLogs(DateTime n, DateTime Function(int, int, int) at) {
  final logs = <RoutineLog>[];
  String day(int off) => RoutineLog.dayKey(at(off, 0, 0));
  // Last 7 completed days: 21 doses/meals, 19 taken, 2 missed.
  const missed = {(-3, DemoIds.medEvening), (-5, DemoIds.mealLunch)};
  for (var off = -7; off <= -1; off++) {
    for (final entry in const [
      (DemoIds.medMorning, 9, 4),
      (DemoIds.mealLunch, 13, 10),
      (DemoIds.medEvening, 18, 50),
    ]) {
      final isMissed = missed.contains((off, entry.$1));
      logs.add(RoutineLog(
        itemId: entry.$1,
        day: day(off),
        status: isMissed ? 'missed' : 'taken',
        at: isMissed ? null : at(off, entry.$2, entry.$3),
        by: isMissed ? '' : (entry.$1 == DemoIds.mealLunch ? 'Ayesha' : 'Bilal'),
      ));
    }
    // Evening walk: skipped Thu and Fri.
    final d = at(off, 0, 0);
    final skipped = d.weekday == DateTime.thursday || d.weekday == DateTime.friday;
    logs.add(RoutineLog(
      itemId: DemoIds.walk,
      day: day(off),
      status: skipped ? 'skipped' : 'taken',
      at: skipped ? null : at(off, 17, 5),
      by: skipped ? '' : 'Bilal',
    ));
  }
  // Today: morning medicine already taken at 9:04 by Bilal (if it is past 9:04).
  if (n.isAfter(at(0, 9, 4))) {
    logs.add(RoutineLog(
      itemId: DemoIds.medMorning,
      day: day(0),
      status: 'taken',
      at: at(0, 9, 4),
      by: 'Bilal',
    ));
  }
  return logs;
}

List<Episode> _episodes(DateTime n, DateTime Function(int, int, int) at) {
  final out = <Episode>[];
  void q(int off, int h, int m, String id) =>
      out.add(Episode(category: 'question', severity: id == 'ruqayya' ? 2 : 1, at: at(off, h, m), question: id));

  // 19 questions: 11 after Asr (4 of them the Ruqayya ones after Maghrib).
  // Before Asr (8)
  q(-6, 10, 20, 'day');
  q(-5, 11, 5, 'bilal');
  q(-4, 9, 40, 'day');
  q(-3, 12, 15, 'food');
  q(-3, 14, 30, 'medicine');
  q(-2, 11, 10, 'where');
  q(-1, 10, 45, 'bilal');
  q(-1, 14, 20, 'medicine');
  // After Asr, before Maghrib (7)
  q(-6, 17, 10, 'bilal');
  q(-5, 16, 55, 'where');
  q(-4, 17, 35, 'bilal');
  q(-3, 17, 5, 'day');
  q(-2, 17, 40, 'where');
  q(-1, 16, 50, 'food');
  q(-1, 17, 25, 'bilal');
  // After Maghrib: Ruqayya x4
  q(-5, 18, 55, 'ruqayya');
  q(-3, 19, 10, 'ruqayya');
  q(-2, 18, 50, 'ruqayya');
  q(-1, 19, 20, 'ruqayya');

  // Calm plays (7).
  for (final c in const [(-6, 18, 30), (-5, 19, 5), (-4, 17, 50), (-3, 18, 45), (-2, 19, 0), (-1, 18, 40), (-1, 14, 10)]) {
    out.add(Episode(category: 'calm', severity: 1, at: at(c.$1, c.$2, c.$3), note: c.$1 == -1 && c.$2 == 18 ? '18 min' : null));
  }

  // Zone exits: today's Fajr visit to Masjid Noor, Thursday 4:50 pm.
  out.add(Episode(category: 'zone_exit', at: at(0, 5, 2), note: 'Masjid Noor'));
  out.add(Episode(category: 'zone_return', at: at(0, 7, 10)));
  out.add(Episode(category: 'zone_exit', severity: 2, at: at(-2, 16, 50)));
  out.add(Episode(category: 'zone_return', at: at(-2, 17, 20)));

  // Night pickups: Tue 2:10, Thu 1:40 (relative to the real week).
  DateTime? lastWeekday(int weekday, int h, int m) {
    for (var off = 0; off >= -6; off--) {
      final d = at(off, h, m);
      if (d.weekday == weekday && !d.isAfter(n)) return d;
    }
    return null;
  }

  final tue = lastWeekday(DateTime.tuesday, 2, 10);
  final thu = lastWeekday(DateTime.thursday, 1, 40);
  if (tue != null) out.add(Episode(category: 'night_pickup', severity: 2, at: tue));
  if (thu != null) out.add(Episode(category: 'night_pickup', severity: 2, at: thu));

  // 14 voices played, Fatima most.
  const plays = [
    DemoIds.fatima, DemoIds.fatima, DemoIds.fatima, DemoIds.fatima, DemoIds.fatima, DemoIds.fatima,
    DemoIds.zaid, DemoIds.zaid, DemoIds.zaid,
    DemoIds.aslam, DemoIds.aslam,
    DemoIds.hassan, DemoIds.maryam, DemoIds.ayesha,
  ];
  for (var i = 0; i < plays.length; i++) {
    out.add(Episode(category: 'voice_played', at: at(-(1 + i % 6), 15 + (i % 4), 10 + i), note: plays[i]));
  }

  out.removeWhere((e) => e.at.isAfter(n));
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}
