import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../demo/demo_controls.dart';
import '../../design/design.dart';
import '../../models/care.dart';
import '../../models/episode_log.dart';
import '../../models/family_member.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import '../../util/en_format.dart';
import '../../util/prayer.dart';
import 'widgets/family_a_common.dart';

/// Caregiver home (`/care`). English, board CaregiverHome.
class CaregiverHomeScreen extends StatelessWidget {
  const CaregiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final inset = MediaQuery.of(context).padding.top;
    const stripH = 72.0;
    final headerH = inset + 12 + 60 + 52;

    return FamilyTabScaffold(
      tab: FamilyTab.home,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: headerH + stripH - 40,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: headerH,
                    child: _Header(app: app, inset: inset),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: headerH - 40,
                    height: stripH,
                    child: _StatusStrip(app: app),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TodayCard(app: app),
                  const SizedBox(height: 24),
                  _Relatives(app: app),
                  const SizedBox(height: 24),
                  _CareTools(app: app),
                  const SizedBox(height: 20),
                  _FamilyCode(app: app),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String full) {
  final parts = full.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

// ── Header ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppState app;
  final double inset;
  const _Header({required this.app, required this.inset});

  @override
  Widget build(BuildContext context) {
    final pack = app.care.missingPack;
    final full = (pack['fullName'] ?? '').toString();
    final age = pack['age'];
    final line2 = [if (full.isNotEmpty) full, if (age != null) '$age'].join(' · ');
    final alert = app.activeAlert;
    return Container(
      color: YaadainTheme.primaryDark,
      child: Stack(
        children: [
          const Positioned.fill(child: JaaliPattern(opacity: 0.08)),
          Padding(
            padding: EdgeInsets.fromLTRB(16, inset + 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.35), width: 3),
                  ),
                  child: Avatar(
                    monogram: _initials(full.isNotEmpty ? full : app.elderNameEn),
                    size: 60,
                    tint: YaadainTheme.tintGold,
                    photoPath: app.elder.photoPath,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EnText(app.elderNameEn, size: 28, weight: FontWeight.w600, color: Colors.white, display: true, height: 1.15, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (line2.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: EnText(line2, size: 14, weight: FontWeight.w600, color: Colors.white.withOpacity(0.78), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ),
                ),
                if (kTrackingIsDemo)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: DemoChip(onLongPress: () => DemoControls.open(context)),
                  ),
                Semantics(
                  button: true,
                  label: alert != null ? 'Open alert' : 'Notifications',
                  child: InkWell(
                    borderRadius: YaadainTheme.radius12,
                    onTap: () {
                      if (alert != null) {
                        Navigator.pushNamed(context, Routes.careAlert);
                      } else {
                        ScaffoldMessenger.maybeOf(context)
                          ?..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(content: Text('No new alerts')));
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: YaadainTheme.radius12,
                        border: Border.all(color: Colors.white.withOpacity(0.22)),
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const YIcon(YI.bell, size: 22, color: Colors.white),
                          if (alert != null)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: YaadainTheme.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: YaadainTheme.primaryDark, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status strip ─────────────────────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  final AppState app;
  const _StatusStrip({required this.app});

  @override
  Widget build(BuildContext context) {
    final st = app.elderStatus;
    final now = app.now;
    String title;
    String sub;
    var warn = false;
    if (st == null) {
      title = 'Waiting for his phone';
      sub = 'No update yet · check that sharing is on';
    } else if (st.inside) {
      Episode? back;
      for (final e in app.episodes) {
        if (e.category != 'zone_return') continue;
        final d = e.at;
        if (d.year == now.year && d.month == now.month && d.day == now.day && !d.isAfter(now)) {
          if (back == null || d.isAfter(back.at)) back = e;
        }
      }
      title = back != null ? 'At home since ${EnFmt.time(back.at).toLowerCase()}' : 'At home';
      sub = _sub(st.battery, st.at, now);
    } else {
      warn = true;
      title = 'Outside the home zone';
      sub = '${EnFmt.distance(st.distanceM)} ${faCompass(st.bearingDeg)} · ${_sub(st.battery, st.at, now)}';
    }
    return Semantics(
      button: true,
      label: '$title. $sub',
      child: InkWell(
        borderRadius: YaadainTheme.radius20,
        onTap: () => Navigator.pushNamed(context, Routes.careWhere),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: YaadainTheme.surface,
            borderRadius: YaadainTheme.radius20,
            boxShadow: [BoxShadow(color: Color(0x1F2C2620), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              FaDot(
                color: st == null ? YaadainTheme.sepia : (warn ? YaadainTheme.accentDark : YaadainTheme.primary),
                halo: st == null ? YaadainTheme.line : (warn ? YaadainTheme.attentionSoft : YaadainTheme.primarySoft),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnText(title, size: 17, weight: FontWeight.w800, height: 1.25, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(children: [
                      if (st?.battery != null) ...[
                        const YIcon(YI.battery, size: 15, color: YaadainTheme.muted),
                        const SizedBox(width: 4),
                      ],
                      Flexible(child: EnText(sub, size: 13, weight: FontWeight.w600, color: YaadainTheme.muted, height: 1.3, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ),
              ),
              const YIcon(YI.chevronRight, size: 22, color: YaadainTheme.stroke),
            ],
          ),
        ),
      ),
    );
  }

  String _sub(int? battery, DateTime at, DateTime now) {
    final parts = <String>[
      if (battery != null) '$battery%',
      'updated ${EnFmt.relative(at, now)}',
      'sharing on',
    ];
    return parts.join(' · ');
  }
}

// ── Today ────────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final AppState app;
  const _TodayCard({required this.app});

  RoutineItem? _focusMedicine() {
    final now = app.now;
    final meds = app.routine.where((i) => i.enabled && i.kind == RoutineKind.medicine).toList()
      ..sort((a, b) => app.routineDueAt(a).compareTo(app.routineDueAt(b)));
    if (meds.isEmpty) return null;
    RoutineItem? pick;
    for (final m in meds) {
      if (!app.routineDueAt(m).isAfter(now.add(const Duration(minutes: 60)))) pick = m;
    }
    return pick ?? meds.first;
  }

  @override
  Widget build(BuildContext context) {
    final now = app.now;
    final med = _focusMedicine();
    final children = <Widget>[];

    // Medicine
    if (med == null) {
      children.add(FaRow(
        leading: const FaIconBox(YI.pill, bg: YaadainTheme.line, fg: YaadainTheme.muted),
        title: 'No medicine prompts yet',
        sub: 'Add them in Routine',
        chevron: true,
        onTap: () => Navigator.pushNamed(context, Routes.careRoutine),
      ));
    } else {
      final log = app.routineLogToday(med.id);
      final due = app.routineDueAt(med);
      final detail = med.detail.isEmpty ? '' : ' · ${med.detail}';
      Widget chip;
      String sub;
      if (log != null && log.status == 'taken') {
        sub = 'Taken ${faClock(log.at ?? due)}$detail';
        chip = const StatusChip('Done', tone: ChipTone.success);
      } else if (log != null) {
        sub = '${log.status[0].toUpperCase()}${log.status.substring(1)}$detail';
        chip = const StatusChip('Not taken', tone: ChipTone.attention);
      } else if (due.isAfter(now)) {
        sub = 'At ${EnFmt.time(due).toLowerCase()}$detail';
        chip = const StatusChip('Later');
      } else {
        sub = 'Due ${EnFmt.time(due).toLowerCase()}$detail';
        chip = const StatusChip('Not yet', tone: ChipTone.attention);
      }
      children.add(FaRow(
        leading: FaIconBox(log?.status == 'taken' ? YI.check : YI.pill),
        title: med.titleEn,
        sub: sub,
        trailing: chip,
        onTap: () => Navigator.pushNamed(context, Routes.careRoutine),
      ));
    }

    // Prayer
    final p = app.prayerToday.nextAfter(now);
    children.add(FaRow(
      leading: FaIconBox(p == Prayer.maghrib || p == Prayer.isha ? YI.sunset : YI.sunrise, bg: YaadainTheme.tintGold.bg, fg: YaadainTheme.tintGold.fg),
      title: p == null ? 'Prayers done for today' : '${p.en} ${faClock(app.prayerToday.at(p))}',
      sub: p == null ? 'Times are approximate' : 'Next prayer · times are approximate',
    ));

    // Duty
    children.add(_dutyRow(context));

    return FaCardList(
      padding: const EdgeInsets.only(top: 14),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(child: EnText('Today', size: 20, weight: FontWeight.w600, display: true)),
              EnText(faDate(now), size: 13, weight: FontWeight.w700, color: YaadainTheme.muted),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _dutyRow(BuildContext context) {
    final on = app.onShiftNow;
    void open() => Navigator.pushNamed(context, Routes.careCircle);
    if (on == null) {
      return FaRow(
        leading: const FaIconBox(YI.users, bg: YaadainTheme.line, fg: YaadainTheme.muted),
        title: 'Nobody on duty now',
        sub: 'Pick a shift in the Care circle',
        chevron: true,
        onTap: open,
      );
    }
    final me = app.settings.contributorMemberId;
    final m = app.memberById(on.memberId);
    final who = on.memberId == me ? 'you' : (m?.firstNameEn.isNotEmpty == true ? m!.firstNameEn : 'a relative');
    final end = on.shiftEndHour;
    CircleMember? next;
    if (end != null) {
      for (final c in app.circle) {
        if (c.shiftStartHour == end && c.memberId != on.memberId) next = c;
      }
    }
    String sub = 'Shift set in the Care circle';
    if (next != null) {
      final nm = app.memberById(next.memberId);
      final nextWho = next.memberId == me ? 'you' : (nm?.firstNameEn ?? 'a relative');
      final city = _city(nm);
      sub = 'Then $nextWho${city == null ? '' : ', from $city'}';
    }
    return FaRow(
      leading: FaIconBox(YI.users, bg: YaadainTheme.tintSage.bg, fg: YaadainTheme.tintSage.fg),
      title: end == null ? 'On duty: $who' : 'On duty: $who until ${faHour(end)}',
      sub: sub,
      chevron: true,
      onTap: open,
    );
  }
}

/// A voice he can hear: a greeting recording, or a voice message on his phone.
bool _hasVoice(AppState app, FamilyMember m) =>
    m.hasVoice || app.letters.any((l) => l.memberId == m.id);

String? _city(FamilyMember? m) {
  final note = m?.note ?? '';
  final r = RegExp(r'Lives in (.+)$', caseSensitive: false).firstMatch(note.trim());
  return r?.group(1)?.trim();
}

// ── Relatives ────────────────────────────────────────────────────────────

class _Relatives extends StatelessWidget {
  final AppState app;
  const _Relatives({required this.app});

  @override
  Widget build(BuildContext context) {
    final members = app.members;
    final withVoice = members.where((m) => _hasVoice(app, m)).length;
    String? addVoiceId;
    final me = app.settings.contributorMemberId;
    for (final m in members) {
      if (!m.isDeceased && m.id != me && !_hasVoice(app, m)) {
        addVoiceId = m.id;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FaSectionHeader(
          'Relatives',
          count: members.isEmpty ? null : '${members.length}',
          action: 'Add relative',
          actionIcon: YI.plus,
          onAction: () => Navigator.pushNamed(context, Routes.careAddRelative),
        ),
        const SizedBox(height: 6),
        if (members.isEmpty)
          YCard(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const FaIconBox(YI.users, size: 44),
                  const SizedBox(height: 12),
                  const EnText('No relatives yet', size: 16, weight: FontWeight.w800),
                  const SizedBox(height: 4),
                  EnText('Add the people ${app.elderNameEn} knows, with a photo and a voice.',
                      size: 13, weight: FontWeight.w600, color: YaadainTheme.muted, align: TextAlign.center),
                  const SizedBox(height: 14),
                  FamilyButton('Add a relative', icon: YI.plus, onTap: () => Navigator.pushNamed(context, Routes.careAddRelative)),
                ],
              ),
            ),
          )
        else ...[
          YCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: LayoutBuilder(builder: (context, c) {
              final rows = <Widget>[];
              for (var i = 0; i < members.length; i += 3) {
                final cells = <Widget>[];
                for (var j = i; j < i + 3; j++) {
                  cells.add(Expanded(
                    child: j < members.length
                        ? _Cell(
                            m: members[j],
                            isMe: me != null && members[j].id == me,
                            voice: _hasVoice(app, members[j]),
                            addVoice: members[j].id == addVoiceId,
                          )
                        : const SizedBox.shrink(),
                  ));
                }
                rows.add(Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells)));
              }
              return Column(mainAxisSize: MainAxisSize.min, children: rows);
            }),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: EnText('$withVoice of ${members.length} have a voice he can hear.', size: 13, weight: FontWeight.w600, color: YaadainTheme.muted),
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final FamilyMember m;
  final bool isMe;
  final bool addVoice;
  final bool voice;
  const _Cell({required this.m, required this.isMe, required this.addVoice, required this.voice});

  @override
  Widget build(BuildContext context) {
    final kin = m.kinshipEnglish;
    final city = _city(m);
    String sub;
    Color subColor = YaadainTheme.muted;
    var weight = FontWeight.w600;
    if (voice || m.isDeceased) {
      sub = isMe ? '$kin · you' : (city != null ? '$kin · $city' : kin);
      if (!voice && m.isDeceased) sub = kin;
    } else if (addVoice) {
      sub = 'Add voice';
      subColor = YaadainTheme.accentDark;
      weight = FontWeight.w800;
    } else {
      sub = 'No voice yet';
      subColor = YaadainTheme.sepia;
    }
    return Semantics(
      button: true,
      label: '${m.displayEn}, $sub',
      child: InkWell(
        borderRadius: YaadainTheme.radius12,
        onTap: () => Navigator.pushNamed(context, Routes.careAddRelative, arguments: AddRelativeArgs(memberId: m.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 62,
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(left: 7, top: 4, child: Avatar.member(m, size: 48)),
                    if (voice)
                      const Positioned(right: 0, bottom: 0, child: _Badge(color: YaadainTheme.primary, icon: YI.volume))
                    else if (addVoice)
                      const Positioned(right: 0, bottom: 0, child: _Badge(color: YaadainTheme.accentDark, icon: YI.mic)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              EnText(m.displayEn, size: 14, weight: FontWeight.w800, height: 1.2, align: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              EnText(sub, size: 12, weight: weight, color: subColor, height: 1.25, align: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final YI icon;
  const _Badge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      alignment: Alignment.center,
      child: YIcon(icon, size: 11, color: Colors.white, strokeWidth: 2.4),
    );
  }
}

// ── Care tools ───────────────────────────────────────────────────────────

class _CareTools extends StatelessWidget {
  final AppState app;
  const _CareTools({required this.app});

  @override
  Widget build(BuildContext context) {
    final now = app.now;
    final zones = app.zones.length;
    final recorded = kQuestions.where((q) => app.answerFor(q.id).isRecorded).length;
    final prompts = app.routine.where((r) => r.enabled).length;
    final next = app.nextRoutineItem();
    String nextTxt = 'none left today';
    if (next != null) {
      if (next.anchor != null && next.anchor!.isNotEmpty) {
        nextTxt = 'next after ${next.anchor![0].toUpperCase()}${next.anchor!.substring(1)}';
      } else {
        nextTxt = 'next at ${EnFmt.time(app.routineDueAt(next)).toLowerCase()}';
      }
    }
    final pack = app.care.missingPack;
    final packReady = (pack['fullName'] ?? '').toString().isNotEmpty;
    final consent = app.consent;
    final st = app.weeklyStats();
    final from = now.subtract(const Duration(days: 7));

    String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

    final rows = <(YI, String, String, VoidCallback)>[
      (
        YI.mapPin,
        'Safe zones',
        zones == 0 ? 'None yet · add Home first' : '${plural(zones, 'zone')} · Home is watched by his phone',
        () => Navigator.pushNamed(context, Routes.careZones)
      ),
      (
        YI.message,
        'Answers',
        '$recorded of ${kQuestions.length} recorded · on his phone',
        () => Navigator.pushNamed(context, Routes.careAnswers)
      ),
      (
        YI.pill,
        'Routine',
        prompts == 0 ? 'No prompts yet' : '${plural(prompts, 'prompt')} · $nextTxt',
        () => Navigator.pushNamed(context, Routes.careRoutine)
      ),
      (
        YI.audioLines,
        'Calm library',
        st.calmPlays == 0 ? 'Nothing played this week' : 'Played ${plural(st.calmPlays, 'time')} this week',
        () => ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Calm clips are managed on his phone for now')))
      ),
      (
        YI.shield,
        'If-found card and missing pack',
        packReady ? 'Ready · on his phone and yours' : 'Not filled in yet',
        () => Navigator.pushNamed(context, Routes.careFind)
      ),
      (
        YI.shieldCheck,
        'Consent',
        consent == null
            ? 'Not recorded yet'
            : 'Agreed ${consent.agreedAt.day} ${EnFmt.month(consent.agreedAt.month)} · review ${consent.askAgainAt.day} ${EnFmt.month(consent.askAgainAt.month)}',
        () => Navigator.pushNamed(context, Routes.consent)
      ),
      (
        YI.barChart,
        'Weekly report',
        '${faRange(from, now)} · ${plural(st.questions, 'question')}, ${plural(faUnplannedExits(app).length, 'zone exit')}',
        () => Navigator.pushNamed(context, Routes.careReport)
      ),
      (
        YI.smartphone,
        'Elder’s phone',
        'Urdu · PIN set${kTrackingIsDemo ? ' · demo controls' : ''}',
        () => DemoControls.open(context)
      ),
    ];

    const tints = [
      YaadainTheme.tintTeal,
      YaadainTheme.tintTeal,
      YaadainTheme.tintGold,
      YaadainTheme.tintSage,
      YaadainTheme.tintClay,
      YaadainTheme.tintTeal,
      YaadainTheme.tintGold,
      YaadainTheme.tintPlum,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FaSectionHeader('Care tools'),
        const SizedBox(height: 8),
        FaCardList(
          children: [
            for (var i = 0; i < rows.length; i++)
              FaRow(
                minHeight: 52,
                leading: FaIconBox(rows[i].$1, bg: tints[i].bg, fg: tints[i].fg),
                title: rows[i].$2,
                sub: rows[i].$3,
                chevron: true,
                onTap: rows[i].$4,
              ),
          ],
        ),
      ],
    );
  }
}

// ── Family code ──────────────────────────────────────────────────────────

class _FamilyCode extends StatelessWidget {
  final AppState app;
  const _FamilyCode({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: YaadainTheme.primarySoft,
        borderRadius: YaadainTheme.radius20,
        border: Border.all(color: const Color(0xFFC9DED5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EnText('Family code', size: 13, weight: FontWeight.w700, color: YaadainTheme.primaryDark),
                EnText(app.familyCodeDisplay, size: 22, weight: FontWeight.w600, color: YaadainTheme.primaryDark, display: true, letterSpacing: 2, maxLines: 1),
              ],
            ),
          ),
          FaSquareButton(icon: YI.copy, label: 'Copy family code', onTap: () => faCopyCode(context, app)),
          const SizedBox(width: 8),
          FaSquareButton(icon: YI.share, label: 'Share family code', onTap: () => faShareCode(context, app)),
        ],
      ),
    );
  }
}
