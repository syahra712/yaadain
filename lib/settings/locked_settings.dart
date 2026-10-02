import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../demo/demo_controls.dart';
import '../design/design.dart';
import '../routes.dart';
import '../state/app_state.dart';

/// Wrap the logo on the elder home with this. Press and hold for 3 seconds
/// to open the PIN prompt (kSettingsPin) and then the English settings.
///
///   ElderLogoGate(child: LogoMark(size: 56))
///
/// A short tap does nothing, so the elder never meets it by accident.
class ElderLogoGate extends StatefulWidget {
  final Widget child;
  final Duration hold;
  const ElderLogoGate(
      {super.key, required this.child, this.hold = const Duration(seconds: 3)});

  @override
  State<ElderLogoGate> createState() => _ElderLogoGateState();
}

class _ElderLogoGateState extends State<ElderLogoGate> {
  Timer? _t;

  void _start() {
    _t?.cancel();
    _t = Timer(widget.hold, () {
      if (mounted) LockedSettings.open(context);
    });
  }

  void _cancel() => _t?.cancel();

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _cancel(),
      onPointerCancel: (_) => _cancel(),
      child: widget.child,
    );
  }
}

class LockedSettings {
  LockedSettings._();

  /// PIN prompt, then the settings screen.
  static Future<void> open(BuildContext context) async {
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const FamilyTheme(child: _PinDialog()),
    );
    if (ok == true) nav.pushNamed(Routes.lockedSettings);
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();
  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  String _pin = '';
  bool _bad = false;

  void _tap(String d) {
    if (_pin.length >= kSettingsPin.length) return;
    setState(() {
      _pin += d;
      _bad = false;
    });
    if (_pin.length == kSettingsPin.length) {
      if (_pin == kSettingsPin) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _pin = '';
          _bad = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, YI? icon}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Material(
              color: YaadainTheme.surface,
              borderRadius: YaadainTheme.radius12,
              child: InkWell(
                borderRadius: YaadainTheme.radius12,
                onTap: onTap ?? () => _tap(label),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: YaadainTheme.radius12,
                      border: Border.all(color: YaadainTheme.line)),
                  child: icon != null
                      ? YIcon(icon, size: 22)
                      : EnText(label, size: 22, weight: FontWeight.w700),
                ),
              ),
            ),
          ),
        );
    Widget row(List<Widget> k) => Row(children: k);
    return Dialog(
      backgroundColor: YaadainTheme.paper,
      shape: const RoundedRectangleBorder(borderRadius: YaadainTheme.radius28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EnText('Caregiver settings',
                size: 22, weight: FontWeight.w600, display: true),
            const SizedBox(height: 4),
            const EnText('Enter the 4-digit PIN',
                size: 14, color: YaadainTheme.muted, weight: FontWeight.w600),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < kSettingsPin.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length
                          ? YaadainTheme.primary
                          : Colors.transparent,
                      border: Border.all(
                          color: _bad
                              ? YaadainTheme.emergency
                              : YaadainTheme.stroke,
                          width: 1.5),
                    ),
                  ),
              ],
            ),
            SizedBox(
              height: 24,
              child: _bad
                  ? const Center(
                      child: EnText('Wrong PIN, try again',
                          size: 13,
                          weight: FontWeight.w700,
                          color: YaadainTheme.emergency))
                  : null,
            ),
            row([key('1'), key('2'), key('3')]),
            row([key('4'), key('5'), key('6')]),
            row([key('7'), key('8'), key('9')]),
            row([
              key('',
                  icon: YI.x, onTap: () => Navigator.of(context).pop(false)),
              key('0'),
              key('',
                  icon: YI.chevronLeft,
                  onTap: () => setState(() => _pin =
                      _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1))),
            ]),
          ],
        ),
      ),
    );
  }
}

/// English settings for the caregiver (reached via the PIN).
class LockedSettingsScreen extends StatelessWidget {
  const LockedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ur = app.settings.elderLanguage != 'en';
    return FamilyScaffold(
      title: 'Settings',
      subtitle: 'Caregiver only',
      showDemo: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          YCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EnText('Language on this phone',
                    size: 18, weight: FontWeight.w600, display: true),
                const SizedBox(height: 4),
                const EnText('Urdu is what the elder sees every day.',
                    size: 14,
                    color: YaadainTheme.muted,
                    weight: FontWeight.w600),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: FamilyButton('Urdu',
                        kind: ur
                            ? FamilyButtonKind.primary
                            : FamilyButtonKind.quiet,
                        expand: true,
                        onTap: () => _setLang(app, 'ur')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FamilyButton('English',
                        kind: !ur
                            ? FamilyButtonKind.primary
                            : FamilyButtonKind.quiet,
                        expand: true,
                        onTap: () => _setLang(app, 'en')),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: YCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EnText('Family code',
                        size: 14,
                        weight: FontWeight.w800,
                        color: YaadainTheme.muted),
                    const SizedBox(height: 4),
                    EnText(
                        app.familyCodeDisplay.isEmpty
                            ? 'Not set'
                            : app.familyCodeDisplay,
                        size: 24,
                        weight: FontWeight.w600,
                        display: true,
                        letterSpacing: 2),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          FamilyButton('Answers about Abu',
              icon: YI.heart,
              kind: FamilyButtonKind.quiet,
              expand: true,
              onTap: () => Navigator.of(context).pushNamed(Routes.careAnswers)),
          const SizedBox(height: 8),
          FamilyButton('Daily routine',
              icon: YI.clock,
              kind: FamilyButtonKind.quiet,
              expand: true,
              onTap: () => Navigator.of(context).pushNamed(Routes.careRoutine)),
          const SizedBox(height: 8),
          FamilyButton('Consent and privacy',
              icon: YI.shield,
              kind: FamilyButtonKind.quiet,
              expand: true,
              onTap: () => Navigator.of(context).pushNamed(Routes.consent)),
          const SizedBox(height: 12),
          FamilyButton('Demo controls',
              icon: YI.shield,
              kind: FamilyButtonKind.primary,
              expand: true,
              onTap: () => DemoControls.open(context)),
          const SizedBox(height: 8),
          FamilyButton('Back to elder phone',
              icon: YI.home,
              kind: FamilyButtonKind.quiet,
              expand: true,
              onTap: () => goRoot(app.initialRoute)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _setLang(AppState app, String code) async {
    app.settings.elderLanguage = code;
    await app.repo.save();
    app.refresh();
  }
}
