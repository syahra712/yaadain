import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/elder_profile.dart';
import '../../models/family_member.dart';
import '../../models/relationship.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/elder_scaffold.dart';
import '../../widgets/ui.dart';
import 'member_detail_screen.dart';

/// The family register — a printed keepsake page, not a diagram.
///
/// The elder sits as a bookplate portrait at the head of the page; each
/// generation follows as its own quiet chapter, set on a real grid with a
/// gold hairline rule and small-caps captions. Nothing moves, nothing glows —
/// the warmth comes from the photographs and the type, the way a family
/// album earns it. The whole thing simply scrolls, so it never crowds no
/// matter how large the family grows.
class FamilyTreeScreen extends StatelessWidget {
  const FamilyTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roman = app.roman;
    final members = app.members;

    final byGen = <int, List<FamilyMember>>{};
    for (final m in members) {
      byGen.putIfAbsent(generationOfRelationship(m.relationshipId), () => []).add(m);
    }
    final levels = byGen.keys.toList()..sort((a, b) => a.compareTo(b)); // -1..+2

    return ElderScaffold(
      title: roman ? 'Mera khandan' : 'میرا خاندان',
      roman: roman,
      accent: YaadainTheme.foxed,
      child: members.isEmpty
          ? _EmptyState(roman: roman)
          : Container(
              color: YaadainTheme.paper,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 28, 0, 48),
                children: [
                  _Frontispiece(elder: app.elder, roman: roman, count: members.length),
                  const SizedBox(height: 30),
                  for (final level in levels) ...[
                    _Chapter(
                      level: level,
                      members: byGen[level]!,
                      roman: roman,
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// The frontispiece — the elder's own page, at the head of the record.
// ---------------------------------------------------------------------------

class _Frontispiece extends StatelessWidget {
  final ElderProfile elder;
  final bool roman;
  final int count;
  const _Frontispiece({required this.elder, required this.roman, required this.count});

  @override
  Widget build(BuildContext context) {
    final name = roman ? (elder.romanName ?? elder.name) : elder.name;
    return Column(
      children: [
        _Medallion(
          photoPath: elder.photoPath,
          fallbackText: name.isNotEmpty ? name.characters.first : '🌿',
          size: 128,
          ringWidth: 3,
          ring: YaadainTheme.leafRule,
        ),
        const SizedBox(height: 14),
        Text(
          name.isEmpty ? (roman ? 'Aap ka khandan' : 'آپ کا خاندان') : name,
          textAlign: TextAlign.center,
          style: YaadainTheme.serif(30, w: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          roman
              ? '$count log is khandan mein'
              : 'اس خاندان میں $count افراد',
          style: TextStyle(fontSize: 14, color: YaadainTheme.foxed, letterSpacing: 0.3),
        ),
        const SizedBox(height: 18),
        const _GoldRule(width: 84),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// A generation, presented as a chapter of the record.
// ---------------------------------------------------------------------------

class _Chapter extends StatelessWidget {
  final int level;
  final List<FamilyMember> members;
  final bool roman;
  const _Chapter({required this.level, required this.members, required this.roman});

  ({String urdu, String roman}) get _label {
    switch (level) {
      case -1:
        return (urdu: 'آپ کے بزرگ', roman: 'Aap ke buzurg');
      case 1:
        return (urdu: 'آپ کی اولاد', roman: 'Aap ki aulad');
      case 2:
        return (urdu: 'پوتے، نواسے', roman: 'Pote, nawase');
      default:
        return (urdu: 'آپ کے ہم عمر', roman: 'Aap ke ham-umar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lab = _label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Center(
            child: Text(
              (roman ? lab.roman : lab.urdu).toUpperCase(),
              textAlign: TextAlign.center,
              style: YaadainTheme.eyebrow(),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: _MemberGrid(members: members, roman: roman),
        ),
      ],
    );
  }
}

/// A real 3-column grid — every medallion the same size, evenly gapped, so
/// the page reads as composed rather than scattered.
class _MemberGrid extends StatelessWidget {
  final List<FamilyMember> members;
  final bool roman;
  const _MemberGrid({required this.members, required this.roman});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const cols = 3;
        const gap = 14.0;
        final cell = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: 22,
          children: [
            for (final m in members)
              SizedBox(
                width: cell,
                child: _EntryCard(member: m, roman: roman),
              ),
          ],
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  final FamilyMember member;
  final bool roman;
  const _EntryCard({required this.member, required this.roman});

  @override
  Widget build(BuildContext context) {
    final rel = relationshipById(member.relationshipId);
    final relLabel = rel == null ? '' : (roman ? rel.roman : rel.urdu);
    final name = roman ? (member.romanName ?? member.name) : member.name;
    final deceased = member.isDeceased;
    final hasVoice = member.greetingAudioPath != null;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MemberDetailScreen(memberId: member.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _Medallion(
                  photoPath: member.photoPath,
                  fallbackText: rel?.emoji ?? (member.name.isNotEmpty ? member.name.characters.first : '🧑'),
                  size: 78,
                  ring: deceased ? YaadainTheme.sepia : YaadainTheme.leafRule,
                  ringWidth: deceased ? 2 : 2.4,
                  desaturate: deceased,
                ),
                if (hasVoice)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: YaadainTheme.paper,
                        shape: BoxShape.circle,
                        border: Border.all(color: YaadainTheme.leafRule, width: 1.2),
                      ),
                      child: const Icon(Icons.volume_up, size: 11, color: YaadainTheme.primaryDark),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: YaadainTheme.serif(15.5, w: FontWeight.w600, h: 1.2),
            ),
            if (relLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  relLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: deceased ? YaadainTheme.sepia : YaadainTheme.foxed,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

/// A circular portrait set like a locket — thin ring, soft paper backing.
/// Falls back to an emoji/initial so nothing ever shows a broken frame.
class _Medallion extends StatelessWidget {
  final String? photoPath;
  final String fallbackText;
  final double size;
  final Color ring;
  final double ringWidth;
  final bool desaturate;
  const _Medallion({
    required this.photoPath,
    required this.fallbackText,
    required this.size,
    required this.ring,
    this.ringWidth = 2.4,
    this.desaturate = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    Widget img = hasPhoto
        ? Image.file(File(photoPath!), fit: BoxFit.cover)
        : Center(
            child: Text(fallbackText, style: TextStyle(fontSize: size * 0.4)),
          );
    if (desaturate && hasPhoto) {
      img = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.35, 0.45, 0.20, 0, 0, //
          0.35, 0.45, 0.20, 0, 0, //
          0.35, 0.45, 0.20, 0, 0, //
          0, 0, 0, 1, 0,
        ]),
        child: img,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: YaadainTheme.surface,
        border: Border.all(color: ring, width: ringWidth),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: img,
    );
  }
}

class _GoldRule extends StatelessWidget {
  final double width;
  const _GoldRule({this.width = 60});
  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: 1.4,
        color: YaadainTheme.leafRule.withOpacity(0.55),
      );
}

class _EmptyState extends StatelessWidget {
  final bool roman;
  const _EmptyState({required this.roman});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      emoji: '🌳',
      title: roman ? 'Aap ka shajra abhi khali hai' : 'آپ کا شجرہ ابھی خالی ہے',
      subtitle: roman
          ? 'Ghar wale “Family setup” mein ja kar apne pyaron ko shamil karein.'
          : 'ترتیبات میں جا کر اپنے پیاروں کو شامل کریں۔',
    );
  }
}
