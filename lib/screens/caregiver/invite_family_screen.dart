import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../state/app_state.dart';
import '../../theme.dart';

/// Elder-device screen: shows the family code (and a QR of it) for relatives to
/// join and contribute from their own phones. Also lets the caregiver lock
/// joining down to specific Google accounts instead of "anyone with the code".
class InviteFamilyScreen extends StatefulWidget {
  const InviteFamilyScreen({super.key});

  @override
  State<InviteFamilyScreen> createState() => _InviteFamilyScreenState();
}

class _InviteFamilyScreenState extends State<InviteFamilyScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _addEmail(AppState app) {
    final e = _email.text.trim().toLowerCase();
    if (e.isEmpty || !e.contains('@')) return;
    final list = [...app.authorizedEmails];
    if (!list.contains(e)) list.add(e);
    app.setAuthorizedEmails(list);
    _email.clear();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final code = app.settings.familyCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Invite family')),
      body: code == null
          ? const Center(child: Text('No family code yet.'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Share this code with family members. On their own phone they '
                  'open Yaadain, choose “I’m a family member”, and enter it — then '
                  'they can add photos and record voices for the elder.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: YaadainTheme.muted),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    decoration: BoxDecoration(
                      color: YaadainTheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: YaadainTheme.primary.withOpacity(0.25)),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 10,
                        color: YaadainTheme.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy code'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: QrImageView(data: 'YAADAIN:$code', size: 180),
                  ),
                ),
                const SizedBox(height: 12),
                if (!app.sync.isConnected)
                  const Text(
                    'Note: cloud sync is not connected yet, so contributions from '
                    'other phones will start flowing once Firebase is linked.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: YaadainTheme.muted),
                  ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Approved Google accounts (optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  app.authorizedEmails.isEmpty
                      ? 'Currently open: anyone with the code above can join. Add an email '
                          'below to restrict joining to specific Google accounts only.'
                      : 'Only these Google accounts may join with the code — everyone else '
                          'will be turned away, even with the right code.',
                  style: const TextStyle(fontSize: 13, color: YaadainTheme.muted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Family member\'s Google email',
                          hintText: 'fatima@gmail.com',
                        ),
                        onSubmitted: (_) => _addEmail(app),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(onPressed: () => _addEmail(app), icon: const Icon(Icons.add)),
                  ],
                ),
                const SizedBox(height: 10),
                for (final e in app.authorizedEmails)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.verified_user_outlined, size: 20),
                    title: Text(e, style: const TextStyle(fontSize: 14)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => app.setAuthorizedEmails(
                        app.authorizedEmails.where((x) => x != e).toList(),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
