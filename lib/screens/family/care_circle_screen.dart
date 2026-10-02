import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../demo/demo_controls.dart';
import '../../design/design.dart';
import '../../models/care.dart';
import '../../models/family_member.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import '../../util/en_format.dart';
import 'widgets/family_a_common.dart';

/// Care circle (`/care/circle`). English, board CareCircle.
class CareCircleScreen extends StatelessWidget {
  const CareCircleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final inset = MediaQuery.of(context).padding.top;
    final meId = app.settings.contributorMemberId;
    final me = meId == null ? null : app.memberById(meId);

    return FamilyTabScaffold(
      tab: FamilyTab.circle,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, inset + 14, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                    child: EnText('Care circle',
                        size: 28, weight: FontWeight.w600, display: true)),
                if (kTrackingIsDemo) ...[
                  DemoChip(onLongPress: () => DemoControls.open(context)),
                  const SizedBox(width: 10),
                ],
                if (me != null)
                  Avatar.member(me, size: 36)
                else
                  Avatar(
                      monogram: app.myNameEn.isEmpty
                          ? '?'
                          : app.myNameEn.substring(0, 1).toUpperCase(),
                      size: 36),
              ],
            ),
            const SizedBox(height: 18),
            FaSectionHeader(
              'Today · ${EnFmt.weekday(app.now)}',
              action: 'Week',
              onAction: () => ScaffoldMessenger.maybeOf(context)
                ?..hideCurrentSnackBar()
                ..showSnackBar(
                    const SnackBar(content: Text('Shifts repeat every day'))),
            ),
            const SizedBox(height: 4),
            _Roster(app: app),
            const SizedBox(height: 12),
            _TakeShift(app: app),
            const SizedBox(height: 16),
            _HandoffCard(app: app),
            const SizedBox(height: 22),
            _Messages(app: app),
            const SizedBox(height: 22),
            _Members(app: app),
            const SizedBox(height: 14),
            _Footer(app: app),
          ],
        ),
      ),
    );
  }
}

String _span(int s, int e) {
  String h(int x) => '${x % 12 == 0 ? 12 : x % 12}';
  String ap(int x) => (x % 24) < 12 ? 'am' : 'pm';
  return ap(s) == ap(e)
      ? '${h(s)} – ${h(e)} ${ap(e)}'
      : '${h(s)} ${ap(s)} – ${h(e)} ${ap(e)}';
}

String? _city(FamilyMember? m) {
  final r = RegExp(r'Lives in (.+)$', caseSensitive: false)
      .firstMatch((m?.note ?? '').trim());
  return r?.group(1)?.trim();
}

// ── Roster ───────────────────────────────────────────────────────────────

class _Roster extends StatelessWidget {
  final AppState app;
  const _Roster({required this.app});

  @override
  Widget build(BuildContext context) {
    final shifts = app.circle
        .where((c) => c.shiftStartHour != null && c.shiftEndHour != null)
        .toList()
      ..sort((a, b) => a.shiftStartHour!.compareTo(b.shiftStartHour!));
    final on = app.onShiftNow;
    final meId = app.settings.contributorMemberId;

    if (shifts.isEmpty) {
      return const YCard(
        padding: EdgeInsets.all(18),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              FaIconBox(YI.calendar, size: 44),
              SizedBox(height: 10),
              EnText('No shifts yet', size: 16, weight: FontWeight.w800),
              SizedBox(height: 4),
              EnText('Take a shift so the family knows who to call first.',
                  size: 13,
                  weight: FontWeight.w600,
                  color: YaadainTheme.muted,
                  align: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return FaCardList(
      dividerInset: 16,
      children: [
        for (final c in shifts)
          Builder(builder: (context) {
            final m = app.memberById(c.memberId);
            final isMe = c.memberId == meId;
            final city = _city(m);
            final kin = m?.kinshipEnglish ?? 'Family';
            final isOn = on != null && on.memberId == c.memberId;
            return FaRow(
              minHeight: 68,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 74,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EnText(_span(c.shiftStartHour!, c.shiftEndHour!),
                          size: 13, weight: FontWeight.w800, height: 1.25),
                      if (isOn)
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Row(children: [
                            FaDot(size: 8),
                            SizedBox(width: 9),
                            EnText('now',
                                size: 12,
                                weight: FontWeight.w700,
                                color: YaadainTheme.primaryDark),
                          ]),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (m != null)
                  Avatar.member(m, size: 36)
                else
                  const Avatar(monogram: '?', size: 36),
              ]),
              title: m?.firstNameEn.isNotEmpty == true
                  ? m!.firstNameEn
                  : 'Relative',
              sub: isMe ? 'You' : (city != null ? 'From $city' : kin),
              titleSize: 16,
              trailing: _shiftPill(c.shiftLabel),
              onTap: m == null
                  ? null
                  : () => Navigator.pushNamed(context, Routes.careAddRelative,
                      arguments: AddRelativeArgs(memberId: m.id)),
            );
          }),
      ],
    );
  }

  Widget? _shiftPill(String? label) {
    final l = (label ?? '').trim();
    if (l.isEmpty) return null;
    final low = l.toLowerCase();
    final (bg, fg, icon) = low.contains('call')
        ? (YaadainTheme.primarySoft, YaadainTheme.primaryDark, YI.phone)
        : low.contains('alert')
            ? (YaadainTheme.attentionSoft, YaadainTheme.accentDark, YI.bell)
            : (const Color(0xFFEFE8DA), YaadainTheme.muted, YI.moon);
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration:
          BoxDecoration(color: bg, borderRadius: YaadainTheme.radiusPill),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        YIcon(icon, size: 14, color: fg),
        const SizedBox(width: 5),
        EnText(l, size: 12, weight: FontWeight.w800, color: fg, height: 1.1),
      ]),
    );
  }
}

// ── Take a shift ─────────────────────────────────────────────────────────

class _TakeShift extends StatelessWidget {
  final AppState app;
  const _TakeShift({required this.app});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Take a shift',
      child: InkWell(
        borderRadius: YaadainTheme.radius12,
        onTap: () => _pickShift(context, app),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: YaadainTheme.surface,
            borderRadius: YaadainTheme.radius12,
            border: Border.all(color: YaadainTheme.stroke, width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            YIcon(YI.calendar, size: 20, color: YaadainTheme.ink),
            SizedBox(width: 10),
            EnText('Take a shift', size: 15, weight: FontWeight.w800),
          ]),
        ),
      ),
    );
  }
}

Future<void> _pickShift(BuildContext context, AppState app) async {
  final meId = app.settings.contributorMemberId;
  if (meId == null) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
          content: Text('Join the family first to take a shift')));
    return;
  }
  const options = [
    (6, 18, 'First call', 'Morning to evening'),
    (18, 23, 'First alert', 'Evening'),
    (23, 6, 'Night', 'Overnight'),
  ];
  final picked = await showModalBottomSheet<(int, int, String, String)>(
    context: context,
    backgroundColor: YaadainTheme.paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => FamilyTheme(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EnText('Take a shift',
                  size: 22, weight: FontWeight.w600, display: true),
              const SizedBox(height: 4),
              const EnText(
                  'You will be the person the family calls during these hours.',
                  size: 13,
                  weight: FontWeight.w600,
                  color: YaadainTheme.muted),
              const SizedBox(height: 12),
              FaCardList(
                dividerInset: 16,
                children: [
                  for (final o in options)
                    FaRow(
                      minHeight: 60,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      title: '${_span(o.$1, o.$2)} · ${o.$3}',
                      sub: o.$4,
                      onTap: () => Navigator.pop(ctx, o),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (picked == null) return;
  final existing = app.circleEntry(meId);
  final entry = existing ??
      CircleMember(
          memberId: meId,
          roleLabel: app.isCaregiver ? 'Primary caregiver' : 'Family');
  entry.shiftStartHour = picked.$1;
  entry.shiftEndHour = picked.$2;
  entry.shiftLabel = picked.$3;
  await app.saveCircleMember(entry);
}

// ── Handoff ──────────────────────────────────────────────────────────────

class _HandoffCard extends StatelessWidget {
  final AppState app;
  const _HandoffCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final h = app.handoff;
    final has = h != null && h.text.trim().isNotEmpty;
    FamilyMember? by;
    if (has) {
      for (final m in app.members) {
        if (m.firstNameEn == h.byName || m.nameEn == h.byName) by = m;
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: YaadainTheme.surface,
        borderRadius: YaadainTheme.radius20,
        border: Border.all(color: YaadainTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: YaadainTheme.gold),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(child: EnText.eyebrow('HANDOFF NOTE')),
                      if (has)
                        EnText(EnFmt.time(h.at).toLowerCase(),
                            size: 12,
                            weight: FontWeight.w700,
                            color: YaadainTheme.muted),
                    ]),
                    const SizedBox(height: 10),
                    if (has)
                      EnText('“${h.text.trim()}”',
                          size: 20,
                          weight: FontWeight.w500,
                          display: true,
                          height: 1.3)
                    else
                      const EnText(
                          'No note yet. Leave one for whoever takes the next shift.',
                          size: 15,
                          weight: FontWeight.w600,
                          color: YaadainTheme.muted),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (has) ...[
                          if (by != null)
                            Avatar.member(by, size: 28)
                          else
                            Avatar(
                                monogram: h.byName.isEmpty
                                    ? '?'
                                    : h.byName.substring(0, 1).toUpperCase(),
                                size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: EnText(
                              h.shiftLabel.isEmpty
                                  ? h.byName
                                  : '${h.byName}, ${h.shiftLabel}',
                              size: 13,
                              weight: FontWeight.w700,
                              color: YaadainTheme.bodyDim,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        InkWell(
                          onTap: () => _addNote(context, app),
                          borderRadius: YaadainTheme.radius12,
                          child: const SizedBox(
                            height: 48,
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              YIcon(YI.pencil,
                                  size: 18, color: YaadainTheme.primary),
                              SizedBox(width: 6),
                              EnText('Add a note',
                                  size: 14,
                                  weight: FontWeight.w800,
                                  color: YaadainTheme.primary),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _addNote(BuildContext context, AppState app) async {
  final ctrl = TextEditingController(text: app.handoff?.text ?? '');
  final text = await showDialog<String>(
    context: context,
    builder: (ctx) => FamilyTheme(
      child: AlertDialog(
        backgroundColor: YaadainTheme.paper,
        title: const EnText('Handoff note',
            size: 22, weight: FontWeight.w600, display: true),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 4,
          minLines: 2,
          decoration: const InputDecoration(
              hintText: 'How was he? Anything the next person should know?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Save')),
        ],
      ),
    ),
  );
  ctrl.dispose();
  if (text == null || text.trim().isEmpty) return;
  final mine = app.circleEntry(app.settings.contributorMemberId ?? '');
  final label =
      (mine?.shiftLabel ?? '').toLowerCase() == 'night' ? 'night shift' : null;
  await app.saveHandoff(text, shiftLabel: label ?? app.handoff?.shiftLabel);
}

// ── Messages ─────────────────────────────────────────────────────────────

class _Messages extends StatelessWidget {
  final AppState app;
  const _Messages({required this.app});

  String _when(VoiceLetter l) {
    final n = app.now;
    String t = EnFmt.time(l.at).toLowerCase();
    final same =
        l.at.year == n.year && l.at.month == n.month && l.at.day == n.day;
    final y = n.subtract(const Duration(days: 1));
    final yest =
        l.at.year == y.year && l.at.month == y.month && l.at.day == y.day;
    final day = same
        ? 'Today'
        : (yest
            ? 'Yesterday'
            : '${EnFmt.weekdayShort(l.at)} ${l.at.day} ${EnFmt.monthShort(l.at.month)}');
    final m = l.durationSec ~/ 60, s = l.durationSec % 60;
    return '$day $t · $m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final letters = app.letters.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FaSectionHeader('Messages'),
        const SizedBox(height: 8),
        if (letters.isEmpty)
          const FaCardList(dividerInset: 16, children: [
            FaRow(
              leading: FaIconBox(YI.message,
                  bg: YaadainTheme.line, fg: YaadainTheme.muted),
              title: 'No messages yet',
              sub: 'Voice notes for him appear here',
              minHeight: 64,
            ),
          ])
        else
          FaCardList(
            dividerInset: 16,
            children: [
              for (final l in letters)
                Builder(builder: (context) {
                  final m = app.memberById(l.memberId);
                  return FaRow(
                    minHeight: 64,
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    leading: m != null
                        ? Avatar.member(m, size: 40)
                        : const Avatar(monogram: '?', size: 40),
                    title: m?.firstNameEn.isNotEmpty == true
                        ? m!.firstNameEn
                        : 'Relative',
                    sub: _when(l),
                    trailing: FaPlayCircle(
                      label:
                          'Play message from ${m?.firstNameEn ?? 'relative'}',
                      onTap: () async {
                        final p = l.audioPath;
                        if (p == null) {
                          ScaffoldMessenger.maybeOf(context)
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(
                                content: Text(
                                    'This recording is not on this phone')));
                          return;
                        }
                        await Svc.audio.play(p);
                      },
                    ),
                  );
                }),
            ],
          ),
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, Routes.familyRecord),
            borderRadius: YaadainTheme.radius12,
            child: const SizedBox(
              height: 52,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  YIcon(YI.mic, size: 18, color: YaadainTheme.primary),
                  SizedBox(width: 8),
                  EnText('Record a voice note',
                      size: 14,
                      weight: FontWeight.w800,
                      color: YaadainTheme.primary),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Members ──────────────────────────────────────────────────────────────

class _Members extends StatelessWidget {
  final AppState app;
  const _Members({required this.app});

  int _rank(CircleMember c) => c.isEverything
      ? 9
      : (c.canSeeStatus ? 1 : 0) +
          (c.canSeeZones ? 1 : 0) +
          (c.canSeeLastPosition ? 1 : 0);

  String _sees(CircleMember c) {
    if (c.isEverything) return 'Everything';
    final p = <String>[
      if (c.canSeeStatus) 'Status',
      if (c.canSeeZones) 'zones',
      if (c.canSeeLastPosition) 'last position'
    ];
    return p.isEmpty ? 'Nothing' : p.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final entries = [...app.circle]
      ..sort((a, b) => _rank(b).compareTo(_rank(a)));
    final meId = app.settings.contributorMemberId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FaSectionHeader('Members and what they see'),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          const FaCardList(dividerInset: 16, children: [
            FaRow(
              leading: FaIconBox(YI.users,
                  bg: YaadainTheme.line, fg: YaadainTheme.muted),
              title: 'Nobody in the circle yet',
              sub: 'Relatives you add will appear here',
              minHeight: 60,
            ),
          ])
        else
          FaCardList(
            dividerInset: 16,
            children: [
              for (final c in entries)
                Builder(builder: (context) {
                  final m = app.memberById(c.memberId);
                  final isMe = c.memberId == meId;
                  final city = _city(m);
                  final role = c.isEverything
                      ? 'Caregiver'
                      : (m?.kinshipEnglish ?? c.roleLabel);
                  final sub = isMe
                      ? '$role · you'
                      : (city != null ? '$role · $city' : role);
                  return FaRow(
                    minHeight: 60,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    leading: m != null
                        ? Avatar.member(m, size: 40)
                        : const Avatar(monogram: '?', size: 40),
                    title: m?.firstNameEn.isNotEmpty == true
                        ? m!.firstNameEn
                        : 'Relative',
                    sub: sub,
                    titleSize: 16,
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: EnText(_sees(c),
                          size: 12,
                          weight: FontWeight.w700,
                          align: TextAlign.right,
                          color: YaadainTheme.ink,
                          height: 1.3),
                    ),
                  );
                }),
            ],
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final AppState app;
  const _Footer({required this.app});

  @override
  Widget build(BuildContext context) {
    final c = app.consent;
    final when = c == null
        ? ''
        : ' on ${c.agreedAt.day} ${EnFmt.month(c.agreedAt.month)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
              padding: EdgeInsets.only(top: 2),
              child: YIcon(YI.shield, size: 18, color: YaadainTheme.muted)),
          const SizedBox(width: 10),
          Expanded(
            child: EnText(
              'What each person sees follows what ${app.elderNameEn} agreed$when. He can see on his phone how often you looked today.',
              size: 13,
              weight: FontWeight.w600,
              color: YaadainTheme.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
