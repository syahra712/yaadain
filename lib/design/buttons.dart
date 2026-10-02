import 'package:flutter/material.dart';

import '../theme.dart';
import 'icons.dart';
import 'text.dart';

enum ElderButtonKind { care, primary, quiet }

/// Elder (Urdu) button. [care] = clay (the ONE care action per screen),
/// [primary] = teal, [quiet] = outline. Height 64 by default, 80 if [large].
class ElderButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final ElderButtonKind kind;
  final YI? icon;
  final bool large;
  final bool expand;

  const ElderButton(this.label,
      {super.key, this.onTap, this.kind = ElderButtonKind.primary, this.icon, this.large = false, this.expand = true});

  const ElderButton.care(this.label, {super.key, this.onTap, this.icon, this.large = false, this.expand = true})
      : kind = ElderButtonKind.care;
  const ElderButton.quiet(this.label, {super.key, this.onTap, this.icon, this.large = false, this.expand = true})
      : kind = ElderButtonKind.quiet;

  @override
  Widget build(BuildContext context) {
    final bg = switch (kind) {
      ElderButtonKind.care => YaadainTheme.accentDark,
      ElderButtonKind.primary => YaadainTheme.primary,
      ElderButtonKind.quiet => YaadainTheme.surface,
    };
    final fg = kind == ElderButtonKind.quiet ? YaadainTheme.ink : Colors.white;
    final h = large ? YaadainTheme.elderPrimaryTouchLarge : YaadainTheme.elderPrimaryTouch;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bg,
        borderRadius: YaadainTheme.radius20,
        child: InkWell(
          borderRadius: YaadainTheme.radius20,
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: h, minWidth: expand ? double.infinity : 0),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: kind == ElderButtonKind.quiet
                ? BoxDecoration(
                    borderRadius: YaadainTheme.radius20,
                    border: Border.all(color: YaadainTheme.stroke, width: 1.5))
                : null,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                if (icon != null) ...[YIcon(icon!, size: 28, color: fg), const SizedBox(width: 12)],
                // Nastaliq glyphs sit low in their line box; the bottom pad optically centres them.
                Flexible(child: Padding(padding: const EdgeInsets.only(bottom: 8), child: UrduText(label, size: 24, color: fg, align: TextAlign.center))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum FamilyButtonKind { care, primary, quiet, emergency }

/// Family (English) button, 48px high.
class FamilyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final FamilyButtonKind kind;
  final YI? icon;
  final bool expand;

  const FamilyButton(this.label,
      {super.key, this.onTap, this.kind = FamilyButtonKind.primary, this.icon, this.expand = true});
  const FamilyButton.care(this.label, {super.key, this.onTap, this.icon, this.expand = true})
      : kind = FamilyButtonKind.care;
  const FamilyButton.quiet(this.label, {super.key, this.onTap, this.icon, this.expand = true})
      : kind = FamilyButtonKind.quiet;
  const FamilyButton.emergency(this.label, {super.key, this.onTap, this.icon, this.expand = true})
      : kind = FamilyButtonKind.emergency;

  @override
  Widget build(BuildContext context) {
    final bg = switch (kind) {
      FamilyButtonKind.care => YaadainTheme.accentDark,
      FamilyButtonKind.primary => YaadainTheme.primary,
      FamilyButtonKind.emergency => YaadainTheme.emergency,
      FamilyButtonKind.quiet => YaadainTheme.surface,
    };
    final fg = kind == FamilyButtonKind.quiet ? YaadainTheme.ink : Colors.white;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bg,
        borderRadius: YaadainTheme.radius12,
        child: InkWell(
          borderRadius: YaadainTheme.radius12,
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: YaadainTheme.familyTouch, minWidth: expand ? double.infinity : 0),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: kind == FamilyButtonKind.quiet
                ? BoxDecoration(
                    borderRadius: YaadainTheme.radius12,
                    border: Border.all(color: YaadainTheme.stroke, width: 1.5))
                : null,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[YIcon(icon!, size: 20, color: fg), const SizedBox(width: 8)],
                Flexible(child: EnText(label, size: 16, weight: FontWeight.w800, color: fg, align: TextAlign.center)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
