import 'package:flutter/material.dart';

import '../models/family_member.dart';
import '../models/relationship.dart';
import '../theme.dart';
import 'member_avatar.dart';

/// A single person hanging on the family tree: a short "stem" line, the
/// portrait, the name, and the relationship shown as "YOUR ___".
class TreeNode extends StatelessWidget {
  final FamilyMember member;
  final bool roman;
  final VoidCallback onTap;
  final bool hasVoice;

  const TreeNode({
    super.key,
    required this.member,
    required this.roman,
    required this.onTap,
    this.hasVoice = false,
  });

  @override
  Widget build(BuildContext context) {
    final rel = relationshipById(member.relationshipId);
    final relLabel = rel == null ? '' : (roman ? rel.roman : rel.urdu);
    final name = roman ? (member.romanName ?? member.name) : member.name;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 118,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // stem
            Container(width: 3, height: 14, color: YaadainTheme.primary.withOpacity(0.35)),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                MemberAvatar(member: member, size: 84),
                if (hasVoice)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: YaadainTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up, color: Colors.white, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (relLabel.isNotEmpty)
              Text(
                roman ? 'Aap ke/ki $relLabel' : 'آپ کے/کی $relLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: YaadainTheme.primaryDark),
              ),
          ],
        ),
      ),
    );
  }
}
