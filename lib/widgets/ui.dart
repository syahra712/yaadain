import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared, reusable UI pieces so every screen reads as one system.

/// A warm, friendly empty state used wherever there's no data yet.
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.emoji, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: YaadainTheme.leafRule.withOpacity(0.4), width: 1.4),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 22),
            Text(title,
                textAlign: TextAlign.center,
                style: YaadainTheme.serif(21, w: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15.5, fontStyle: FontStyle.italic, color: YaadainTheme.foxed, height: 1.6)),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// A small rounded label chip.
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final Color? bg;
  const Pill({super.key, required this.text, required this.color, this.icon, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: color), const SizedBox(width: 5)],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}

/// A soft section heading for setup screens.
class SectionLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  const SectionLabel(this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 20, color: YaadainTheme.primaryDark), const SizedBox(width: 8)],
          Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: YaadainTheme.ink)),
        ],
      ),
    );
  }
}

/// A large, elder-friendly primary action button.
class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color fg;
  final VoidCallback? onTap;
  const BigButton({
    super.key,
    required this.label,
    this.icon,
    this.color = YaadainTheme.primary,
    this.fg = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: onTap == null ? color.withOpacity(0.4) : color,
        borderRadius: BorderRadius.circular(YaadainTheme.rMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(YaadainTheme.rMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, color: fg, size: 26), const SizedBox(width: 12)],
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
