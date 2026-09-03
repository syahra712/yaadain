import 'package:flutter/material.dart';

import '../theme.dart';

/// A calm, large-touch navigation shell for every elder-facing sub-screen.
///
/// Dementia-friendly navigation principles applied here:
///  - A big, labelled **Back** button (not a tiny arrow), RTL-correct.
///  - A one-tap **Home** escape, so the elder is never "lost" more than one
///    tap from the front door.
///  - Generous type, high contrast, nothing that flashes.
class ElderScaffold extends StatelessWidget {
  final String title;
  final bool roman;
  final Widget child;

  /// Show the one-tap Home button (hidden on the home screen itself).
  final bool showHome;

  /// Optional colour accent for the header (defaults to primary).
  final Color? accent;

  const ElderScaffold({
    super.key,
    required this.title,
    required this.roman,
    required this.child,
    this.showHome = true,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // Elder sub-screens are pushed above the app's Directionality wrapper, so
    // we set direction here from the elder's script preference — otherwise Urdu
    // screens would render left-to-right.
    final dir = roman ? TextDirection.ltr : TextDirection.rtl;
    return Directionality(textDirection: dir, child: _build(context, dir));
  }

  Widget _build(BuildContext context, TextDirection dir) {
    final isRtl = dir == TextDirection.rtl;
    final color = accent ?? YaadainTheme.primary;

    return Scaffold(
      backgroundColor: YaadainTheme.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Header — a title page strip, not an app toolbar.
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
              child: Row(
                children: [
                  _HeaderButton(
                    icon: isRtl ? Icons.arrow_forward : Icons.arrow_back,
                    label: roman ? 'Wapas' : 'واپس',
                    color: color,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YaadainTheme.serif(23, w: FontWeight.w600),
                    ),
                  ),
                  if (showHome)
                    _HeaderButton(
                      icon: Icons.home_rounded,
                      label: roman ? 'Ghar' : 'گھر',
                      color: color,
                      onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    )
                  else
                    const SizedBox(width: 76),
                ],
              ),
            ),
            Container(height: 1.2, color: YaadainTheme.leafRule.withOpacity(0.3)),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
