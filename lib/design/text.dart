import 'package:flutter/widgets.dart';

import '../theme.dart';

final RegExp _latin = RegExp(r'[A-Za-z]');

/// Urdu text for elder screens: NastaliqUrdu only, weight 400, height >= 1.8,
/// size >= 20, RTL. Latin letters in the string trigger a debug warning
/// (never fatal) because a Latin glyph would fall back to a different font.
class UrduText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final double height;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  const UrduText(
    this.text, {
    super.key,
    this.size = 24,
    this.color = YaadainTheme.ink,
    this.height = 1.9,
    this.align,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (_latin.hasMatch(text)) {
        debugPrint('UrduText: Latin letters in "$text" (one script per screen)');
      }
      return true;
    }());
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: YaadainTheme.ur(size, color: color, height: height),
    );
  }
}

/// English text for family screens. [display] switches to Fraunces.
class EnText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final double? height;
  final bool display;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;

  const EnText(
    this.text, {
    super.key,
    this.size = 15,
    this.weight = FontWeight.w500,
    this.color = YaadainTheme.ink,
    this.height,
    this.display = false,
    this.align,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
  });

  /// Small uppercase label, e.g. "TODAY".
  const EnText.eyebrow(this.text, {super.key, this.color = YaadainTheme.muted})
      : size = 12,
        weight = FontWeight.w800,
        height = null,
        display = false,
        align = null,
        maxLines = null,
        overflow = null,
        letterSpacing = 1.2;

  @override
  Widget build(BuildContext context) {
    final base = display
        ? YaadainTheme.display(size, weight: weight, color: color, height: height ?? 1.2)
        : YaadainTheme.en(size, weight: weight, color: color, height: height ?? 1.4);
    return Text(
      text,
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: letterSpacing == null ? base : base.copyWith(letterSpacing: letterSpacing),
    );
  }
}
