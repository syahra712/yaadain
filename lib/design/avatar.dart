import 'dart:io';

import 'package:flutter/material.dart';

import '../models/family_member.dart';
import '../theme.dart';

/// Tinted monogram avatar. Photo shows when [photoPath] exists on disk, else
/// the monogram; a broken photo never throws. [memorial] draws the 3px white
/// then 6px sepia ring.
class Avatar extends StatelessWidget {
  final String monogram;
  final double size;
  final AvatarTint tint;
  final String? photoPath;
  final bool memorial;
  final bool urdu;

  const Avatar({
    super.key,
    required this.monogram,
    this.size = 48,
    this.tint = YaadainTheme.tintTeal,
    this.photoPath,
    this.memorial = false,
    this.urdu = false,
  });

  /// Avatar for a relative. [urdu] picks the Urdu initial (elder screens) or
  /// the Latin initial (family screens).
  factory Avatar.member(FamilyMember m, {double size = 48, bool urdu = false}) => Avatar(
        monogram: monogramFor(m, urdu: urdu),
        size: size,
        tint: m.avatarTint,
        photoPath: m.photoPath,
        memorial: m.isDeceased,
        urdu: urdu,
      );

  static String monogramFor(FamilyMember m, {bool urdu = false}) {
    final s = urdu ? m.displayUr.replaceAll('آپ کا ', '').replaceAll('آپ کی ', '') : m.displayEn;
    final t = s.trim();
    if (t.isEmpty) return urdu ? 'ی' : '?';
    return String.fromCharCode(t.runes.first);
  }

  @override
  Widget build(BuildContext context) {
    Widget inner;
    final p = photoPath;
    final hasPhoto = p != null && p.isNotEmpty && _exists(p);
    if (hasPhoto) {
      inner = ClipOval(
        child: Image.file(File(p), width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _mono()),
      );
    } else {
      inner = _mono();
    }
    if (!memorial) return SizedBox(width: size, height: size, child: inner);
    return Container(
      width: size + 12,
      height: size + 12,
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: YaadainTheme.sepia),
      child: Container(
        width: size + 6,
        height: size + 6,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: inner,
      ),
    );
  }

  bool _exists(String p) {
    try {
      return File(p).existsSync();
    } catch (_) {
      return false;
    }
  }

  Widget _mono() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: tint.bg),
        child: Text(
          monogram,
          textDirection: urdu ? TextDirection.rtl : TextDirection.ltr,
          style: urdu
              ? YaadainTheme.ur(size * 0.42, color: tint.fg, height: 1.8).copyWith(fontSize: size * 0.42 < 20 ? 20 : size * 0.42)
              : YaadainTheme.display(size * 0.42, color: tint.fg, height: 1.1),
        ),
      );
}
