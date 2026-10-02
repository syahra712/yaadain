import 'package:flutter/material.dart';

import '../theme.dart';

/// White surface card with a 1px line border. Elder cards use radius 20/28,
/// family cards 20.
class YCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;
  final bool shadow;

  const YCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = YaadainTheme.surface,
    this.borderColor = YaadainTheme.line,
    this.radius = 20,
    this.onTap,
    this.shadow = false,
  });

  /// Tinted callout (attention / emergency / success).
  const YCard.tinted({
    super.key,
    required this.child,
    required this.color,
    this.borderColor = Colors.transparent,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
  }) : shadow = false;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: br,
          border: Border.all(color: borderColor, width: 1),
          boxShadow: shadow ? YaadainTheme.softShadow : null,
        ),
        child: InkWell(
          borderRadius: br,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
