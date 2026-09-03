import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/relationship.dart';
import '../../services/audio_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/elder_scaffold.dart';
import '../../widgets/member_avatar.dart';

class MemberDetailScreen extends StatefulWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final _audio = AudioService.instance;
  String? _playing; // path currently playing

  @override
  void initState() {
    super.initState();
    _audio.playerState.listen((_) {
      if (mounted && _audio.currentlyPlaying == null) {
        setState(() => _playing = null);
      }
    });
  }

  Future<void> _toggle(String path) async {
    if (_playing == path) {
      await _audio.stop();
      setState(() => _playing = null);
    } else {
      await _audio.play(path);
      setState(() => _playing = path);
    }
  }

  @override
  void dispose() {
    _audio.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roman = app.roman;
    final m = app.memberById(widget.memberId);
    if (m == null) {
      return const Scaffold(body: Center(child: Text('—')));
    }
    final rel = relationshipById(m.relationshipId);
    final relLabel = rel == null ? '' : (roman ? rel.roman : rel.urdu);
    final name = roman ? (m.romanName ?? m.name) : m.name;

    return ElderScaffold(
      title: name,
      roman: roman,
      accent: YaadainTheme.foxed,
      child: Container(
        color: YaadainTheme.paper,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Center(
              child: Container(
                width: 172,
                height: 172,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YaadainTheme.surface,
                  border: Border.all(color: YaadainTheme.leafRule, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 5)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: MemberAvatar(member: m, size: 166, showRing: false),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(name,
                  textAlign: TextAlign.center,
                  style: YaadainTheme.serif(30, w: FontWeight.w600)),
            ),
            const SizedBox(height: 5),
            Center(
              child: Text(
                relLabel,
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: YaadainTheme.foxed),
              ),
            ),
            if (m.isDeceased) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  // Gentle, never a blunt correction. We do NOT announce a death
                  // to the elder; we only soften the framing of the memory.
                  roman ? 'Ek pyari yaad' : 'ایک پیاری یاد',
                  style: const TextStyle(fontSize: 14, color: YaadainTheme.sepia),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Center(child: _Rule()),
            const SizedBox(height: 24),

          // The core voice moment.
          if (m.greetingAudioPath != null && File(m.greetingAudioPath!).existsSync())
            _VoiceButton(
              label: roman ? '$name ki awaaz suniye' : '$name کی آواز سنیے',
              playing: _playing == m.greetingAudioPath,
              onTap: () => _toggle(m.greetingAudioPath!),
            )
          else
            _MutedNote(
              text: roman
                  ? 'Abhi in ki awaaz record nahi hui.'
                  : 'ابھی اِن کی آواز ریکارڈ نہیں ہوئی۔',
            ),

            if (m.stories.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                roman ? 'Un ki baatein' : 'اُن کی باتیں',
                style: YaadainTheme.serif(21, w: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...m.stories.map((st) {
                final has = st.audioPath != null && File(st.audioPath!).existsSync();
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: YaadainTheme.accent,
                      child: Icon(
                        _playing == st.audioPath ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    title: Text(st.title, style: const TextStyle(fontSize: 19)),
                    enabled: has,
                    onTap: has ? () => _toggle(st.audioPath!) : null,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  final String label;
  final bool playing;
  final VoidCallback onTap;
  const _VoiceButton({required this.label, required this.playing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YaadainTheme.primary,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(playing ? Icons.stop_circle : Icons.volume_up,
                  color: Colors.white, size: 40),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();
  @override
  Widget build(BuildContext context) =>
      Container(width: 64, height: 1.4, color: YaadainTheme.leafRule.withOpacity(0.5));
}

class _MutedNote extends StatelessWidget {
  final String text;
  const _MutedNote({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: YaadainTheme.muted)),
      );
}
