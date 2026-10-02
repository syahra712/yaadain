import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../demo/demo_controls.dart';
import '../../design/design.dart';
import '../../models/app_settings.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import 'widgets/onboarding_parts.dart';

/// "Who will use this phone?" Elder phone (set up by a family member) or
/// family member (joins with the code). Long-press the mark for demo controls.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _busy = false;

  Future<void> _elder() async {
    if (_busy) return;
    setState(() => _busy = true);
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    try {
      final code = app.settings.familyCode;
      if (code != null && code.isNotEmpty) {
        // A code already exists (demo family or an earlier try): keep it.
        app.settings
          ..role = DeviceRole.elder
          ..isCaregiver = false;
        await app.repo.save();
        app.refresh();
        app.startBackground();
      } else {
        await app.becomeElderDevice();
      }
    } catch (_) {
      // Offline or no cloud: the phone still becomes the elder's phone.
      app.settings.role = DeviceRole.elder;
      app.refresh();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    nav.pushNamed(Routes.elderPhoneSetup);
  }

  void _family() {
    if (_busy) return;
    Navigator.of(context).pushNamed(Routes.join);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return FamilyTheme(
      child: Scaffold(
        backgroundColor: YaadainTheme.paper,
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, top + 20, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - top - 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onLongPress: () => DemoControls.open(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: YaadainTheme.primaryDark,
                            borderRadius: YaadainTheme.radius12),
                        child: const Center(child: LogoMark(size: 28)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const EnText('Yaadain',
                        size: 20, weight: FontWeight.w700, display: true),
                  ],
                ),
                const SizedBox(height: 61),
                const OnbTitle('Who will use this phone?',
                    lead:
                        'Yaadain lives on two kinds of phones. Choose the one you are holding right now.'),
                const SizedBox(height: 34),
                _RoleCard(
                  icon: YI.smartphone,
                  tileBg: YaadainTheme.primary,
                  tileFg: Colors.white,
                  title: 'This is the elder’s phone',
                  body:
                      'Set it up for him in Urdu or Roman Urdu. He never has to configure anything.',
                  onTap: _elder,
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: YI.users,
                  tileBg: YaadainTheme.primarySoft,
                  tileFg: YaadainTheme.primary,
                  title: 'I’m a family member',
                  body:
                      'Join with the family code to help, record a hello and stay informed.',
                  onTap: _family,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: YaadainTheme.line, height: 1)),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: YaadainTheme.accent),
                    ),
                    const Expanded(
                        child: Divider(color: YaadainTheme.line, height: 1)),
                  ],
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: EnText(
                      'The elder’s phone is set up by a family member, then handed to him.',
                      size: 14,
                      weight: FontWeight.w600,
                      color: YaadainTheme.bodyDim,
                      align: TextAlign.center,
                      height: 1.45),
                ),
                const SizedBox(height: 72),
                const EnText('You can change this later in Settings.',
                    size: 14,
                    weight: FontWeight.w700,
                    color: YaadainTheme.bodyDim,
                    align: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final YI icon;
  final Color tileBg;
  final Color tileFg;
  final String title;
  final String body;
  final VoidCallback onTap;
  const _RoleCard(
      {required this.icon,
      required this.tileBg,
      required this.tileFg,
      required this.title,
      required this.body,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $body',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: YaadainTheme.radius28,
          boxShadow: [
            BoxShadow(
                color: YaadainTheme.ink.withOpacity(.07),
                blurRadius: 24,
                offset: const Offset(0, 6))
          ],
        ),
        child: Material(
          color: YaadainTheme.surface,
          borderRadius: YaadainTheme.radius28,
          child: InkWell(
            borderRadius: YaadainTheme.radius28,
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: YaadainTheme.radius28,
                  border: Border.all(color: YaadainTheme.line)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  OnbIconTile(icon, bg: tileBg, fg: tileFg, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EnText(title,
                            size: 20,
                            weight: FontWeight.w700,
                            display: true,
                            height: 1.2),
                        const SizedBox(height: 8),
                        EnText(body,
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: YaadainTheme.muted,
                            height: 1.45),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const YIcon(YI.chevronRight,
                      size: 20, color: YaadainTheme.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
