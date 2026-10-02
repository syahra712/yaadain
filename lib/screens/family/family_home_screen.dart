import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../demo/demo_controls.dart';
import '../../design/design.dart';
import '../../models/care.dart';
import '../../models/episode_log.dart';
import '../../models/family_member.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import '../../tracking/tracking_source.dart';
import '../../util/en_format.dart';
import 'widgets/family_a_common.dart';

/// Family member home (`/family`). English, board FamilyHome.
class FamilyHomeScreen extends StatelessWidget {
  const FamilyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final inset = MediaQuery.of(context).padding.top;
    final alert = app.activeAlert;

    return FamilyTabScaffold(
      tab: FamilyTab.home,
      showAlertBanner: alert == null,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, inset + 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Top(app: app),
            const SizedBox(height: 16),
            if (alert != null) ...[
              _AlertCard(app: app, alert: alert),
              const SizedBox(height: 12),
            ],
            _Glance(app: app),
            const SizedBox(height: 16),
            _RecordButton(app: app),
            const SizedBox(height: 22),
            _Hellos(app: app),
            const SizedBox(height: 12),
            _MemoryCard(),
            const SizedBox(height: 22),
            _TodayWithHim(app: app),
            const SizedBox(height: 22),
            _OnDuty(app: app),
            const SizedBox(height: 16),
            _CodeCard(app: app),
          ],
        ),
      ),
    );
  }
}

FamilyMember? _me(AppState app) {
  final id = app.settings.contributorMemberId;
  return id == null ? null : app.memberById(id);
}

// ── Top row ──────────────────────────────────────────────────────────────

class _Top extends StatelessWidget {
  final AppState app;
  const _Top({required this.app});

  @override
  Widget build(BuildContext context) {
    final me = _me(app);
    final name = me?.firstNameEn.isNotEmpty == true ? me!.firstNameEn : app.myNameEn;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: YaadainTheme.primaryDark, borderRadius: YaadainTheme.radius12),
          alignment: Alignment.center,
          child: const LogoMark(size: 22),
        ),
        const SizedBox(width: 10),
        const EnText('Yaadain', size: 22, weight: FontWeight.w600, display: true),
        const Spacer(),
        if (kTrackingIsDemo) ...[
          DemoChip(onLongPress: () => DemoControls.open(context)),
          const SizedBox(width: 10),
        ],
        Flexible(child: EnText(name, size: 13, weight: FontWeight.w700, color: YaadainTheme.bodyDim, maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 10),
        if (me != null)
          Avatar.member(me, size: 36)
        else
          Avatar(monogram: name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(), size: 36, tint: YaadainTheme.tintClay),
      ],
    );
  }
}

// ── Alert ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final AppState app;
  final ActiveAlert alert;
  const _AlertCard({required this.app, required this.alert});

  @override
  Widget build(BuildContext context) {
    final elder = app.elderNameEn;
    final when = EnFmt.time(alert.raisedAt).toLowerCase();
    final help = alert.kind == 'help';
    final title = help ? '$elder pressed Help · $when' : '$elder left home · $when';
    final place = '${EnFmt.distance(alert.distanceM)} ${faCompass(alert.bearingDeg)} of home';
    final phoneTxt = alert.battery != null ? ', phone ${alert.battery}%' : '';
    final ackBy = alert.ackBy ?? '';
    final mine = ackBy.isNotEmpty && ackBy == app.myNameEn;
    final sub = alert.isAcknowledged
        ? '${mine ? 'You are' : '$ackBy is'} on the way. $place$phoneTxt.'
        : '$place$phoneTxt. Nobody has taken it yet.';

    final caregiver = app.primaryContact;
    final cgName = caregiver?.firstNameEn ?? 'the caregiver';
    String side;
    if (alert.isAcknowledged) {
      side = 'You can still call him or open the alert for the map.';
    } else {
      final sorted = [...app.circle]..sort((a, b) => a.escalationOrder.compareTo(b.escalationOrder));
      final first = sorted.isEmpty ? null : sorted.first;
      final mins = first?.escalateAfterMin ?? 0;
      side = 'Tells $cgName you have taken it.'
          '${mins > 0 ? ' Escalates to the next person at ${EnFmt.time(alert.raisedAt.add(Duration(minutes: mins))).replaceAll(RegExp(r' [AP]M$'), '')} if nobody does.' : ''}';
    }

    return Semantics(
      container: true,
      label: '$title. $sub',
      child: InkWell(
        borderRadius: YaadainTheme.radius20,
        onTap: () => Navigator.pushNamed(context, Routes.careAlert),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: YaadainTheme.attentionSoft,
            borderRadius: YaadainTheme.radius20,
            border: Border.all(color: const Color(0xFFE8CDB7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3, right: 14),
                    child: YIcon(YI.alertTriangle, size: 24, color: YaadainTheme.accentDark),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EnText(title, size: 20, weight: FontWeight.w600, display: true, height: 1.2),
                        const SizedBox(height: 4),
                        EnText(sub, size: 15, weight: FontWeight.w600, color: YaadainTheme.bodyDim, height: 1.35),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!mine)
                    FamilyButton.care(
                      "I'll call him",
                      icon: YI.phone,
                      expand: false,
                      onTap: () async {
                        await app.acknowledgeAlert();
                        final phone = caregiver?.phone ?? app.care.missingPack['phone']?.toString() ?? '';
                        if (phone.isNotEmpty) await Svc.launcher.call(phone);
                      },
                    )
                  else
                    FamilyButton.quiet('Open alert', expand: false, onTap: () => Navigator.pushNamed(context, Routes.careAlert)),
                  const SizedBox(width: 14),
                  Expanded(child: EnText(side, size: 12, weight: FontWeight.w600, color: YaadainTheme.bodyDim, height: 1.35)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glance ───────────────────────────────────────────────────────────────

class _Glance extends StatelessWidget {
  final AppState app;
  const _Glance({required this.app});

  @override
  Widget build(BuildContext context) {
    final st = app.elderStatus;
    final name = app.elderNameEn;
    String title;
    String sub;
    Color dot = YaadainTheme.primary;
    Color halo = YaadainTheme.primarySoft;
    if (st == null) {
      title = 'Waiting for $name’s phone';
      sub = 'No update yet';
      dot = YaadainTheme.sepia;
      halo = YaadainTheme.line;
    } else if (st.inside) {
      title = '$name is at home';
      sub = 'Last seen ${EnFmt.relative(st.at, app.now)}${st.battery != null ? ' · phone ${st.battery}%' : ''}';
    } else {
      title = '$name is out';
      sub = '${EnFmt.distance(st.distanceM)} ${faCompass(st.bearingDeg)} of home · ${EnFmt.relative(st.at, app.now)}';
      dot = YaadainTheme.accentDark;
      halo = YaadainTheme.attentionSoft;
    }

    final entry = app.circleEntry(app.settings.contributorMemberId ?? '');
    final sees = <String>[];
    if (entry == null || entry.isEverything) {
      sees.add('everything');
    } else {
      if (entry.canSeeStatus) sees.add('status');
      if (entry.canSeeZones) sees.add('zones');
      if (entry.canSeeLastPosition) sees.add('last position');
    }
    final seesTxt = sees.isEmpty ? 'nothing yet' : sees.join(' and ');

    return Semantics(
      button: true,
      label: '$title. $sub',
      child: InkWell(
        borderRadius: YaadainTheme.radius28,
        onTap: () => Navigator.pushNamed(context, Routes.careWhere),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 6),
          decoration: BoxDecoration(
            color: YaadainTheme.surface,
            borderRadius: YaadainTheme.radius28,
            border: Border.all(color: YaadainTheme.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 14, left: 2),
                    child: FaDot(color: dot, halo: halo, size: 10),
                  ),
                  Expanded(child: EnText(title, size: 28, weight: FontWeight.w600, display: true, height: 1.15)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: EnText(sub, size: 15, weight: FontWeight.w600, color: YaadainTheme.bodyDim),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: YaadainTheme.gold.withOpacity(0.5)),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    const YIcon(YI.eye, size: 20, color: YaadainTheme.muted),
                    const SizedBox(width: 8),
                    Expanded(child: EnText('You see: $seesTxt', size: 13, weight: FontWeight.w700, color: YaadainTheme.muted)),
                    const YIcon(YI.chevronRight, size: 20, color: YaadainTheme.stroke),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Record button ────────────────────────────────────────────────────────

class _RecordButton extends StatelessWidget {
  final AppState app;
  const _RecordButton({required this.app});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Record a hello for ${app.elderNameEn}',
      child: InkWell(
        borderRadius: YaadainTheme.radius20,
        onTap: () => Navigator.pushNamed(context, Routes.familyRecord),
        child: Container(
          height: 56,
          decoration: const BoxDecoration(color: YaadainTheme.primary, borderRadius: YaadainTheme.radius20),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const YIcon(YI.mic, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              EnText('Record a hello for ${app.elderNameEn}', size: 16, weight: FontWeight.w800, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Your hellos ──────────────────────────────────────────────────────────

class _Hellos extends StatelessWidget {
  final AppState app;
  const _Hellos({required this.app});

  @override
  Widget build(BuildContext context) {
    final meId = app.settings.contributorMemberId;
    final mine = app.letters.where((l) => meId != null && l.memberId == meId).toList();
    final children = <Widget>[
      FaSectionHeader('Your hellos', action: 'All', onAction: () => Navigator.pushNamed(context, Routes.familyRecord)),
      const SizedBox(height: 8),
    ];
    if (mine.isEmpty) {
      children.add(YCard(
        padding: EdgeInsets.zero,
        child: FaRow(
          leading: const FaIconBox(YI.volume, bg: YaadainTheme.line, fg: YaadainTheme.muted),
          title: 'No hello recorded yet',
          sub: 'A few kind words in your voice go a long way',
          minHeight: 72,
          padding: const EdgeInsets.all(16),
          onTap: () => Navigator.pushNamed(context, Routes.familyRecord),
        ),
      ));
    } else {
      final l = mine.first;
      Episode? lastPlay;
      for (final e in app.episodes) {
        // Only plays of THIS hello: a fresh recording must not inherit the
        // previous hello's play history.
        if (e.category == 'voice_played' && e.note == meId && e.at.isAfter(l.at)) {
          if (lastPlay == null || e.at.isAfter(lastPlay.at)) lastPlay = e;
        }
      }
      final plays = l.playCount;
      String sub;
      if (plays == 0 && lastPlay == null) {
        sub = 'Not played yet';
      } else {
        final n = plays > 0 ? plays : 1;
        final cnt = n == 1 ? 'once' : (n == 2 ? 'twice' : '$n times');
        sub = 'Played $cnt${lastPlay != null ? ' · last ${_when(lastPlay.at, app.now)}' : ''}';
      }
      children.add(YCard(
        padding: EdgeInsets.zero,
        child: FaRow(
          leading: const FaIconBox(YI.volume, size: 40),
          title: '${EnFmt.weekday(l.at)}’s hello',
          sub: sub,
          minHeight: 72,
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          trailing: FaPlayCircle(
            label: 'Play your hello',
            onTap: () async {
              final p = l.audioPath;
              if (p == null) {
                ScaffoldMessenger.maybeOf(context)
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('This recording is not on this phone')));
                return;
              }
              await Svc.audio.play(p);
            },
          ),
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

String _when(DateTime at, DateTime now) {
  final same = at.year == now.year && at.month == now.month && at.day == now.day;
  if (same) return 'today, ${EnFmt.time(at).toLowerCase()}';
  final y = now.subtract(const Duration(days: 1));
  if (at.year == y.year && at.month == y.month && at.day == y.day) return 'yesterday, ${EnFmt.time(at).toLowerCase()}';
  return '${EnFmt.weekday(at)}, ${EnFmt.time(at).toLowerCase()}';
}

// ── Add a memory ─────────────────────────────────────────────────────────

class _MemoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return YCard(
      padding: EdgeInsets.zero,
      child: FaRow(
        leading: FaIconBox(YI.image, size: 44, bg: YaadainTheme.tintGold.bg, fg: YaadainTheme.tintGold.fg),
        title: 'Add a memory',
        sub: 'A photo, and your voice telling its story. It shows on his home screen.',
        chevron: true,
        minHeight: 76,
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.pushNamed(context, Routes.familyRecord),
      ),
    );
  }
}

// ── Today with him ───────────────────────────────────────────────────────

class _TodayWithHim extends StatelessWidget {
  final AppState app;
  const _TodayWithHim({required this.app});

  bool _today(DateTime d) => d.year == app.now.year && d.month == app.now.month && d.day == app.now.day;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    // Latest medicine taken today.
    RoutineLog? taken;
    RoutineItem? takenItem;
    final key = RoutineLog.dayKey(app.now);
    for (final l in app.care.routineLogs) {
      if (l.day != key || l.status != 'taken') continue;
      RoutineItem? it;
      for (final r in app.routine) {
        if (r.id == l.itemId) it = r;
      }
      if (it == null || it.kind != RoutineKind.medicine) continue;
      if (taken == null || (l.at ?? app.now).isAfter(taken.at ?? app.now)) {
        taken = l;
        takenItem = it;
      }
    }
    if (taken != null && takenItem != null) {
      rows.add(FaRow(
        leading: const FaIconBox(YI.check),
        title: '${takenItem.titleEn} taken',
        sub: '${taken.at != null ? faClock(taken.at!) : 'Today'}${taken.by.isNotEmpty ? ' · ${taken.by} marked it' : ''}',
      ));
    }

    // Latest hello played today.
    Episode? played;
    for (final e in app.episodes) {
      if (e.category == 'voice_played' && _today(e.at) && !e.at.isAfter(app.now)) {
        if (played == null || e.at.isAfter(played.at)) played = e;
      }
    }
    if (played != null) {
      final m = app.memberById(played.note ?? '');
      final meId = app.settings.contributorMemberId;
      final who = (m != null && m.id == meId) ? 'your' : (m != null ? '${m.firstNameEn}’s' : 'a');
      rows.add(FaRow(
        leading: FaIconBox(YI.volume, bg: YaadainTheme.tintGold.bg, fg: YaadainTheme.tintGold.fg),
        title: 'He played $who hello',
        sub: '${EnFmt.time(played.at).toLowerCase()} · from the family faces on his home screen',
      ));
    }

    if (rows.isEmpty) {
      rows.add(const FaRow(
        leading: FaIconBox(YI.clock, bg: YaadainTheme.line, fg: YaadainTheme.muted),
        title: 'Nothing logged yet today',
        sub: 'Medicine and hellos will appear here',
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FaSectionHeader('Today with him'),
        const SizedBox(height: 8),
        FaCardList(children: rows),
      ],
    );
  }
}

// ── On duty ──────────────────────────────────────────────────────────────

class _OnDuty extends StatelessWidget {
  final AppState app;
  const _OnDuty({required this.app});

  @override
  Widget build(BuildContext context) {
    final on = app.onShiftNow;
    final meId = app.settings.contributorMemberId;
    Widget content;
    if (on == null) {
      content = FaRow(
        leading: const FaIconBox(YI.users, size: 40, bg: YaadainTheme.line, fg: YaadainTheme.muted),
        title: 'Nobody is on duty now',
        sub: 'Take a shift in the Care circle',
        chevron: true,
        minHeight: 72,
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.pushNamed(context, Routes.careCircle),
      );
    } else {
      final m = app.memberById(on.memberId);
      final isMe = on.memberId == meId;
      final end = on.shiftEndHour;
      CircleMember? next;
      if (end != null) {
        for (final c in app.circle) {
          if (c.shiftStartHour == end && c.memberId != on.memberId) next = c;
        }
      }
      String? sub;
      if (next != null) {
        final nm = app.memberById(next.memberId);
        final nWho = next.memberId == meId ? 'you' : (nm?.firstNameEn ?? 'a relative');
        final s = next.shiftStartHour, e = next.shiftEndHour;
        final span = (s != null && e != null) ? ', ${_h(s)} – ${faHour(e)}' : '';
        final first = next.memberId == meId && (next.shiftLabel ?? '').toLowerCase().contains('alert');
        sub = 'Then $nWho$span${first ? ' · you get the first alert' : ''}';
      }
      content = FaRow(
        leading: m != null ? Avatar.member(m, size: 40) : null,
        title: '${isMe ? 'You are' : '${m?.firstNameEn ?? 'Someone'} is'} on duty${end != null ? ' until ${faHour(end)}' : ''}',
        sub: sub,
        chevron: true,
        minHeight: 72,
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.pushNamed(context, Routes.careCircle),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FaSectionHeader('Who is on duty'),
        const SizedBox(height: 8),
        YCard(padding: EdgeInsets.zero, child: content),
      ],
    );
  }

  /// "6" in "6 – 11 pm" (no am/pm on the first number).
  String _h(int h) {
    final x = h % 12 == 0 ? 12 : h % 12;
    return '$x';
  }
}

// ── Family code ──────────────────────────────────────────────────────────

class _CodeCard extends StatelessWidget {
  final AppState app;
  const _CodeCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
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
          Semantics(
            button: true,
            label: 'Share family code',
            child: InkWell(
              borderRadius: YaadainTheme.radius12,
              onTap: () => faShareCode(context, app),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(color: YaadainTheme.surface, borderRadius: YaadainTheme.radius12),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  YIcon(YI.share, size: 18, color: YaadainTheme.primaryDark),
                  SizedBox(width: 8),
                  EnText('Share', size: 14, weight: FontWeight.w800, color: YaadainTheme.primaryDark),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
