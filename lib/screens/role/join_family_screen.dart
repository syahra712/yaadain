import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/google_auth_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

/// Family device: enter the 6-char code the elder's device shows, plus your
/// name, to start contributing to that family.
class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;
  bool _signingIn = false;
  String? _error;
  String? _googleEmail;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    final result = await GoogleAuthService.signIn();
    if (!mounted) return;
    setState(() {
      _signingIn = false;
      if (result != null) {
        _googleEmail = result.email;
        if (_name.text.trim().isEmpty && (result.displayName ?? '').isNotEmpty) {
          _name.text = result.displayName!;
        }
      } else {
        _error = 'Google sign-in wasn\'t completed. You can still join with just your name.';
      }
    });
  }

  Future<void> _join() async {
    final code = _code.text.trim();
    final name = _name.text.trim();
    if (code.length < 4 || name.isEmpty) {
      setState(() => _error = 'Enter the family code and your name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await context.read<AppState>().becomeFamilyDevice(code, name, email: _googleEmail);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).popUntil((r) => r.isFirst); // Boot routes to family home
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join your family')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: YaadainTheme.leafRule.withOpacity(0.5), width: 1.4),
                      ),
                      child: const Icon(Icons.family_restroom_outlined, size: 28, color: YaadainTheme.accentDark),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ask your family for the 6-letter code shown on the elder’s phone '
                      '(Family setup → Invite family).',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: YaadainTheme.foxed, height: 1.5),
                    ),
                    const SizedBox(height: 22),
                    if (_googleEmail == null)
                      OutlinedButton.icon(
                        onPressed: _signingIn ? null : _signInWithGoogle,
                        icon: _signingIn
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.g_mobiledata, size: 26),
                        label: const Text('Sign in with Google (optional, more secure)'),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: YaadainTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: YaadainTheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 18, color: YaadainTheme.primaryDark),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Signed in as $_googleEmail',
                                  style: const TextStyle(fontSize: 13, color: YaadainTheme.primaryDark)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        UpperCaseFormatter(),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Family code',
                        hintText: 'ABC123',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: 'Your name',
                        hintText: 'How the elder knows you — e.g. Fatima',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: YaadainTheme.danger)),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _busy ? null : _join,
                        style: FilledButton.styleFrom(
                          backgroundColor: YaadainTheme.accentDark,
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Join family', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Forces typed text to uppercase for the code field.
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
