import 'package:flutter/material.dart';

import '../theme.dart';
import 'icons.dart';
import 'text.dart';

enum ChipTone { neutral, success, attention, emergency }

/// Small English status chip (family screens).
class StatusChip extends StatelessWidget {
  final String label;
  final ChipTone tone;
  final YI? icon;
  const StatusChip(this.label, {super.key, this.tone = ChipTone.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ChipTone.success => (YaadainTheme.primarySoft, YaadainTheme.primaryDark),
      ChipTone.attention => (YaadainTheme.attentionSoft, YaadainTheme.accentDark),
      ChipTone.emergency => (YaadainTheme.emergencySoft, YaadainTheme.emergency),
      ChipTone.neutral => (YaadainTheme.line, YaadainTheme.bodyDim),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: YaadainTheme.radiusPill),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[YIcon(icon!, size: 14, color: fg), const SizedBox(width: 4)],
        EnText(label, size: 12, weight: FontWeight.w800, color: fg),
      ]),
    );
  }
}

/// Urdu status chip (elder screens).
class UrduChip extends StatelessWidget {
  final String label;
  final ChipTone tone;
  const UrduChip(this.label, {super.key, this.tone = ChipTone.neutral});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ChipTone.success => (YaadainTheme.primarySoft, YaadainTheme.primaryDark),
      ChipTone.attention => (YaadainTheme.attentionSoft, YaadainTheme.accentDark),
      ChipTone.emergency => (YaadainTheme.emergencySoft, YaadainTheme.emergency),
      ChipTone.neutral => (YaadainTheme.line, YaadainTheme.bodyDim),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: YaadainTheme.radiusPill),
      child: UrduText(label, size: 20, color: fg),
    );
  }
}

/// "Demo" chip, English screens only. Long-press opens the presenter sheet
/// via [onLongPress] (wired by FamilyScaffold / home screens).
class DemoChip extends StatelessWidget {
  final VoidCallback? onLongPress;
  const DemoChip({super.key, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: YaadainTheme.attentionSoft,
          borderRadius: YaadainTheme.radiusPill,
          border: Border.all(color: YaadainTheme.gold, width: 1),
        ),
        child: const EnText('Demo', size: 12, weight: FontWeight.w800, color: YaadainTheme.accentDark),
      ),
    );
  }
}
