import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/care.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import '../../util/en_format.dart';
import 'widgets/onboarding_parts.dart';

/// Step 3 of 3, back in the family member's hands: what he agreed to, kept
/// for the family, and what to do next (set up your own phone).
class ConsentRecordScreen extends StatelessWidget {
  const ConsentRecordScreen({super.key});

  void _say(BuildContext context, String msg) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: EnText(msg, color: Colors.white, weight: FontWeight.w700)));
  }

  Future<void> _copy(BuildContext context, String code) async {
    try {
      await Clipboard.setData(ClipboardData(text: code));
      if (context.mounted) _say(context, 'Family code copied.');
    } catch (_) {}
  }

  Future<void> _share(BuildContext context, String code) async {
    final text = 'Join our family on Yaadain with the code $code.';
    var opened = false;
    try {
      opened = await Svc.launcher.sms('', body: text);
    } catch (_) {}
    if (!opened) {
      try {
        await Clipboard.setData(ClipboardData(text: text));
      } catch (_) {}
      if (context.mounted)
        _say(context, 'Message copied. Paste it into any chat.');
    }
  }

  Future<void> _done(BuildContext context) async {
    final app = context.read<AppState>();
    try {
      await app.completeOnboarding();
    } catch (_) {}
    goRoot(app.initialRoute);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final mq = MediaQuery.of(context);
    final c = app.consent;
    final code = app.familyCodeDisplay;
    return FamilyTheme(
      child: Scaffold(
        backgroundColor: YaadainTheme.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OnbStepHeader(step: 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OnbTitle('Consent recorded',
                        lead:
                            'Take the phone back. This is what he agreed to, kept for the family.'),
                    const SizedBox(height: 20),
                    if (c == null)
                      _Missing(
                          onAsk: () => Navigator.of(context)
                              .pushReplacementNamed(Routes.khayal))
                    else
                      _Recorded(app: app, c: c),
                    const SizedBox(height: 16),
                    if (c != null)
                      OnbOutlineButton('Ask him again',
                          icon: YI.refresh,
                          onTap: () => Navigator.of(context)
                              .pushReplacementNamed(Routes.khayal)),
                    const SizedBox(height: 16),
                    OnbDarkPanel(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EnText('NEXT',
                              size: 11,
                              weight: FontWeight.w800,
                              color: Color(0xB3FFFFFF),
                              letterSpacing: 1.2),
                          const SizedBox(height: 6),
                          const EnText('Set up your own phone',
                              size: 22,
                              weight: FontWeight.w700,
                              display: true,
                              color: Colors.white,
                              height: 1.2),
                          const SizedBox(height: 8),
                          const EnText(
                              'Install Yaadain on your phone and join with the family code. Choose “I live with him and look after him”.',
                              size: 14,
                              weight: FontWeight.w600,
                              color: Color(0xE6FFFFFF),
                              height: 1.4),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 56,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.1),
                                    borderRadius: YaadainTheme.radius12,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(.25)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const EnText('FAMILY CODE',
                                          size: 10,
                                          weight: FontWeight.w800,
                                          color: Color(0xB3FFFFFF),
                                          letterSpacing: 1,
                                          height: 1.1),
                                      EnText(code.isEmpty ? '—' : code,
                                          size: 22,
                                          weight: FontWeight.w700,
                                          display: true,
                                          color: Colors.white,
                                          height: 1.2,
                                          letterSpacing: 2),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _SquareButton(
                                  icon: YI.copy,
                                  label: 'Copy family code',
                                  filled: false,
                                  onTap: code.isEmpty
                                      ? null
                                      : () => _copy(context, code)),
                              const SizedBox(width: 8),
                              _SquareButton(
                                  icon: YI.share,
                                  label: 'Share family code',
                                  filled: true,
                                  onTap: code.isEmpty
                                      ? null
                                      : () => _share(context, code)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + mq.padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OnbPrimaryButton('Done', onTap: () => _done(context)),
                  const SizedBox(height: 10),
                  const EnText(
                      'The phone is now his. His home screen opens next.',
                      size: 13,
                      weight: FontWeight.w600,
                      color: YaadainTheme.bodyDim,
                      align: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Recorded extends StatelessWidget {
  final AppState app;
  final ConsentRecord c;
  const _Recorded({required this.app, required this.c});

  @override
  Widget build(BuildContext context) {
    final agreed = c.statusShared || c.zonesShared;
    final carer = app.primaryContact?.firstNameEn;
    final present =
        c.presentNames.isEmpty ? 'Not recorded' : c.presentNames.join('\n');
    final shared = agreed
        ? (c.statusShared && c.zonesShared ? 'Family' : 'Part of it')
        : 'Not shared';
    final last = !agreed
        ? 'Not shared'
        : (c.lastPositionBilalOnly ? '${carer ?? 'Caregiver'} only' : 'Family');
    final history =
        !agreed || c.historyDays <= 0 ? 'None' : '${c.historyDays} days';
    final response = c.hisResponseEn.isEmpty ? "That's fine" : c.hisResponseEn;
    final when =
        '${EnFmt.weekday(c.agreedAt)} ${EnFmt.date(c.agreedAt)}\n${EnFmt.time(c.agreedAt).replaceAll('AM', 'am').replaceAll('PM', 'pm')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: YaadainTheme.primarySoft,
            borderRadius: YaadainTheme.radius20,
            border: Border.all(color: YaadainTheme.primary.withOpacity(.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: agreed
                            ? YaadainTheme.primary
                            : YaadainTheme.stroke),
                    child: Center(
                        child: YIcon(agreed ? YI.check : YI.clock,
                            size: 26, color: Colors.white, strokeWidth: 3)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EnText(
                            agreed
                                ? '${app.elderNameEn} agreed'
                                : '${app.elderNameEn} said not now',
                            size: 22,
                            weight: FontWeight.w700,
                            display: true,
                            color: YaadainTheme.primaryDark,
                            height: 1.2),
                        const SizedBox(height: 2),
                        EnText('He chose “$response”',
                            size: 14,
                            weight: FontWeight.w700,
                            color: YaadainTheme.primaryDark),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: YaadainTheme.primary.withOpacity(.2)),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _Fact('WHEN', when)),
                  Expanded(flex: 4, child: _Fact('PRESENT', present)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const OnbLabel('What is shared'),
        Container(
          decoration: BoxDecoration(
            color: YaadainTheme.surface,
            borderRadius: YaadainTheme.radius20,
            border: Border.all(color: YaadainTheme.line),
          ),
          child: Column(
            children: [
              _ShareRow(YI.mapPin, 'Status and zones', shared),
              const Divider(height: 1, color: YaadainTheme.line),
              _ShareRow(YI.crosshair, 'Last position', last),
              const Divider(height: 1, color: YaadainTheme.line),
              _ShareRow(YI.history, 'History kept', history),
              const Divider(height: 1, color: YaadainTheme.line),
              _ShareRow(
                  YI.calendar, 'Ask him again on', EnFmt.date(c.askAgainAt)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: EdgeInsets.only(top: 1),
                child:
                    YIcon(YI.eye, size: 18, color: YaadainTheme.primaryDark)),
            SizedBox(width: 10),
            Expanded(
              child: EnText(
                  'He can see on his phone how often you looked today. Nothing here is hidden from him.',
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: YaadainTheme.bodyDim,
                  height: 1.4),
            ),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  const _Fact(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnText(label,
              size: 11,
              weight: FontWeight.w800,
              color: YaadainTheme.primaryDark,
              letterSpacing: 1.1),
          const SizedBox(height: 4),
          EnText(value, size: 15, weight: FontWeight.w700, height: 1.4),
        ],
      );
}

class _ShareRow extends StatelessWidget {
  final YI icon;
  final String label;
  final String value;
  const _ShareRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            OnbIconTile(icon, size: 36),
            const SizedBox(width: 14),
            Expanded(child: EnText(label, size: 15, weight: FontWeight.w700)),
            const SizedBox(width: 8),
            EnText(value, size: 15, weight: FontWeight.w800),
          ],
        ),
      );
}

class _Missing extends StatelessWidget {
  final VoidCallback onAsk;
  const _Missing({required this.onAsk});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: YaadainTheme.surface,
          borderRadius: YaadainTheme.radius20,
          border: Border.all(color: YaadainTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EnText('No agreement is recorded yet',
                size: 20, weight: FontWeight.w700, display: true, height: 1.2),
            const SizedBox(height: 8),
            const EnText(
                'Nothing is shared with the family until he says yes on his own phone.',
                size: 14,
                weight: FontWeight.w600,
                color: YaadainTheme.bodyDim,
                height: 1.4),
            const SizedBox(height: 16),
            OnbOutlineButton('Ask him now', icon: YI.refresh, onTap: onAsk),
          ],
        ),
      );
}

class _SquareButton extends StatelessWidget {
  final YI icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;
  const _SquareButton(
      {required this.icon,
      required this.label,
      required this.filled,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: filled ? YaadainTheme.surface : Colors.white.withOpacity(.1),
          borderRadius: YaadainTheme.radius12,
          child: InkWell(
            borderRadius: YaadainTheme.radius12,
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: YaadainTheme.radius12,
                border: filled
                    ? null
                    : Border.all(color: Colors.white.withOpacity(.25)),
              ),
              child: Center(
                  child: YIcon(icon,
                      size: 22,
                      color: filled ? YaadainTheme.primaryDark : Colors.white)),
            ),
          ),
        ),
      );
}
