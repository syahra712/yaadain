import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/care.dart';
import '../../models/episode_log.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import '../../tracking/tracking_source.dart';
import '../../util/en_format.dart';
import 'widgets/safety_family_common.dart';
import 'widgets/safety_family_radar.dart';

/// Opens of this screen since the app started (the "You looked N times" line).
int _looksThisSession = 0;

/// Family tab: where is he now, as events and a radar, never a trail.
class WhereIsAbuScreen extends StatefulWidget {
  const WhereIsAbuScreen({super.key});

  @override
  State<WhereIsAbuScreen> createState() => _WhereIsAbuScreenState();
}

class _WhereIsAbuScreenState extends State<WhereIsAbuScreen> {
  late final int _looks;

  @override
  void initState() {
    super.initState();
    _looksThisSession++;
    _looks = _looksThisSession;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final name = whoName(app);
    final caregiver = app.isCaregiver;
    final status = app.elderStatus;
    final alert = app.activeAlert;
    final outside = status != null && !status.inside;
    final zone = (alert != null && !alert.isResolved)
        ? null
        : zoneContaining(app, status);
    final showRadar = caregiver ||
        (app
                .circleEntry(app.settings.contributorMemberId ?? '')
                ?.canSeeLastPosition ??
            false);
    final looks = _looks + (app.hasDemoData ? 1 : 0);

    return FamilyTabScaffold(
      tab: FamilyTab.abu,
      title: caregiver ? 'Where is $name' : name,
      subtitle: EnFmt.dayDate(app.now),
      actions: [_ElderDot(app: app, outside: outside)],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _StatusCard(
              app: app,
              status: status,
              outside: outside,
              zone: zone,
              looks: looks,
              hasAlert: alert != null && !alert.isResolved),
          const SizedBox(height: 12),
          if (app.zones.isNotEmpty)
            _ZoneChips(app: app, zone: zone, outside: outside),
          if (app.zones.isNotEmpty) const SizedBox(height: 12),
          if (showRadar)
            _RadarCard(app: app, status: status, outside: outside, zone: zone)
          else
            _LimitedCard(app: app, status: status, outside: outside),
          const SizedBox(height: 16),
          _Actions(app: app),
          SafetySectionHeader('Today', trailing: 'Events, not locations'),
          _Timeline(app: app),
          const SizedBox(height: 12),
          _WeekRow(app: app),
          const SizedBox(height: 12),
          SafetyButton.clayOutline(
            "I can't find him",
            icon: YI.alertTriangle,
            onTap: () => Navigator.of(context).pushNamed(Routes.careFind),
          ),
        ],
      ),
    );
  }
}

class _ElderDot extends StatelessWidget {
  final AppState app;
  final bool outside;
  const _ElderDot({required this.app, required this.outside});

  @override
  Widget build(BuildContext context) {
    final initial =
        app.elderNameEn.isEmpty ? 'D' : app.elderNameEn.trim()[0].toUpperCase();
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(clipBehavior: Clip.none, children: [
        Align(
            alignment: Alignment.center,
            child: Avatar(
                monogram: initial, size: 48, tint: YaadainTheme.tintGold)),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: outside ? YaadainTheme.accentDark : YaadainTheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: YaadainTheme.paper, width: 2),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final AppState app;
  final ElderStatus? status;
  final bool outside;
  final SafeZone? zone;
  final int looks;
  final bool hasAlert;
  const _StatusCard(
      {required this.app,
      required this.status,
      required this.outside,
      required this.zone,
      required this.looks,
      required this.hasAlert});

  String _headline() {
    final s = status;
    if (s == null) return 'No position yet';
    if (!s.inside) {
      return zone != null
          ? 'At ${zone!.name}'
          : 'Out, ${EnFmt.distance(s.distanceM)} from home';
    }
    final since = _homeSince();
    return since == null ? 'At home' : 'At home since ${tLower(since)}';
  }

  DateTime? _homeSince() {
    DateTime? best;
    for (final e in app.episodes) {
      if (e.category == 'zone_return' && (best == null || e.at.isAfter(best)))
        best = e.at;
    }
    if (best == null) return null;
    final n = app.now;
    return DateTime(best.year, best.month, best.day) ==
            DateTime(n.year, n.month, n.day)
        ? best
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final s = status;
    return YCard(
      padding: const EdgeInsets.all(20),
      radius: 28,
      shadow: true,
      child: SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EnText(_headline(),
              size: 26,
              weight: FontWeight.w700,
              display: true,
              height: 1.15,
              color: (outside && zone == null)
                  ? YaadainTheme.accentDark
                  : YaadainTheme.ink),
          const SizedBox(height: 10),
          if (s != null)
            StatusMeta(
                battery: s.battery,
                updatedAt: s.at,
                sharing: true,
                now: app.now)
          else
            EnText('His phone has not reported yet.',
                size: 14, weight: FontWeight.w700, color: YaadainTheme.muted),
          const SizedBox(height: 14),
          const Divider(height: 1, color: YaadainTheme.line),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: YIcon(YI.shieldCheck,
                  size: 16, color: YaadainTheme.muted, strokeWidth: 2.2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: EnText(
                  'You looked $looks ${looks == 1 ? 'time' : 'times'} today. He can see this on his phone.',
                  size: 14,
                  weight: FontWeight.w600,
                  color: YaadainTheme.muted,
                  height: 1.35),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ZoneChips extends StatelessWidget {
  final AppState app;
  final SafeZone? zone;
  final bool outside;
  const _ZoneChips(
      {required this.app, required this.zone, required this.outside});

  @override
  Widget build(BuildContext context) {
    final current = zone?.id ?? (outside ? null : app.homeZone?.id);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: app.zones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final z = app.zones[i];
          final on = z.id == current;
          return GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(Routes.careZones),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: on ? YaadainTheme.primarySoft : YaadainTheme.surface,
                borderRadius: YaadainTheme.radiusPill,
                border: Border.all(
                    color: on ? YaadainTheme.primarySoft : YaadainTheme.line),
              ),
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (on) ...[
                  const YIcon(YI.check,
                      size: 16,
                      color: YaadainTheme.primaryDark,
                      strokeWidth: 2.6),
                  const SizedBox(width: 6)
                ],
                EnText(z.name,
                    size: 14,
                    weight: FontWeight.w800,
                    color: on ? YaadainTheme.primaryDark : YaadainTheme.ink,
                    height: 1.1,
                    maxLines: 1),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _RadarCard extends StatelessWidget {
  final AppState app;
  final ElderStatus? status;
  final bool outside;
  final SafeZone? zone;
  const _RadarCard(
      {required this.app,
      required this.status,
      required this.outside,
      required this.zone});

  @override
  Widget build(BuildContext context) {
    final s = status;
    final home = app.homePoint;
    // Clay is for "outside and nowhere known"; a saved safe zone is calm.
    final warn = outside && zone == null;
    final String foot;
    if (s == null) {
      foot = 'Position unknown';
    } else if (s.inside) {
      foot = 'Inside the home zone';
    } else if (zone != null) {
      foot = 'At ${zone!.name}';
    } else {
      foot = 'Outside the home zone';
    }
    return YCard(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      radius: 28,
      child: Column(children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: SafetyRadar(
              geometry: RadarGeometry.compact,
              homeRadiusM: home.radiusM,
              distanceM: s?.distanceM,
              bearingDeg: s?.bearingDeg ?? 0,
              outside: outside,
              places: radarPlaces(app),
              landmark: demoLandmark(app, s),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                YIcon(warn ? YI.mapPin : YI.shieldCheck,
                    size: 18,
                    color: warn
                        ? YaadainTheme.accentDark
                        : YaadainTheme.primary,
                    strokeWidth: 2.4),
                const SizedBox(width: 8),
                Flexible(
                  child: EnText(foot,
                      size: 15,
                      weight: FontWeight.w800,
                      color: warn
                          ? YaadainTheme.accentDark
                          : YaadainTheme.primaryDark,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            EnText('No trail is kept',
                size: 13, weight: FontWeight.w700, color: YaadainTheme.muted),
          ]),
        ),
      ]),
    );
  }
}

/// Permission-limited view (no radar): only whether he is home or out.
class _LimitedCard extends StatelessWidget {
  final AppState app;
  final ElderStatus? status;
  final bool outside;
  const _LimitedCard(
      {required this.app, required this.status, required this.outside});

  @override
  Widget build(BuildContext context) {
    final s = status;
    final line = s == null
        ? 'His phone has not reported yet.'
        : s.inside
            ? 'He is inside the home zone.'
            : 'He is outside the home zone. Bilal has been told.';
    return YCard(
      padding: const EdgeInsets.all(20),
      radius: 28,
      child: SizedBox(
        width: double.infinity,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: outside
                    ? YaadainTheme.attentionSoft
                    : YaadainTheme.primarySoft,
                shape: BoxShape.circle),
            alignment: Alignment.center,
            child: YIcon(outside ? YI.mapPin : YI.shieldCheck,
                size: 22,
                color: outside
                    ? YaadainTheme.accentDark
                    : YaadainTheme.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EnText(line, size: 16, weight: FontWeight.w800, height: 1.3),
              const SizedBox(height: 6),
              EnText(
                  'Where he is on the map is shared with the person who looks after him. You see events, not locations.',
                  size: 14,
                  weight: FontWeight.w600,
                  color: YaadainTheme.muted,
                  height: 1.35),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final AppState app;
  const _Actions({required this.app});

  Widget _tile(BuildContext context, String label, YI icon, VoidCallback onTap,
      {bool primary = false}) {
    final fg = primary ? Colors.white : YaadainTheme.ink;
    final br = BorderRadius.circular(20);
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: primary
              ? const [
                  BoxShadow(
                      color: Color(0x331F6F5C),
                      blurRadius: 16,
                      offset: Offset(0, 6))
                ]
              : null,
        ),
        child: Material(
          color: primary ? YaadainTheme.primary : YaadainTheme.surface,
          borderRadius: br,
          child: InkWell(
            borderRadius: br,
            onTap: onTap,
            child: Container(
              height: 64,
              decoration: primary
                  ? null
                  : BoxDecoration(
                      borderRadius: br,
                      border: Border.all(color: YaadainTheme.stroke)),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    YIcon(icon, size: 22, color: fg, strokeWidth: 2.2),
                    const SizedBox(height: 4),
                    EnText(label,
                        size: 14,
                        weight: FontWeight.w800,
                        color: fg,
                        height: 1.1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = whoName(app);
    return Row(children: [
      _tile(context, 'Call $name', YI.phone, () => _call(context),
          primary: true),
      const SizedBox(width: 8),
      _tile(context, 'Voice note', YI.mic, () {
        Navigator.of(context).pushNamed(Routes.familyRecord,
            arguments:
                RecordHelloArgs(memberId: app.settings.contributorMemberId));
      }),
      const SizedBox(width: 8),
      _tile(context, 'Play Calm', YI.waves, () {
        app.logEpisode(Episode(category: 'calm', at: app.now));
        safetyToast(context,
            'Noted. Playing Calm on his phone needs the live connection.');
      }),
    ]);
  }

  Future<void> _call(BuildContext context) async {
    final phone = elderPhone(app);
    if (phone == null) {
      safetyToast(context, 'Add his phone number in the missing pack first.');
      return;
    }
    final ok = await Svc.launcher.call(EnFmt.telDigits(phone));
    if (!ok && context.mounted)
      safetyToast(context, 'Could not open the dialer.');
  }
}

class _Row {
  final DateTime at;
  final String timeLabel;
  final YI icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String? sub;
  final String? chip;
  final bool chipAttention;
  _Row(this.at, this.timeLabel, this.icon, this.iconBg, this.iconFg, this.title,
      {this.sub, this.chip, this.chipAttention = false});
}

List<_Row> _buildRows(AppState app) {
  final n = app.now;
  final today = DateTime(n.year, n.month, n.day);
  final from = today.subtract(const Duration(days: 1));
  final eps = app
      .episodesSince(from)
      .where((e) => e.at.isBefore(n.add(const Duration(minutes: 1))))
      .toList()
    ..sort((a, b) => a.at.compareTo(b.at));
  final rows = <_Row>[];
  String? lastExitNote;
  final questions = <String, List<Episode>>{};
  for (final e in eps) {
    switch (e.category) {
      case 'zone_exit':
        lastExitNote = e.note;
        rows.add(_Row(
            e.at,
            tLower(e.at),
            YI.arrowRight,
            const Color(0xFFE3E8D6),
            const Color(0xFF475326),
            e.note != null ? 'Left home for ${e.note}' : 'Left home',
            chip: e.severity >= 2 ? 'unusual time' : 'usual time',
            chipAttention: e.severity >= 2));
      case 'zone_return':
        rows.add(_Row(
            e.at,
            tLower(e.at),
            YI.home,
            YaadainTheme.primarySoft,
            YaadainTheme.primaryDark,
            lastExitNote != null
                ? 'Returned home from $lastExitNote'
                : 'Returned home'));
        lastExitNote = null;
      case 'calm':
        rows.add(_Row(
            e.at,
            tLower(e.at),
            YI.waves,
            const Color(0xFFE9E1EC),
            const Color(0xFF55406A),
            e.note != null
                ? 'Calm played for ${e.note!.replaceAll(' min', ' minutes')}'
                : 'Calm played',
            sub: 'Played on his phone'));
      case 'night_pickup':
        rows.add(_Row(e.at, tLower(e.at), YI.moon, const Color(0xFFE9E1EC),
            const Color(0xFF55406A), 'Awake at night',
            sub: 'Night pickup logged', chip: 'check in', chipAttention: true));
      case 'question':
        final k = '${e.at.year}-${e.at.month}-${e.at.day}';
        questions.putIfAbsent(k, () => []).add(e);
    }
  }
  for (final list in questions.values) {
    final last = list.last;
    final q = last.question == null ? null : questionById(last.question!);
    final same = list.every((x) => x.question == last.question);
    final h = last.at.hour;
    final word = h < 12 ? 'morning' : (h < 17 ? 'afternoon' : 'evening');
    rows.add(_Row(
        last.at,
        word,
        YI.helpCircle,
        const Color(0xFFF1E6CC),
        const Color(0xFF6E5420),
        '${list.length} ${list.length == 1 ? 'question' : 'questions'} asked',
        sub: q == null
            ? null
            : (same && list.length > 1
                ? '"${q.textEn}" every time'
                : '"${q.textEn}"')));
  }
  rows.sort((a, b) => b.at.compareTo(a.at));
  return rows.take(6).toList();
}

class _Timeline extends StatelessWidget {
  final AppState app;
  const _Timeline({required this.app});

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(app);
    final n = app.now;
    final today = DateTime(n.year, n.month, n.day);
    if (rows.isEmpty) {
      return YCard(
        radius: 24,
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: EnText('Nothing to report yet. Quiet days are good days.',
              size: 15,
              weight: FontWeight.w700,
              color: YaadainTheme.muted,
              height: 1.35),
        ),
      );
    }
    final kids = <Widget>[];
    var shownYesterday = false;
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final isToday = DateTime(r.at.year, r.at.month, r.at.day) == today;
      if (!isToday && !shownYesterday) {
        shownYesterday = true;
        if (i > 0) kids.add(const Divider(height: 1, color: YaadainTheme.line));
        kids.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: EnText('YESTERDAY',
              size: 12,
              weight: FontWeight.w800,
              color: YaadainTheme.muted,
              letterSpacing: 0.8),
        ));
      } else if (i > 0) {
        kids.add(const Divider(
            height: 1, color: YaadainTheme.line, indent: 16, endIndent: 16));
      }
      kids.add(_RowView(r));
    }
    return YCard(
      radius: 24,
      padding: EdgeInsets.zero,
      child: SizedBox(
          width: double.infinity,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: kids)),
    );
  }
}

class _RowView extends StatelessWidget {
  final _Row r;
  const _RowView(this.r);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
            width: 62,
            child: EnText(r.timeLabel,
                size: 14,
                weight: FontWeight.w800,
                color: YaadainTheme.bodyDim)),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: r.iconBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          // arrowRight turned up-right (the foundation's arrowUpRight path is flipped).
          child: Transform.rotate(
              angle: r.icon == YI.arrowRight ? -0.785398 : 0,
              child:
                  YIcon(r.icon, size: 20, color: r.iconFg, strokeWidth: 2.2)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            EnText(r.title, size: 15, weight: FontWeight.w800, height: 1.25),
            if (r.sub != null)
              EnText(r.sub!,
                  size: 13,
                  weight: FontWeight.w600,
                  color: YaadainTheme.muted,
                  height: 1.3),
          ]),
        ),
        if (r.chip != null) ...[
          const SizedBox(width: 8),
          SafetyPill(r.chip!,
              height: 32,
              bg: r.chipAttention
                  ? YaadainTheme.attentionSoft
                  : YaadainTheme.primarySoft,
              fg: r.chipAttention
                  ? YaadainTheme.accentDark
                  : YaadainTheme.primaryDark),
        ],
      ]),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final AppState app;
  const _WeekRow({required this.app});

  Widget _stat(int n, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            EnText('$n', size: 22, weight: FontWeight.w700, display: true),
            const SizedBox(width: 4),
            EnText(label,
                size: 13, weight: FontWeight.w700, color: YaadainTheme.muted),
          ]);

  @override
  Widget build(BuildContext context) {
    final from = app.now.subtract(const Duration(days: 7));
    final exits = app
        .episodesSince(from)
        .where((e) => e.category == 'zone_exit')
        .toList();
    final outings = exits.where((e) => e.severity < 2).length;
    final alerts = exits.length - outings;
    final nights = app.weeklyStats().nightPickups;
    Widget bar() => Container(
        width: 1,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: YaadainTheme.line);
    return YCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => Navigator.of(context).pushNamed(Routes.careReport),
      child: SizedBox(
        width: double.infinity,
        child: Row(children: [
          EnText('This week', size: 14, weight: FontWeight.w800),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(children: [
                _stat(outings, outings == 1 ? 'outing' : 'outings'),
                bar(),
                _stat(alerts, alerts == 1 ? 'exit' : 'exits'),
                bar(),
                _stat(nights, nights == 1 ? 'night' : 'nights'),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          EnText('Report',
              size: 14,
              weight: FontWeight.w800,
              color: YaadainTheme.primaryDark),
        ]),
      ),
    );
  }
}
