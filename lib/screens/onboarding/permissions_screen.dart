import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import 'widgets/onboarding_parts.dart';

/// Step 2 of 3: the three Android permissions, each in plain words, then the
/// hand-over to the elder.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _location = false;
  bool _mic = false;
  bool _notif = false;
  String? _busy;
  String? _denied;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    try {
      final ok = await Svc.location.hasPermission();
      if (mounted && ok) setState(() => _location = true);
    } catch (_) {}
  }

  Future<void> _ask(String which) async {
    if (_busy != null) return;
    final app = context.read<AppState>();
    setState(() {
      _busy = which;
      _denied = null;
    });
    var ok = false;
    try {
      ok = switch (which) {
        'location' => await app.requestLocationPermission(),
        'mic' => await app.requestMicPermission(),
        _ => await app.requestNotificationPermission(),
      };
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = null;
      switch (which) {
        case 'location':
          _location = ok;
        case 'mic':
          _mic = ok;
        default:
          _notif = ok;
      }
      if (!ok) {
        _denied =
            'Not allowed yet. You can allow it later in Android settings; the app keeps working without it.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return FamilyTheme(
      child: Scaffold(
        backgroundColor: YaadainTheme.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnbStepHeader(
                step: 2, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OnbTitle('What his phone needs',
                        lead:
                            'Android asks three times. Here is what each one is for, in plain words.'),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: YaadainTheme.surface,
                        borderRadius: YaadainTheme.radius20,
                        border: Border.all(color: YaadainTheme.line),
                      ),
                      child: Column(
                        children: [
                          _PermRow(
                            icon: YI.mapPin,
                            title: 'Location',
                            body:
                                'To know when he is away from home and to show him the way back.',
                            allowed: _location,
                            busy: _busy == 'location',
                            onAllow: () => _ask('location'),
                          ),
                          const Divider(height: 1, color: YaadainTheme.line),
                          _PermRow(
                            icon: YI.mic,
                            title: 'Microphone',
                            body:
                                'So you can record answers and hellos on this phone.',
                            allowed: _mic,
                            busy: _busy == 'mic',
                            onAllow: () => _ask('mic'),
                          ),
                          const Divider(height: 1, color: YaadainTheme.line),
                          _PermRow(
                            icon: YI.bell,
                            title: 'Notifications',
                            body: 'For medicine and meal prompts.',
                            allowed: _notif,
                            busy: _busy == 'notif',
                            clay: true,
                            onAllow: () => _ask('notif'),
                          ),
                        ],
                      ),
                    ),
                    if (_denied != null)
                      OnbHelp(_denied!, color: YaadainTheme.accentDark),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: YaadainTheme.surface.withOpacity(.55),
                        borderRadius: YaadainTheme.radius20,
                        border: Border.all(color: YaadainTheme.line),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: YIcon(YI.eye,
                                  size: 20, color: YaadainTheme.primaryDark)),
                          SizedBox(width: 12),
                          Expanded(
                            child: EnText(
                                'Nothing is shared until he agrees on the next screen. Location stays on this phone; the family sees only what he allows.',
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: YaadainTheme.ink,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OnbDarkPanel(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(.3)),
                                ),
                                child: const Center(
                                    child: YIcon(YI.smartphone,
                                        size: 30, color: Colors.white)),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    EnText('Now hand the phone to him',
                                        size: 24,
                                        weight: FontWeight.w700,
                                        display: true,
                                        color: Colors.white,
                                        height: 1.15),
                                    SizedBox(height: 8),
                                    EnText(
                                        'The next screen is in Urdu and speaks to him. Sit beside him while he reads it; it is his decision to make.',
                                        size: 14,
                                        weight: FontWeight.w600,
                                        color: Color(0xE6FFFFFF),
                                        height: 1.4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(
                              height: 1, color: Colors.white.withOpacity(.2)),
                          const SizedBox(height: 14),
                          const Row(
                            children: [
                              YIcon(YI.checkCircle,
                                  size: 18, color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(
                                child: EnText(
                                    'Two buttons, no scrolling, nothing to configure.',
                                    size: 13.5,
                                    weight: FontWeight.w800,
                                    color: Colors.white),
                              ),
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
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + mq.padding.bottom),
              child: OnbPrimaryButton('Continue',
                  onTap: () => Navigator.of(context).pushNamed(Routes.khayal)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final YI icon;
  final String title;
  final String body;
  final bool allowed;
  final bool busy;
  final bool clay;
  final VoidCallback onAllow;
  const _PermRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.allowed,
    required this.busy,
    required this.onAllow,
    this.clay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          OnbIconTile(icon,
              size: 48,
              bg: clay ? YaadainTheme.attentionSoft : YaadainTheme.primarySoft,
              fg: clay ? YaadainTheme.accentDark : YaadainTheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EnText(title,
                    size: 17,
                    weight: FontWeight.w700,
                    display: true,
                    height: 1.2),
                const SizedBox(height: 4),
                EnText(body,
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: YaadainTheme.muted,
                    height: 1.4),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (allowed)
            const StatusChip('Allowed', tone: ChipTone.success, icon: YI.check)
          else
            Semantics(
              button: true,
              label: 'Allow $title',
              child: Material(
                color: YaadainTheme.primary,
                borderRadius: YaadainTheme.radius12,
                child: InkWell(
                  borderRadius: YaadainTheme.radius12,
                  onTap: busy ? null : onAllow,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 80, minHeight: 48),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const EnText('Allow',
                            size: 15,
                            weight: FontWeight.w800,
                            color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
