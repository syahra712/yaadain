import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../routes.dart';
import '../../services/google_auth_service.dart';
import '../../state/app_state.dart';
import 'widgets/onboarding_parts.dart';

/// Family member joins with the code shown on the elder's home screen.
class JoinFamilyScreen extends StatefulWidget {
  final String? code;
  const JoinFamilyScreen({super.key, this.code});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  late final TextEditingController _code;
  final _name = TextEditingController();
  bool _caregiver = false;
  bool _busy = false;
  String? _error;
  String? _email;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: (widget.code ?? '').toUpperCase());
    final saved = context.read<AppState>().settings.contributorName;
    if (saved != null) _name.text = saved;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  /// "yd-7f3k", "7F3K" and "YD 7F3K" all mean the same thing.
  String get _clean {
    var c = _code.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (c.startsWith('YD') && c.length > 4) c = c.substring(2);
    return c;
  }

  bool get _ready =>
      _clean.length >= 4 && _name.text.trim().isNotEmpty && !_busy;

  Future<void> _scan() async {
    final scanned = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const _ScanPage()));
    if (scanned == null || !mounted) return;
    final up = scanned.toUpperCase();
    final m = RegExp(r'(?:YD-)?([A-Z0-9]{4,8})').firstMatch(up);
    setState(() {
      _code.text = m == null
          ? up
          : (up.contains('YD-') ? 'YD-${m.group(1)}' : m.group(1)!);
      _error = null;
    });
  }

  Future<void> _google() async {
    try {
      final r = await GoogleAuthService.signIn();
      if (!mounted) return;
      if (r == null) {
        _say(
            'Google sign-in is not available right now. You can join without it.');
        return;
      }
      setState(() {
        _email = r.email;
        if (_name.text.trim().isEmpty &&
            (r.displayName ?? '').trim().isNotEmpty) {
          _name.text = r.displayName!.trim().split(' ').first;
        }
      });
    } catch (_) {
      if (mounted)
        _say(
            'Google sign-in is not available right now. You can join without it.');
    }
  }

  void _say(String msg) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: EnText(msg, color: Colors.white, weight: FontWeight.w700)));
  }

  Future<void> _join() async {
    if (!_ready) return;
    final app = context.read<AppState>();
    setState(() {
      _busy = true;
      _error = null;
    });
    String? err;
    try {
      err = await app.becomeFamilyDevice(_clean, _name.text,
          email: _email, caregiver: _caregiver);
    } catch (_) {
      err =
          'Could not reach the family just now. Check the code and your connection, then try again.';
    }
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    setState(() => _busy = false);
    // Distress alerts arrive as notifications: ask once (Android 13+), never block.
    try {
      await app.requestNotificationPermission().timeout(const Duration(seconds: 20));
    } catch (_) {}
    if (!mounted) return;
    goRoot(app.initialRoute);
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
            OnbBackBar(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(16, 12, 16, 24 + mq.padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OnbTitle('Join the family',
                        lead:
                            'Ask the person who set up the elder’s phone for the family code. It is shown on their home screen.'),
                    const SizedBox(height: 24),
                    const OnbLabel('Family code'),
                    OnbField(
                      controller: _code,
                      hint: 'YD-7F3K',
                      codeStyle: true,
                      height: 72,
                      highlight: _clean.length >= 4,
                      capitalization: TextCapitalization.characters,
                      textDirection: TextDirection.ltr,
                      semanticsLabel: 'Family code',
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    if (_error != null)
                      OnbHelp(_error!, color: YaadainTheme.accentDark)
                    else
                      const OnbHelp(
                          'Letters and numbers. Capitals don’t matter.'),
                    const SizedBox(height: 16),
                    OnbOutlineButton('Scan the code on his phone',
                        icon: YI.scan, onTap: _scan),
                    const SizedBox(height: 24),
                    const OnbLabel('Your name'),
                    OnbField(
                      controller: _name,
                      hint: 'Your first name',
                      capitalization: TextCapitalization.words,
                      textDirection: TextDirection.ltr,
                      semanticsLabel: 'Your name',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    const OnbLabel('Your part in his care'),
                    OnbChoice(
                      title: 'I live with him and look after him',
                      body:
                          'You set up his phone, zones and routine. You are the first call.',
                      selected: _caregiver,
                      onTap: () => setState(() => _caregiver = true),
                    ),
                    const SizedBox(height: 12),
                    OnbChoice(
                      title: 'I help from anywhere',
                      body:
                          'Record hellos, see how he is, take a shift when asked.',
                      selected: !_caregiver,
                      onTap: () => setState(() => _caregiver = false),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: InkWell(
                        onTap: _google,
                        borderRadius: YaadainTheme.radius12,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: EnText(
                              _email == null
                                  ? 'Continue with Google (optional)'
                                  : 'Signed in as $_email',
                              size: 16,
                              weight: FontWeight.w800,
                              color: YaadainTheme.primary),
                        ),
                      ),
                    ),
                    const EnText(
                        'Keeps your place if you change phones. Not required.',
                        size: 13,
                        weight: FontWeight.w600,
                        color: YaadainTheme.bodyDim,
                        align: TextAlign.center),
                    const SizedBox(height: 24),
                    OnbPrimaryButton('Join',
                        onTap: _ready ? _join : null, busy: _busy),
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

/// Camera page that returns the first QR value it sees.
class _ScanPage extends StatefulWidget {
  const _ScanPage();

  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return FamilyTheme(
      child: Scaffold(
        backgroundColor: YaadainTheme.primaryDark,
        body: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                onDetect: (capture) {
                  if (_done) return;
                  for (final b in capture.barcodes) {
                    final v = b.rawValue;
                    if (v != null && v.trim().isNotEmpty) {
                      _done = true;
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(v.trim());
                      return;
                    }
                  }
                },
                errorBuilder: (context, error, child) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: EnText(
                        'The camera is not available. Type the code instead.',
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        align: TextAlign.center),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 32 + MediaQuery.of(context).padding.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EnText('Point the camera at the code on his phone',
                      size: 15,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      align: TextAlign.center),
                  const SizedBox(height: 12),
                  OnbOutlineButton('Cancel',
                      onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
