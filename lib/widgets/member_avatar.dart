import 'dart:io';

import 'package:flutter/material.dart';

import '../models/family_member.dart';
import '../models/relationship.dart';
import '../theme.dart';

/// Large, friendly circular portrait. Falls back to the relationship emoji
/// then an initial, so the tree never shows a broken image to the elder.
class MemberAvatar extends StatelessWidget {
  final FamilyMember member;
  final double size;
  final bool showRing;

  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 96,
    this.showRing = true,
  });

  @override
  Widget build(BuildContext context) {
    final rel = relationshipById(member.relationshipId);
    final hasPhoto = member.photoPath != null && File(member.photoPath!).existsSync();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: showRing
            ? Border.all(color: YaadainTheme.primary.withOpacity(0.35), width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.file(File(member.photoPath!), fit: BoxFit.cover)
          : Center(
              child: Text(
                rel?.emoji ?? (member.name.isNotEmpty ? member.name.characters.first : '🧑'),
                style: TextStyle(fontSize: size * 0.42),
              ),
            ),
    );
  }
}
