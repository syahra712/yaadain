import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/episode_log.dart';
import '../../models/family_member.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import 'widgets/elder_a_parts.dart';

/// Sukoon (calm): reassurance and soothing audio for a frightened moment.
/// Opening it is logged as a calm episode. Tracks without a recording are a
/// quiet visual state only; nothing is ever synthesised.
class SukoonScreen extends StatefulWidget {
  const SukoonScreen({super.key});

  @override
  State<SukoonScreen> createState() => _SukoonScreenState();
}

class _Track {
  final String title;
  final String? path;
  const _Track(this.title, this.path);
}

class _SukoonScreenState extends State<SukoonScreen> {
  int _sel = 0;
  bool _playing = true;
  late AppState _app;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _app.logEpisode(Episode(category: 'calm', at: _app.now));
    });
  }

  @override
  void dispose() {
    try {
      Svc.audio.stop();
    } catch (_) {}
    super.dispose();
  }

  FamilyMember? _voiceMember(AppState app) {
    for (final m in app.members) {
      if (!m.isDeceased && m.hasVoice) return m;
    }
    return null;
  }

  Future<void> _select(int i, _Track t) async {
    try {
      await Svc.audio.stop();
    } catch (_) {}
    setState(() {
      _sel = i;
      _playing = true;
    });
    final p = t.path;
    if (p != null && p.isNotEmpty) {
      try {
        await Svc.audio.play(p);
      } catch (_) {}
    }
  }

  Future<void> _toggle(_Track t) async {
    final next = !_playing;
    setState(() => _playing = next);
    try {
      if (!next) {
        await Svc.audio.stop();
      } else if (t.path != null && t.path!.isNotEmpty) {
        await Svc.audio.play(t.path!);
      }
    } catch (_) {}
  }

  Future<void> _call(AppState app) async {
    final p = app.primaryContact;
    final messenger = ScaffoldMessenger.of(context);
    if (p == null || (p.phone ?? '').isEmpty) {
      messenger.showSnackBar(const SnackBar(content: UrduText('ابھی کوئی نمبر محفوظ نہیں۔', size: 20, color: Colors.white)));
      return;
    }
    try {
      await Svc.launcher.call(p.phone!);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final voice = _voiceMember(app);
    final tracks = [
      const _Track('سورۂ رحمٰن', null),
      _Track(voice == null ? 'گھر والوں کی آواز' : '${voice.displayUr} کی آواز', voice?.greetingAudioPath),
      const _Track('نعت', null),
    ];
    final p = app.primaryContact;
    final callLabel = p == null ? 'گھر والوں کو فون کریں' : '${p.displayUr} کو فون کریں';
    final safe = app.elderStatus?.inside ?? true;

    return ElderScaffold(
      title: 'سکون',
      scroll: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const EldArtView(EldArt.homeScene),
          const SizedBox(height: 12),
          UrduText(safe ? 'آپ محفوظ ہیں۔ آپ گھر پر ہیں۔' : 'آپ محفوظ ہیں۔', size: 28, height: 1.8, align: TextAlign.center),
          const UrduText('آپ کا خاندان آپ سے پیار کرتا ہے۔',
              size: 24, color: YaadainTheme.muted, height: 1.8, align: TextAlign.center),
          const SizedBox(height: 20),
          for (var i = 0; i < tracks.length; i++) ...[
            _TrackRow(track: tracks[i], selected: i == _sel && _playing, onTap: () => _select(i, tracks[i])),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          Center(
            child: Semantics(
              button: true,
              label: _playing ? 'روکیں' : 'چلائیں',
              excludeSemantics: true,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(side: BorderSide(color: YaadainTheme.primary, width: 2)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _toggle(tracks[_sel]),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Center(
                      child: EldIcon(_playing ? EldPaths.pause : EldPaths.play, size: 32, color: YaadainTheme.primary, fill: true),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottom: EldBtn(
        callLabel,
        bg: YaadainTheme.accentDark,
        fg: Colors.white,
        height: 72,
        size: 24,
        shadow: true,
        icon: EldIcon(EldPaths.phone, size: 24, color: Colors.white),
        onTap: () => _call(app),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final _Track track;
  final bool selected;
  final VoidCallback onTap;
  const _TrackRow({required this.track, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : YaadainTheme.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: track.title,
      excludeSemantics: true,
      child: Material(
        color: selected ? YaadainTheme.primary : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: selected ? BorderSide.none : const BorderSide(color: YaadainTheme.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  EldIcon(EldPaths.speaker, size: 24, color: selected ? Colors.white : YaadainTheme.primary, fillFirst: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: UrduText(track.title, size: 24, color: fg, height: 1.8, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  if (selected)
                    const _Bars()
                  else
                    EldIcon(EldPaths.play, size: 22, color: YaadainTheme.primary, fill: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) {
    const hs = [10.0, 20.0, 14.0, 24.0, 12.0];
    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final h in hs)
            Container(
              width: 4,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
            ),
        ],
      ),
    );
  }
}
