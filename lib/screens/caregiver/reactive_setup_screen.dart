import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/voice_recorder.dart';

/// Caregiver setup for the reactive companion: turn on ambient listening,
/// record the REAL calming clip Yaadain plays when confusion is heard, and
/// choose whose familiar face appears with it.
class ReactiveSetupScreen extends StatefulWidget {
  const ReactiveSetupScreen({super.key});

  @override
  State<ReactiveSetupScreen> createState() => _ReactiveSetupScreenState();
}

class _ReactiveSetupScreenState extends State<ReactiveSetupScreen> {
  String? _pendingClipPath;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final elder = app.elder;
    final members = app.members;

    return Scaffold(
      appBar: AppBar(title: const Text('Reactive companion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: YaadainTheme.primary.withOpacity(0.06),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'When Yaadain hears the elder sound confused or distressed — repeating '
                '“who is this?”, “where am I?”, or saying they’re scared — it gently plays '
                'a calming clip you record here, in a real family member’s voice. It never '
                'invents speech, and it stays quiet unless it’s fairly sure.',
                style: TextStyle(height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ambient listening', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Listen on the elder’s device and respond to confusion'),
            value: elder.listeningEnabled,
            onChanged: (v) {
              elder.listeningEnabled = v;
              context.read<AppState>().saveElder();
            },
          ),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Calming clip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'e.g. “Abba, aap ghar par hain, sab theek hai — main aapki beti Fatima hoon, '
            'main aa rahi hoon.”',
            style: TextStyle(color: YaadainTheme.muted),
          ),
          const SizedBox(height: 10),
          VoiceRecorder(
            initialPath: elder.reassuranceAudioPath,
            hint: 'Record a warm, calming reassurance for the elder.',
            onRecorded: (p) => _pendingClipPath = p,
          ),
          const SizedBox(height: 20),
          const Text('Whose face to show', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: elder.reassuranceMemberId,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('The elder / no face')),
              ...members.map((m) => DropdownMenuItem<String?>(value: m.id, child: Text(m.name))),
            ],
            onChanged: (v) {
              elder.reassuranceMemberId = v;
              context.read<AppState>().saveElder();
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: YaadainTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () async {
              final appState = context.read<AppState>();
              if (_pendingClipPath != null) {
                elder.reassuranceAudioPath = await appState.repo.ensureStored(_pendingClipPath);
              }
              await appState.saveElder();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Save', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
