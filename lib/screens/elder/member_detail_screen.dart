import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/family_member.dart';
import '../../models/memory_story.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import 'widgets/elder_b_widgets.dart';

/// ایک رشتہ دار: face, name, how they address Dada Jaan, their voice, their
/// stories, and one calm clay call button.
class MemberDetailScreen extends StatefulWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final EbPlayer _player = EbPlayer();

  @override
  void initState() {
    super.initState();
    _player.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _name(FamilyMember m) => hasOwnName(m) ? m.nameUr : m.kinshipUrdu;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final m = app.memberById(widget.memberId);
    if (m == null) {
      return const ElderScaffold(
        body: Center(child: EbEmptyNote('یہ نام اب موجود نہیں۔')),
      );
    }
    final name = _name(m);
    final calls = m.isDeceased ? 'ایک پیاری یاد' : callsHimLine(m);
    final stories = m.stories;
    final canCall = !m.isDeceased && (m.phone ?? '').trim().isNotEmpty;
    final voicePlaying = _player.isPlaying('hello');

    return ElderScaffold(
      bodyPadding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      bottom: canCall
          ? ElderButton.care('$name کو فون کریں', icon: YI.phone, large: true,
              onTap: () {
              try {
                Svc.launcher.call(m.phone!);
              } catch (_) {}
            })
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: EbFace(m, size: 160, badge: m.hasVoice)),
          const SizedBox(height: 12),
          UrduText(name, size: 40, height: 1.8, align: TextAlign.center),
          if (hasOwnName(m))
            UrduText(m.kinshipUrdu,
                size: 28,
                height: 1.8,
                color: YaadainTheme.muted,
                align: TextAlign.center),
          if (calls.isNotEmpty)
            UrduText(calls, size: 24, height: 1.8, align: TextAlign.center),
          if (m.hasVoice) ...[
            const SizedBox(height: 12),
            ElderButton(
              '$name کی آواز سنیے',
              icon: voicePlaying ? YI.pause : YI.volumeMirrored,
              large: true,
              onTap: () => voicePlaying
                  ? _player.stop()
                  : _player.start('hello',
                      path: m.greetingAudioPath, seconds: 4, minSeconds: 2),
            ),
          ],
          if (stories.isNotEmpty) ...[
            const SizedBox(height: 28),
            EbSectionTitle('$name کی باتیں'),
            const SizedBox(height: 12),
            for (final s in stories) ...[
              _StoryRow(
                story: s,
                tint: m.avatarTint,
                playing: _player.isPlaying('s-${s.id}'),
                onPlay: () => _player.isPlaying('s-${s.id}')
                    ? _player.stop()
                    : _player.start('s-${s.id}', path: s.audioPath, seconds: 5),
              ),
              const SizedBox(height: 12),
            ],
          ] else if (!m.hasVoice && calls.isEmpty) ...[
            const SizedBox(height: 28),
            const EbEmptyNote('ابھی یہاں کچھ نہیں ہے۔'),
          ],
        ],
      ),
    );
  }
}

class _StoryRow extends StatelessWidget {
  final MemoryStory story;
  final AvatarTint tint;
  final bool playing;
  final VoidCallback onPlay;
  const _StoryRow(
      {required this.story,
      required this.tint,
      required this.playing,
      required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final title = hasUrduScript(story.title) ? story.title : 'ایک یاد';
    final hasAudio = (story.audioPath ?? '').isNotEmpty;
    final photo = story.photoPath;
    Widget thumb;
    if (photo != null && photo.isNotEmpty && File(photo).existsSync()) {
      thumb = Image.file(File(photo),
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _ph());
    } else {
      thumb = _ph();
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YaadainTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YaadainTheme.line),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: thumb),
          const SizedBox(width: 14),
          Expanded(child: UrduText(title, size: 24, height: 1.8)),
          if (hasAudio) ...[
            const SizedBox(width: 12),
            EbPlayCircle(playing: playing, onTap: onPlay, label: 'سنیے'),
          ],
        ],
      ),
    );
  }

  Widget _ph() => Container(
        width: 64,
        height: 64,
        color: tint.bg,
        alignment: Alignment.center,
        child: YIcon(YI.image, size: 28, color: tint.fg),
      );
}
