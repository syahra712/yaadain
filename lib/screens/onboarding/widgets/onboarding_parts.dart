import 'dart:io';

import 'package:flutter/material.dart';

import '../../../design/design.dart';

/// Shared building blocks for the onboarding screens (English family side).

/// Top row of the setup flow: back arrow, "Step n of 3" and the three-segment
/// progress strip with its labels.
class OnbStepHeader extends StatelessWidget {
  final int step; // 1..3
  final VoidCallback? onBack;
  const OnbStepHeader({super.key, required this.step, this.onBack});

  static const _labels = ['His details', 'Permissions', 'His agreement'];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                if (onBack != null)
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: InkResponse(
                      onTap: onBack,
                      radius: 28,
                      child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(child: YIcon(YI.arrowLeft, size: 24))),
                    ),
                  )
                else
                  const SizedBox(width: 48, height: 48),
                const Spacer(),
                EnText('Step $step of 3',
                    size: 14,
                    weight: FontWeight.w800,
                    color: YaadainTheme.muted),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i < step
                              ? YaadainTheme.primary
                              : YaadainTheme.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      EnText(_labels[i],
                          size: 12,
                          weight: FontWeight.w800,
                          color: i < step
                              ? YaadainTheme.primaryDark
                              : YaadainTheme.muted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Screen title (Fraunces 28) with its lead paragraph.
class OnbTitle extends StatelessWidget {
  final String title;
  final String? lead;
  const OnbTitle(this.title, {super.key, this.lead});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnText(title,
              size: 27,
              weight: FontWeight.w700,
              display: true,
              height: 1.15,
              letterSpacing: -0.3),
          if (lead != null) ...[
            const SizedBox(height: 10),
            EnText(lead!,
                size: 15,
                weight: FontWeight.w600,
                color: YaadainTheme.muted,
                height: 1.45),
          ],
        ],
      );
}

/// Field label above an input.
class OnbLabel extends StatelessWidget {
  final String text;
  const OnbLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EnText(text, size: 13.5, weight: FontWeight.w800),
      );
}

/// Small helper line under an input.
class OnbHelp extends StatelessWidget {
  final String text;
  final Color color;
  const OnbHelp(this.text, {super.key, this.color = YaadainTheme.muted});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: EnText(text,
            size: 13, weight: FontWeight.w600, color: color, height: 1.4),
      );
}

/// White rounded input used across the setup screens.
class OnbField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final TextDirection? textDirection;
  final bool urdu;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool highlight;
  final bool codeStyle;
  final double height;
  final String? semanticsLabel;

  const OnbField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.textDirection,
    this.urdu = false,
    this.maxLines = 1,
    this.onChanged,
    this.highlight = false,
    this.codeStyle = false,
    this.height = 52,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle base = codeStyle
        ? YaadainTheme.display(26,
                weight: FontWeight.w700, color: YaadainTheme.ink)
            .copyWith(letterSpacing: 4)
        : urdu
            ? YaadainTheme.ur(18, color: YaadainTheme.ink, height: 1.8)
            : YaadainTheme.en(16,
                weight: FontWeight.w700, color: YaadainTheme.ink, height: 1.3);
    // The hint is an English instruction even on the Urdu-keyboard fields.
    final hintStyle = YaadainTheme.en(16,
        weight: FontWeight.w700,
        color: YaadainTheme.muted.withOpacity(.75),
        height: 1.3);
    final border = highlight ? YaadainTheme.primary : YaadainTheme.stroke;
    return Container(
      constraints: BoxConstraints(minHeight: height),
      decoration: BoxDecoration(
        color: YaadainTheme.surface,
        borderRadius: YaadainTheme.radius12,
        border: Border.all(color: border, width: highlight ? 2 : 1),
        boxShadow: highlight
            ? [
                BoxShadow(
                    color: YaadainTheme.primary.withOpacity(.14),
                    spreadRadius: 3,
                    blurRadius: 0)
              ]
            : null,
      ),
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 10 : 0),
      alignment: Alignment.center,
      child: Semantics(
        label: semanticsLabel,
        textField: true,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          textDirection: textDirection,
          minLines: 1,
          maxLines: maxLines,
          onChanged: onChanged,
          style: base,
          cursorColor: YaadainTheme.primary,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.symmetric(vertical: urdu ? 6 : 12),
            hintText: hint,
            hintStyle: hintStyle,
            hintTextDirection: urdu ? TextDirection.ltr : textDirection,
          ),
        ),
      ),
    );
  }
}

/// Outlined white button (secondary action), 48 high.
class OnbOutlineButton extends StatelessWidget {
  final String label;
  final YI? icon;
  final VoidCallback? onTap;
  const OnbOutlineButton(this.label, {super.key, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: YaadainTheme.surface,
          borderRadius: YaadainTheme.radius12,
          child: InkWell(
            borderRadius: YaadainTheme.radius12,
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                borderRadius: YaadainTheme.radius12,
                border: Border.all(color: YaadainTheme.stroke),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    YIcon(icon!, size: 20, color: YaadainTheme.ink),
                    const SizedBox(width: 10)
                  ],
                  Flexible(
                      child: EnText(label,
                          size: 16,
                          weight: FontWeight.w800,
                          align: TextAlign.center)),
                ],
              ),
            ),
          ),
        ),
      );
}

/// The big teal call to action at the foot of a setup screen (56 high).
class OnbPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  const OnbPrimaryButton(this.label,
      {super.key, this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: YaadainTheme.radius20,
            boxShadow: [
              BoxShadow(
                  color: YaadainTheme.primary.withOpacity(.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Material(
            color: YaadainTheme.primary,
            borderRadius: YaadainTheme.radius20,
            child: InkWell(
              borderRadius: YaadainTheme.radius20,
              onTap: enabled ? onTap : null,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : EnText(label,
                        size: 17, weight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A selectable card with a title and a description (role in care, script).
class OnbChoice extends StatelessWidget {
  final String title;
  final String body;
  final bool selected;
  final bool radioDot; // true = ring + dot, false = filled check circle
  final VoidCallback onTap;
  const OnbChoice({
    super.key,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
    this.radioDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget mark;
    if (selected) {
      mark = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: radioDot ? YaadainTheme.primary : YaadainTheme.primary,
        ),
        child: radioDot
            ? Center(
                child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white)))
            : const Center(
                child: YIcon(YI.check,
                    size: 16, color: Colors.white, strokeWidth: 3)),
      );
    } else {
      mark = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: YaadainTheme.stroke, width: 2)),
      );
    }
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $body',
      child: Material(
        color: selected ? YaadainTheme.primarySoft : YaadainTheme.surface,
        borderRadius: YaadainTheme.radius12,
        child: InkWell(
          borderRadius: YaadainTheme.radius12,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              borderRadius: YaadainTheme.radius12,
              border: Border.all(
                  color: selected ? YaadainTheme.primary : YaadainTheme.stroke,
                  width: selected ? 2 : 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                mark,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EnText(title,
                          size: 15.5, weight: FontWeight.w800, height: 1.25),
                      const SizedBox(height: 3),
                      EnText(body,
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: YaadainTheme.bodyDim,
                          height: 1.35),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Teal rounded tile holding an icon (list rows).
class OnbIconTile extends StatelessWidget {
  final YI icon;
  final Color bg;
  final Color fg;
  final double size;
  const OnbIconTile(this.icon,
      {super.key,
      this.bg = YaadainTheme.primarySoft,
      this.fg = YaadainTheme.primary,
      this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(size >= 56 ? 16 : 12)),
        child:
            Center(child: YIcon(icon, size: size >= 56 ? 28 : 22, color: fg)),
      );
}

/// Dark teal panel with the jaali lattice (hand-over card, next-step card).
class OnbDarkPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const OnbDarkPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: YaadainTheme.primaryDark,
          borderRadius: YaadainTheme.radius28,
          boxShadow: [
            BoxShadow(
                color: YaadainTheme.primaryDark.withOpacity(.25),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned.fill(child: JaaliPattern(opacity: .08)),
            Padding(padding: padding, child: child),
          ],
        ),
      );
}

/// Bare back arrow row (48 high) under the status bar.
class OnbBackBar extends StatelessWidget {
  final VoidCallback onBack;
  const OnbBackBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + 8, 16, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            button: true,
            label: 'Back',
            child: InkResponse(
              onTap: onBack,
              radius: 28,
              child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: YIcon(YI.arrowLeft, size: 24))),
            ),
          ),
        ),
      );
}

/// Person silhouette inside a ring: the placeholder when there is no photo.
class OnbSilhouette extends StatelessWidget {
  final double size;
  final Color bg;
  final Color fg;
  final Color ring;
  final String? photoPath;
  const OnbSilhouette({
    super.key,
    this.size = 88,
    this.bg = const Color(0xFFF1E6CC),
    this.fg = const Color(0xFF8A6D2F),
    this.ring = YaadainTheme.gold,
    this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    final p = photoPath;
    Widget inner =
        CustomPaint(painter: _SilPainter(bg, fg), size: Size.square(size));
    if (p != null && p.isNotEmpty) {
      inner = Image.file(File(p),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CustomPaint(
              painter: _SilPainter(bg, fg), size: Size.square(size)));
    }
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ring, width: 1.5),
          color: YaadainTheme.surface),
      child: ClipOval(child: inner),
    );
  }
}

class _SilPainter extends CustomPainter {
  final Color bg;
  final Color fg;
  _SilPainter(this.bg, this.fg);

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = bg);
    final w = s.width;
    final paint = Paint()..color = fg;
    canvas.drawCircle(Offset(w / 2, w * .40), w * .19, paint);
    canvas.save();
    canvas.clipRect(Offset.zero & s);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w / 2, w * 1.0), width: w * .78, height: w * .62),
        paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SilPainter old) => old.bg != bg || old.fg != fg;
}
