import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/care.dart';
import '../../models/family_member.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import '../../tracking/tracking_source.dart';
import '../../util/en_format.dart';
import 'widgets/safety_family_common.dart';
import 'widgets/safety_family_radar.dart';

/// The alert a family member lands on: where he is, who is coming, what to do.
class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({super.key});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  bool _sending = false;

  Future<void> _onMyWay(AppState app) async {
    setState(() => _sending = true);
    try {
      await app.imOnMyWay();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _call(BuildContext context, String? phone, String who) async {
    if (phone == null || phone.trim().isEmpty) {
      safetyToast(context, 'No phone number saved for $who.');
      return;
    }
    final ok = await Svc.launcher.call(EnFmt.telDigits(phone));
    if (!ok && context.mounted)
      safetyToast(context, 'Could not open the dialer.');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final alert = app.activeAlert;
    if (alert == null || alert.isResolved) return _NoAlert(app: app);

    final help = alert.kind == 'help';
    final name = whoName(app);
    final status = app.elderStatus;
    final dist = status?.distanceM ?? alert.distanceM;
    final bearing = status?.bearingDeg ?? alert.bearingDeg;
    final battery = status?.battery ?? alert.battery;
    final chain = _chain(app);
    final next = chain.isEmpty ? null : chain.first;
    final me = app.settings.contributorMemberId;
    final iAmComing = alert.isAcknowledged && alert.etaMin != null;
    final tone = help ? YaadainTheme.emergency : YaadainTheme.accentDark;
    final soft = help ? YaadainTheme.emergencySoft : YaadainTheme.attentionSoft;
    final sub = StringBuffer(tLower(alert.raisedAt));
    if (alert.unusualReason != null && alert.unusualReason!.isNotEmpty) {
      sub.write(
          ' · ${alert.unusualReason!.substring(0, 1).toLowerCase()}${alert.unusualReason!.substring(1)}');
    }

    return FamilyScaffold(
      title: 'Alert',
      actions: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
              color: YaadainTheme.surface,
              borderRadius: YaadainTheme.radiusPill,
              border: Border.all(color: YaadainTheme.line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const YIcon(YI.clock,
                size: 18, color: YaadainTheme.ink, strokeWidth: 2.4),
            const SizedBox(width: 6),
            EnText(tLower(alert.raisedAt),
                size: 15, weight: FontWeight.w800, height: 1.0),
          ]),
        ),
      ],
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: tone.withOpacity(0.12))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: YIcon(YI.alertTriangle,
                  size: 24, color: tone, strokeWidth: 2.2),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnText(
                        help
                            ? '$name pressed Help'
                            : '$name left the home zone',
                        size: 24,
                        weight: FontWeight.w700,
                        display: true,
                        color: tone,
                        height: 1.15),
                    const SizedBox(height: 8),
                    EnText(sub.toString(),
                        size: 14,
                        weight: FontWeight.w800,
                        color: tone,
                        height: 1.35),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        YCard(
          radius: 28,
          padding: EdgeInsets.zero,
          child: Column(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: SafetyRadar(
                geometry: RadarGeometry.large,
                homeRadiusM: app.homePoint.radiusM,
                distanceM: dist,
                bearingDeg: bearing,
                outside: true,
                places: radarPlaces(app),
                landmark: demoLandmark(app, status ?? _asStatus(alert, app)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: YIcon(YI.mapPin,
                                  size: 18,
                                  color: YaadainTheme.accentDark,
                                  strokeWidth: 2.4),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: EnText(
                                  _where(app, dist, bearing, status, alert),
                                  size: 16,
                                  weight: FontWeight.w800,
                                  height: 1.3),
                            ),
                          ]),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: StatusMeta(
                            battery: battery,
                            updatedAt: status?.at ?? alert.raisedAt,
                            now: app.now),
                      ),
                    ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        _AckCard(app: app, alert: alert, chain: chain),
        const SizedBox(height: 16),
        SafetyButton.care(
          iAmComing
              ? 'On your way, ${EnFmt.duration(alert.etaMin!)}'
              : "I'm on my way",
          icon: iAmComing ? YI.check : YI.send,
          onTap: (_sending || iAmComing) ? null : () => _onMyWay(app),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: SafetyButton.primary('Call $name',
                  icon: YI.phone,
                  onTap: () => _call(context, elderPhone(app), name))),
          const SizedBox(width: 10),
          Expanded(
            child: SafetyButton.quiet(
              next == null ? 'Call Bilal' : 'Call ${next.$1.firstNameEn}',
              icon: YI.phone,
              onTap: () {
                final m = next?.$1 ?? app.primaryContact;
                _call(context, m?.phone, m?.firstNameEn ?? 'them');
              },
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _Escalation(alert: alert, chain: chain, now: app.now, me: me),
        const SizedBox(height: 12),
        SafetyButton.clayOutline("I can't find him",
            icon: YI.alertTriangle,
            onTap: () => Navigator.of(context).pushNamed(Routes.careFind)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: EnText(
              '“I’m on my way” tells his phone you are coming and plays your voice.',
              size: 13,
              weight: FontWeight.w600,
              color: YaadainTheme.muted,
              align: TextAlign.center,
              height: 1.4),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  ElderStatus _asStatus(ActiveAlert a, AppState app) => ElderStatus(
      lat: 0,
      lng: 0,
      at: a.raisedAt,
      battery: a.battery,
      inside: false,
      distanceM: a.distanceM,
      bearingDeg: a.bearingDeg);

  String _where(AppState app, double dist, double bearing, ElderStatus? status,
      ActiveAlert alert) {
    final s = status ?? _asStatus(alert, app);
    final shaped = ElderStatus(
        lat: s.lat,
        lng: s.lng,
        at: s.at,
        battery: s.battery,
        inside: false,
        distanceM: dist,
        bearingDeg: bearing);
    return locationSentence(app, shaped);
  }

  /// Escalation chain after the first caller: (member, entry) by order.
  List<(FamilyMember, CircleMember)> _chain(AppState app) {
    final entries = app.circle.where((c) => c.escalationOrder < 99).toList()
      ..sort((a, b) => a.escalationOrder.compareTo(b.escalationOrder));
    final out = <(FamilyMember, CircleMember)>[];
    final me = app.settings.contributorMemberId;
    for (final c in entries) {
      final m = app.memberById(c.memberId);
      if (m == null || m.isDeceased) continue;
      if (c.escalationOrder == 0 || c.memberId == me) continue;
      out.add((m, c));
    }
    return out;
  }
}

class _AckCard extends StatelessWidget {
  final AppState app;
  final ActiveAlert alert;
  final List<(FamilyMember, CircleMember)> chain;
  const _AckCard({required this.app, required this.alert, required this.chain});

  @override
  Widget build(BuildContext context) {
    final people = <FamilyMember>[];
    final first = app.circle
        .where((c) => c.escalationOrder == 0)
        .map((c) => app.memberById(c.memberId))
        .whereType<FamilyMember>();
    people.addAll(first);
    people.addAll(chain.map((e) => e.$1));
    final shown = people.take(3).toList();
    final value = alert.isAcknowledged
        ? '${alert.ackBy}${alert.ackAt != null ? ' at ${tLower(alert.ackAt!)}' : ''}'
        : 'Nobody yet';
    return YCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EnText('ACKNOWLEDGED BY',
                  size: 12,
                  weight: FontWeight.w800,
                  color: YaadainTheme.muted,
                  letterSpacing: 0.8),
              const SizedBox(height: 4),
              EnText(value, size: 17, weight: FontWeight.w800, height: 1.25),
            ]),
          ),
          if (shown.isNotEmpty)
            SizedBox(
              width: 40.0 + (shown.length - 1) * 28,
              height: 44,
              child: Stack(children: [
                for (var i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * 28.0,
                    child: Opacity(
                      opacity: alert.ackBy != null &&
                              alert.ackBy == shown[i].firstNameEn
                          ? 1
                          : 0.45,
                      child: Avatar.member(shown[i], size: 44),
                    ),
                  ),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _Escalation extends StatelessWidget {
  final ActiveAlert alert;
  final List<(FamilyMember, CircleMember)> chain;
  final DateTime now;
  final String? me;
  const _Escalation(
      {required this.alert,
      required this.chain,
      required this.now,
      required this.me});

  @override
  Widget build(BuildContext context) {
    String text;
    if (alert.isAcknowledged) {
      text = alert.etaMin != null
          ? '${alert.ackBy} is on the way, about ${EnFmt.duration(alert.etaMin!)}'
          : '${alert.ackBy} has seen this';
    } else if (chain.isEmpty) {
      text = 'No one else is set to be called. Add people in Circle.';
    } else {
      final elapsed = now.difference(alert.raisedAt).inMinutes;
      final left = (chain.first.$2.escalateAfterMin - elapsed).clamp(0, 999);
      text = 'Escalates to ${chain.first.$1.firstNameEn} in $left min';
      if (chain.length > 1) text += ', then ${chain[1].$1.firstNameEn}';
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const YIcon(YI.clock,
          size: 16, color: YaadainTheme.muted, strokeWidth: 2.4),
      const SizedBox(width: 8),
      Flexible(
          child: EnText(text,
              size: 14,
              weight: FontWeight.w700,
              color: YaadainTheme.muted,
              align: TextAlign.center)),
    ]);
  }
}

/// No active alert: calm state with the last one, if any.
class _NoAlert extends StatelessWidget {
  final AppState app;
  const _NoAlert({required this.app});

  @override
  Widget build(BuildContext context) {
    final name = whoName(app);
    final last = app.alertHistory.isEmpty ? null : app.alertHistory.first;
    return FamilyScaffold(
      title: 'Alert',
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: YaadainTheme.primarySoft,
              borderRadius: BorderRadius.circular(28)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const YIcon(YI.shieldCheck,
                  size: 24, color: YaadainTheme.primaryDark, strokeWidth: 2.2),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnText('No alert right now',
                        size: 24,
                        weight: FontWeight.w700,
                        display: true,
                        color: YaadainTheme.primaryDark,
                        height: 1.15),
                    const SizedBox(height: 8),
                    EnText(
                        '$name is within his safe zones. You will be told here the moment that changes.',
                        size: 14,
                        weight: FontWeight.w700,
                        color: YaadainTheme.primaryDark,
                        height: 1.35),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (last != null)
          YCard(
            radius: 20,
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnText('LAST ALERT',
                        size: 12,
                        weight: FontWeight.w800,
                        color: YaadainTheme.muted,
                        letterSpacing: 0.8),
                    const SizedBox(height: 6),
                    EnText(
                        '${last.kind == 'help' ? 'Help pressed' : 'Left the home zone'} · ${EnFmt.relative(last.at, app.now)}',
                        size: 17,
                        weight: FontWeight.w800,
                        height: 1.25),
                    const SizedBox(height: 4),
                    EnText(
                        '${EnFmt.distance(last.distanceM)} ${bearingWords(last.bearingDeg)} of home'
                        '${last.ackBy != null ? ' · ${last.ackBy} responded' : ''}'
                        '${last.resolution == 'returned' ? ' · back home' : last.resolution == 'found' ? ' · found' : ''}',
                        size: 14,
                        weight: FontWeight.w600,
                        color: YaadainTheme.muted,
                        height: 1.35),
                  ]),
            ),
          ),
        const SizedBox(height: 16),
        SafetyButton.clayOutline("I can't find him",
            icon: YI.alertTriangle,
            onTap: () => Navigator.of(context).pushNamed(Routes.careFind)),
      ]),
    );
  }
}
