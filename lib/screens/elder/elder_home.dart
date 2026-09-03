import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../models/episode_log.dart';
import '../../models/family_member.dart';
import '../../models/memory_story.dart';
import '../../services/confusion_detector.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../caregiver/caregiver_home.dart';
import 'family_tree_screen.dart';
import 'flashbacks_screen.dart';
import 'im_safe_screen.dart';
import 'member_detail_screen.dart';
import 'reassurance_screen.dart';
import 'who_is_this_screen.dart';

/// The elder's front door — read like the opening page of a keepsake book,
/// not a menu of app tiles. A photograph, a greeting set in serif type, one
/// real memory for today, and a quiet path into the family record. Underneath
/// sits the invisible reactive layer: when confusion is heard, Yaadain
/// responds on its own. A small, unobtrusive door to the caregiver setup
/// sits in the corner (long-press to open).
class ElderHome extends StatefulWidget {
  const ElderHome({super.key});

  @override
  State<ElderHome> createState() => _ElderHomeState();
}

class _ElderHomeState extends State<ElderHome> {
  final ConfusionDetector _detector = ConfusionDetector();
  StreamSubscription<ConfusionEvent>? _sub;
  bool _responding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartListening());
  }

  Future<void> _maybeStartListening() async {
    final app = context.read<AppState>();
    if (!app.elder.listeningEnabled) return;
    final ok = await _detector.init();
    if (!ok) return;
    _sub = _detector.events.listen(_onConfusion);
    await _detector.start();
    if (mounted) setState(() {});
  }

  Future<void> _onConfusion(ConfusionEvent e) async {
    if (_responding || !mounted) return;
    _responding = true;
    // Log the episode for the caregiver's private report (no transcript stored).
    final app = context.read<AppState>();
    app.logEpisode(Episode(category: e.category, severity: e.severity, at: e.at));
    await _detector.stop(); // don't listen while reassuring
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReassuranceScreen(category: e.category)),
      );
    }
    _responding = false;
    if (mounted && context.read<AppState>().elder.listeningEnabled) {
      await _detector.start();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = S(app.roman);
    final roman = app.roman;
    final elderName =
        roman ? (app.elder.romanName ?? app.elder.name) : app.elder.name;
    final listening = app.elder.listeningEnabled && _detector.isEnabled;
    final members = app.members;

    return Scaffold(
      backgroundColor: YaadainTheme.paper,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                _Frontispiece(
                  roman: roman,
                  name: elderName,
                  photoPath: app.elder.photoPath,
                  listening: listening,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 22, 26, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MemoryOfDay(roman: roman, members: members),
                      _VoiceNudge(roman: roman, members: members),
                      const SizedBox(height: 6),
                      _TreeCta(
                        roman: roman,
                        label: s.myFamily,
                        count: members.length,
                        onTap: () => _go(context, const FamilyTreeScreen()),
                      ),
                      const SizedBox(height: 26),
                      _RuleRow(
                        left: _QuietLink(
                          label: roman ? 'Yaadein' : 'یادیں',
                          icon: Icons.auto_stories_outlined,
                          onTap: () => _go(context, const FlashbacksScreen()),
                        ),
                        right: _QuietLink(
                          label: s.whoIsThis,
                          icon: Icons.person_search_outlined,
                          onTap: () => _go(context, const WhoIsThisScreen()),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SafeButton(
                        roman: roman,
                        label: s.imSafe,
                        onTap: () => _go(context, const ImSafeScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Script toggle + hidden caregiver door, floating over the banner.
            Positioned(
              top: 4,
              right: 6,
              child: Row(
                children: [
                  _GlassButton(
                    label: roman ? 'اردو' : 'Roman',
                    onTap: () => context.read<AppState>().toggleScript(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onLongPress: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CaregiverHome()),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.32),
                        ),
                        child: const Icon(Icons.settings, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

// ---------------------------------------------------------------------------
// The frontispiece — a photograph banner with the greeting set into it,
// like the opening plate of a keepsake book.
// ---------------------------------------------------------------------------

class _Frontispiece extends StatelessWidget {
  final bool roman;
  final String name;
  final String? photoPath;
  final bool listening;
  const _Frontispiece({
    required this.roman,
    required this.name,
    required this.photoPath,
    required this.listening,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    final hour = DateTime.now().hour;
    final partOfDay = hour < 12
        ? (roman ? 'Subah bakhair' : 'صبح بخیر')
        : hour < 17
            ? (roman ? 'Achhi dopahar' : 'اچھی دوپہر')
            : (roman ? 'Sham bakhair' : 'شام بخیر');

    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPhoto)
            Image.file(File(photoPath!), fit: BoxFit.cover)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [YaadainTheme.primarySoft, YaadainTheme.paperShade],
                ),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name.characters.first : '🌿',
                  style: YaadainTheme.serif(88, w: FontWeight.w600, color: YaadainTheme.primaryDark.withOpacity(0.35)),
                ),
              ),
            ),
          // Legibility scrim, darkest at the foot where the type sits.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black38, Colors.black87],
                stops: [0.35, 0.75, 1.0],
              ),
            ),
          ),
          if (listening)
            Positioned(
              top: 14,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.32),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hearing, size: 14, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(roman ? 'Sun raha hai' : 'سن رہا ہے',
                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 26,
            right: 26,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partOfDay,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: Colors.white.withOpacity(0.78),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name.isEmpty ? (roman ? 'Assalam-o-alaikum' : 'السلام علیکم') : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: YaadainTheme.serif(34, w: FontWeight.w600, color: Colors.white, h: 1.15),
                ),
                if (name.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      roman ? 'Assalam-o-alaikum' : 'السلام علیکم',
                      style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.85)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Today's memory" — a real recorded memory, chosen by the calendar day so
// the same one holds all day and gently rotates over time.
// ---------------------------------------------------------------------------

class _MemoryOfDay extends StatelessWidget {
  final bool roman;
  final List<FamilyMember> members;
  const _MemoryOfDay({required this.roman, required this.members});

  @override
  Widget build(BuildContext context) {
    final picks = <_StoryRef>[];
    for (final m in members) {
      for (final st in m.stories) {
        if (st.title.trim().isNotEmpty) picks.add(_StoryRef(m, st));
      }
    }
    if (picks.isEmpty) return const SizedBox.shrink();

    final doy = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final ref = picks[doy % picks.length];
    final who = roman ? (ref.member.romanName ?? ref.member.name) : ref.member.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MemberDetailScreen(memberId: ref.member.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              roman ? 'AAJ KI YAAD' : 'آج کی یاد',
              style: YaadainTheme.eyebrow(),
            ),
            const SizedBox(height: 8),
            Text(
              ref.story.title,
              style: YaadainTheme.serif(22, w: FontWeight.w600, h: 1.3),
            ),
            if (who.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  roman ? '— $who ke saath' : '— $who کے ساتھ',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontStyle: FontStyle.italic,
                    color: YaadainTheme.foxed,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoryRef {
  final FamilyMember member;
  final MemoryStory story;
  _StoryRef(this.member, this.story);
}

// ---------------------------------------------------------------------------
// A quiet nudge to hear one loved one's voice today.
// ---------------------------------------------------------------------------

class _VoiceNudge extends StatelessWidget {
  final bool roman;
  final List<FamilyMember> members;
  const _VoiceNudge({required this.roman, required this.members});

  @override
  Widget build(BuildContext context) {
    final voiced = members.where((m) => m.greetingAudioPath != null).toList();
    if (voiced.isEmpty) return const SizedBox.shrink();

    final doy = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final m = voiced[doy % voiced.length];
    final who = roman ? (m.romanName ?? m.name) : m.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MemberDetailScreen(memberId: m.id)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: YaadainTheme.leafRule, width: 1.4),
              ),
              child: const Icon(Icons.volume_up_outlined, size: 19, color: YaadainTheme.primaryDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                roman ? '$who ki awaaz suniye' : '$who کی آواز سنیے',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: YaadainTheme.ink,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: YaadainTheme.foxed, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The living-record call to action — restrained, not a neon gradient tile.
// ---------------------------------------------------------------------------

class _TreeCta extends StatelessWidget {
  final bool roman;
  final String label;
  final int count;
  final VoidCallback onTap;
  const _TreeCta({
    required this.roman,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YaadainTheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: YaadainTheme.leafRule.withOpacity(0.45)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: YaadainTheme.leafRule.withOpacity(0.6)),
                ),
                child: const Text('🌳', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: YaadainTheme.serif(21, w: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      count == 0
                          ? (roman ? 'Apne pyaron ko yahan dekhein' : 'اپنے پیاروں کو یہاں دیکھیں')
                          : (roman ? '$count log' : '$count افراد'),
                      style: const TextStyle(fontSize: 13.5, color: YaadainTheme.foxed),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: YaadainTheme.foxed),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Secondary links + safe button
// ---------------------------------------------------------------------------

class _RuleRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _RuleRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: YaadainTheme.line),
          bottom: BorderSide(color: YaadainTheme.line),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: left),
          Container(width: 1, height: 56, color: YaadainTheme.line),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _QuietLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuietLink({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: YaadainTheme.primaryDark),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: YaadainTheme.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafeButton extends StatelessWidget {
  final bool roman;
  final String label;
  final VoidCallback onTap;
  const _SafeButton({required this.roman, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: YaadainTheme.accentDark.withOpacity(0.5)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border_rounded, color: YaadainTheme.accentDark, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: YaadainTheme.accentDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GlassButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black.withOpacity(0.28),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
