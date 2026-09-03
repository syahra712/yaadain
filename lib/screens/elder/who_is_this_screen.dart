import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../models/family_member.dart';
import '../../models/relationship.dart';
import '../../services/audio_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/elder_scaffold.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/ui.dart';

/// Fast recognition helper for the everyday moment: "someone is here and I
/// don't know who." Tapping a face immediately speaks their voice and shows
/// big "YOUR ___, <name>" text. No menus, no detail screen to get lost in.
class WhoIsThisScreen extends StatefulWidget {
  const WhoIsThisScreen({super.key});

  @override
  State<WhoIsThisScreen> createState() => _WhoIsThisScreenState();
}

class _WhoIsThisScreenState extends State<WhoIsThisScreen> {
  final _audio = AudioService.instance;
  String? _selectedId;

  @override
  void dispose() {
    _audio.stop();
    super.dispose();
  }

  Future<void> _pick(FamilyMember m) async {
    setState(() => _selectedId = m.id);
    if (m.greetingAudioPath != null) {
      await _audio.play(m.greetingAudioPath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = S(app.roman);
    final roman = app.roman;
    final members = app.members;
    final selected =
        _selectedId == null ? null : app.memberById(_selectedId!);

    return ElderScaffold(
      title: s.whoIsThis,
      roman: roman,
      accent: YaadainTheme.primaryDark,
      child: Column(
        children: [
          if (selected != null) _Banner(member: selected, roman: roman),
          Expanded(
            child: members.isEmpty
                ? EmptyState(
                    emoji: '👥',
                    title: roman ? 'Abhi koi shamil nahi' : 'ابھی کوئی شامل نہیں',
                    subtitle: roman ? 'Ghar wale khandan add karein.' : 'گھر والے خاندان شامل کریں۔',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      final m = members[i];
                      final name = roman ? (m.romanName ?? m.name) : m.name;
                      final sel = _selectedId == m.id;
                      return InkWell(
                        onTap: () => _pick(m),
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: sel ? YaadainTheme.primaryDark : YaadainTheme.leafRule.withOpacity(0.5),
                                  width: sel ? 3 : 2,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: MemberAvatar(member: m, size: 76, showRing: false),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: YaadainTheme.serif(15, w: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final FamilyMember member;
  final bool roman;
  const _Banner({required this.member, required this.roman});

  @override
  Widget build(BuildContext context) {
    final rel = relationshipById(member.relationshipId);
    final relLabel = rel == null ? '' : (roman ? rel.roman : rel.urdu);
    final name = roman ? (member.romanName ?? member.name) : member.name;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: YaadainTheme.surface,
        border: Border(bottom: BorderSide(color: YaadainTheme.leafRule.withOpacity(0.3))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        children: [
          Text(
            (roman ? 'Yeh aap ke/ki $relLabel hain' : 'یہ آپ کے/کی $relLabel ہیں').toUpperCase(),
            style: YaadainTheme.eyebrow(),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: YaadainTheme.serif(30, w: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
