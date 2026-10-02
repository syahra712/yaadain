import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../util/urdu_format.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import 'widgets/safety_elder_widgets.dart';

/// Help screen. Opening it raises the help flag (the family gets an alert).
/// Two states from tracking: outside the home zone / at home.
class MadadScreen extends StatefulWidget {
  const MadadScreen({super.key});

  @override
  State<MadadScreen> createState() => _MadadScreenState();
}

class _MadadScreenState extends State<MadadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        // Demo/Firestore sources ignore this when an alert is already open.
        unawaited(context.read<AppState>().raiseHelp().catchError((_) {}));
      } catch (_) {}
    });
  }

  static bool isOutside(AppState app) {
    final st = app.elderStatus;
    if (st != null) return !st.inside;
    final a = app.activeAlert;
    return a != null && !a.isResolved && a.kind == 'zone_exit';
  }

  Future<void> _call(BuildContext context, SafetyContacts c) async {
    final m = c.first;
    if (m == null) return;
    final ok = await dialMember(m);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: UrduText('فون نہیں ہو سکا', size: 20, color: Colors.white),
        duration: Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final outside = isOutside(app);
    final contacts = SafetyContacts.of(app);
    final first = contacts.first;
    final address = (app.elder.homeAddressUr ?? '').trim().isNotEmpty &&
            RegExp(r'[؀-ۿ]').hasMatch(app.elder.homeAddressUr!)
        ? UrduFmt.digits(app.elder.homeAddressUr!.trim())
        : urduAddress(app.elder.homeAddress);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final Color cardBg =
        outside ? YaadainTheme.attentionSoft : YaadainTheme.primarySoft;
    final Color cardBorder =
        outside ? const Color(0xFFEBD3BE) : const Color(0xFFC3DBD1);
    final Color iconFg =
        outside ? YaadainTheme.accentDark : YaadainTheme.primaryDark;
    final String headline =
        outside ? 'آپ گھر سے باہر ہیں۔' : 'آپ گھر پر ہیں۔ سب ٹھیک ہے۔';
    final String sub = outside
        ? (first != null
            ? 'گھبرائیں نہیں۔ ${first.displayUr} کو بتا دیا گیا ہے۔'
            : 'گھبرائیں نہیں۔ گھر والوں کو بتا دیا گیا ہے۔')
        : 'ضرورت ہو تو فون کریں۔';

    return ElderTheme(
      child: Scaffold(
        backgroundColor: YaadainTheme.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SafetyHeader(title: 'مدد'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: YaadainTheme.radius28,
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white),
                            alignment: Alignment.center,
                            child: YIcon(outside ? YI.mapPin : YI.home,
                                size: 24, color: iconFg),
                          ),
                          const SizedBox(height: 4),
                          UrduText(headline, size: 36, height: 1.8),
                          UrduText(sub,
                              size: 22,
                              color: YaadainTheme.bodyDim,
                              height: 2.2),
                        ],
                      ),
                    ),
                    if (address != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                        decoration: BoxDecoration(
                          color: YaadainTheme.surface,
                          borderRadius: YaadainTheme.radius20,
                          border: Border.all(color: YaadainTheme.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: YaadainTheme.primarySoft),
                                  alignment: Alignment.center,
                                  child: const YIcon(YI.home,
                                      size: 22,
                                      color: YaadainTheme.primaryDark),
                                ),
                                const SizedBox(width: 12),
                                const UrduText('آپ کا گھر',
                                    size: 20,
                                    color: YaadainTheme.muted,
                                    height: 2.0),
                              ],
                            ),
                            UrduText(address, size: 24, height: 2.2),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 32 + bottomPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (first != null)
                    SafetyButton(
                      label: '${first.displayUr} کو فون کریں',
                      icon: YI.phone,
                      bg: YaadainTheme.accentDark,
                      minHeight: 80,
                      onTap: () => _call(context, contacts),
                    ),
                  if (outside) ...[
                    const SizedBox(height: 12),
                    SafetyButton(
                      label: 'یہ کسی کو دکھائیں',
                      icon: YI.shieldCheck,
                      bg: YaadainTheme.primary,
                      minHeight: 72,
                      onTap: () => Navigator.of(context).pushNamed(
                          Routes.ifFound,
                          arguments: const IfFoundArgs()),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SafetyButton(
                    label: 'میں ٹھیک ہوں',
                    icon: YI.check,
                    bg: YaadainTheme.surface,
                    fg: YaadainTheme.ink,
                    outline: true,
                    minHeight: 64,
                    fontSize: 20,
                    onTap: () => _imFine(context, outside),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _imFine(BuildContext context, bool outside) {
    final nav = Navigator.of(context);
    if (outside) {
      nav.pushNamed(Routes.imSafe);
    } else {
      // At home: close the help request and go back.
      final app = context.read<AppState>();
      unawaited(app.markFound(resolution: 'ok').catchError((_) {}));
      nav.popUntil((r) => r.isFirst);
    }
  }
}
