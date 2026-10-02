import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/care.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import 'widgets/onboarding_parts.dart';

/// Step 3 of 3, the only Urdu screen in onboarding. The phone is in his
/// hands; this is the question put to him. Urdu only, right to left.
class KhayalScreen extends StatefulWidget {
  const KhayalScreen({super.key});

  @override
  State<KhayalScreen> createState() => _KhayalScreenState();
}

class _KhayalScreenState extends State<KhayalScreen> {
  bool _busy = false;

  Future<void> _answer(bool agreed) async {
    if (_busy) return;
    setState(() => _busy = true);
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    final now = app.now;
    final who = app.primaryContact?.firstNameEn;
    try {
      await app.saveConsent(ConsentRecord(
        agreedAt: now,
        presentNames: who == null || who.isEmpty ? const [] : [who],
        statusShared: agreed,
        zonesShared: agreed,
        lastPositionBilalOnly: agreed,
        historyDays: agreed ? 7 : 0,
        askAgainAt: agreed
            ? now.add(const Duration(days: 91))
            : now.add(const Duration(days: 7)),
        hisResponseEn: agreed ? "That's fine" : 'Not now',
        hisResponseUr: agreed ? 'ٹھیک ہے' : 'ابھی نہیں',
      ));
    } catch (_) {
      // The record is best effort; the flow must never stall in his hands.
    }
    if (!mounted) return;
    nav.pushReplacementNamed(Routes.consent);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final carer = app.primaryContact;
    final who = carer?.displayUr ?? 'گھر والے';
    final photo = app.elder.photoPath;
    final mq = MediaQuery.of(context);

    TextStyle ur(double size,
            {Color color = YaadainTheme.ink, FontWeight w = FontWeight.w400}) =>
        YaadainTheme.ur(size, color: color, height: 1.9)
            .copyWith(fontWeight: w);

    return ElderTheme(
      child: Scaffold(
        backgroundColor: YaadainTheme.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 203,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 136,
                            child: ColoredBox(
                                color: YaadainTheme.primaryDark,
                                child: JaaliPattern(opacity: .09)),
                          ),
                          Positioned(
                            top: 53,
                            child: OnbSilhouette(
                              size: 150,
                              photoPath: photo,
                              bg: YaadainTheme.primarySoft,
                              fg: YaadainTheme.primary,
                              ring: YaadainTheme.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                '$who آپ کا\nخیال رکھنا چاہتے ہیں',
                                textAlign: TextAlign.center,
                                style: ur(32, w: FontWeight.w700)
                                    .copyWith(height: 1.95),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _Line(
                                icon: YI.mapPin,
                                text:
                                    'اگر آپ گھر سے دور ہوں تو $who کو پتہ چل جائے گا',
                                style: ur(20)),
                            _Line(
                                icon: YI.lifebuoy,
                                text: 'آپ جب چاہیں ایک بٹن سے مدد بلا سکتے ہیں',
                                style: ur(20)),
                            _Line(
                                icon: YI.users,
                                text: 'صرف گھر والے دیکھ سکتے ہیں',
                                style: ur(20)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20,
                  8 + (mq.padding.bottom > 8 ? mq.padding.bottom - 8 : 0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElderButton('ٹھیک ہے',
                      icon: YI.check,
                      large: true,
                      onTap: _busy ? null : () => _answer(true)),
                  const SizedBox(height: 12),
                  ElderButton.quiet('ابھی نہیں',
                      onTap: _busy ? null : () => _answer(false)),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: UrduText('آپ یہ کبھی بھی بدل سکتے ہیں۔',
                        size: 20,
                        color: YaadainTheme.muted,
                        align: TextAlign.center),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final YI icon;
  final String text;
  final TextStyle style;
  const _Line({required this.icon, required this.text, required this.style});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OnbIconTile(icon, size: 40),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: style)),
          ],
        ),
      );
}
