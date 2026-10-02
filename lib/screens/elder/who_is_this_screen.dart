import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/demo_seed.dart';
import '../../design/design.dart';
import '../../models/family_member.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import 'widgets/elder_b_widgets.dart';

/// یہ کون ہے؟ A grid of faces without names. Touch one: the banner says who it
/// is and, when a real recording exists, their own voice plays.
class WhoIsThisScreen extends StatefulWidget {
  const WhoIsThisScreen({super.key});

  @override
  State<WhoIsThisScreen> createState() => _WhoIsThisScreenState();
}

class _WhoIsThisScreenState extends State<WhoIsThisScreen> {
  final EbPlayer _player = EbPlayer();
  String? _selected;

  // A fixed, mixed-up order (not seed order, not by closeness) so the grid is
  // never a test of rank. Unknown ids follow in member order.
  static const _rank = [
    DemoIds.bilal,
    DemoIds.ayesha,
    DemoIds.zaid,
    DemoIds.maryam,
    DemoIds.fatima,
    DemoIds.hassan,
    DemoIds.aslam,
    DemoIds.naseem,
    DemoIds.ruqayya,
  ];

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

  List<FamilyMember> _ordered(List<FamilyMember> all) {
    int r(FamilyMember m) {
      final i = _rank.indexOf(m.id);
      return i < 0 ? 100 + all.indexOf(m) : i;
    }

    return List.of(all)..sort((a, b) => r(a).compareTo(r(b)));
  }

  void _select(FamilyMember m) {
    setState(() => _selected = m.id);
    _player.start('who-${m.id}',
        path: m.greetingAudioPath, seconds: 4, minSeconds: 2);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final faces = _ordered(app.members);
    final sel = _selected == null ? null : app.memberById(_selected!);

    return ElderScaffold(
      title: 'یہ کون ہے؟',
      subtitle: 'چہرے کو چھوئیں، آواز سنیں',
      scroll: false,
      bodyPadding: EdgeInsets.zero,
      body: faces.isEmpty
          ? const Center(
              child: EbEmptyNote('ابھی کوئی چہرہ شامل نہیں کیا گیا۔'))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding:
                      EdgeInsets.fromLTRB(24, 12, 24, sel == null ? 32 : 232),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    textDirection: TextDirection.rtl,
                    children: [
                      for (final m in faces)
                        SizedBox(
                          width: (390 - 48 - 12) / 2,
                          child: _FaceTile(
                              member: m,
                              selected: m.id == sel?.id,
                              onTap: () => _select(m)),
                        ),
                    ],
                  ),
                ),
                if (sel != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _Banner(
                      member: sel,
                      player: _player,
                      onReplay: () => _player.start('who-${sel.id}',
                          path: sel.greetingAudioPath, seconds: 4),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _FaceTile extends StatelessWidget {
  final FamilyMember member;
  final bool selected;
  final VoidCallback onTap;
  const _FaceTile(
      {required this.member, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'ایک چہرہ',
      excludeSemantics: true,
      child: Material(
        color: selected ? YaadainTheme.primarySoft : YaadainTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
              color: selected ? YaadainTheme.primary : YaadainTheme.line,
              width: selected ? 3 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 136),
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: EbFace(member, size: 112),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final FamilyMember member;
  final EbPlayer player;
  final VoidCallback onReplay;
  const _Banner(
      {required this.member, required this.player, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    final m = member;
    final String headline;
    if (hasOwnName(m)) {
      headline =
          'یہ ${m.nameUr} ${isJunior(m) ? 'ہے' : 'ہیں'}، ${m.kinshipUrdu}';
    } else {
      headline = 'یہ ${m.kinshipUrdu} ${isJunior(m) ? 'ہے' : 'ہیں'}';
    }
    final line2 = m.isDeceased ? 'ایک پیاری یاد' : callsHimLine(m);
    final playing = player.isPlaying('who-${m.id}');
    final hasVoice = m.hasVoice;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 28 + bottomInset),
      decoration: BoxDecoration(
        color: YaadainTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(top: BorderSide(color: YaadainTheme.line)),
        boxShadow: [
          BoxShadow(
              color: YaadainTheme.ink.withOpacity(0.14),
              blurRadius: 28,
              offset: const Offset(0, -8))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: headline,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.pushNamed(context, Routes.memberDetail,
                  arguments: MemberDetailArgs(m.id)),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  EbFace(m, size: 80),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UrduText(headline, size: 28, height: 1.8),
                        if (line2.isNotEmpty)
                          UrduText(line2,
                              size: 24, height: 1.8, color: YaadainTheme.muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasVoice) ...[
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                SizedBox(
                  width: 80,
                  child: Center(child: _Bars(active: playing)),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: ElderButton('دوبارہ سنیں',
                        icon: YI.volumeMirrored, onTap: onReplay)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Five little bars, lit while a voice plays.
class _Bars extends StatelessWidget {
  final bool active;
  const _Bars({required this.active});

  @override
  Widget build(BuildContext context) {
    const hs = [10.0, 22.0, 14.0, 26.0, 12.0];
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < hs.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: 4,
              height: hs[i],
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: active
                    ? YaadainTheme.primary
                    : YaadainTheme.primary.withOpacity(0.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
