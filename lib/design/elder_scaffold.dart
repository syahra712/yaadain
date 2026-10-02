import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../theme.dart';
import 'icons.dart';
import 'text.dart';

/// Wraps [child] in the elder flavour: elder Theme, RTL, Urdu locale.
/// Every elder surface (including dialogs you build yourself) should sit
/// inside this.
class ElderTheme extends StatelessWidget {
  final Widget child;
  const ElderTheme({super.key, required this.child});

  static final ThemeData _theme = YaadainTheme.elder();

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: const Locale('ur'),
      delegates: GlobalMaterialLocalizations.delegates,
      child: Theme(
        data: _theme,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: DefaultTextStyle(style: YaadainTheme.ur(24), child: child),
        ),
      ),
    );
  }
}

/// Elder screen frame: status-safe top, the 80x80 واپس / گھر header, 24px
/// gutter, optional pinned bottom action.
///
/// [showBack] / [showHome] default true. [onBack] defaults to pop;
/// [onHome] defaults to popUntil(first). In RTL, واپس sits on the right.
class ElderScaffold extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget body;
  final Widget? bottom;
  final bool showBack;
  final bool showHome;
  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final Color background;
  final bool scroll;
  final EdgeInsetsGeometry? bodyPadding;

  /// Replaces the whole header (e.g. Main screen with a logo).
  final Widget? header;

  const ElderScaffold({
    super.key,
    this.title,
    this.subtitle,
    required this.body,
    this.bottom,
    this.showBack = true,
    this.showHome = true,
    this.onBack,
    this.onHome,
    this.background = YaadainTheme.paper,
    this.scroll = true,
    this.bodyPadding,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return ElderTheme(
      child: Builder(builder: (context) {
        final mq = MediaQuery.of(context);
        final padBody = bodyPadding ?? const EdgeInsets.symmetric(horizontal: YaadainTheme.elderGutter);
        Widget content = body;
        if (scroll) {
          content = SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Padding(padding: padBody, child: body),
          );
        } else {
          content = Padding(padding: padBody, child: body);
        }
        return Scaffold(
          backgroundColor: background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header ?? ElderHeader(
                    title: title,
                    subtitle: subtitle,
                    showBack: showBack,
                    showHome: showHome,
                    onBack: onBack,
                    onHome: onHome,
                  ),
              Expanded(child: content),
              if (bottom != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      YaadainTheme.elderGutter, 12, YaadainTheme.elderGutter, 16 + mq.padding.bottom),
                  child: bottom,
                ),
              if (bottom == null) SizedBox(height: mq.padding.bottom),
            ],
          ),
        );
      }),
    );
  }
}

/// The header: [واپس | title | گھر]. Exposed so screens can compose it.
class ElderHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showBack;
  final bool showHome;
  final VoidCallback? onBack;
  final VoidCallback? onHome;

  const ElderHeader({super.key, this.title, this.subtitle, this.showBack = true, this.showHome = true, this.onBack, this.onHome});

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, inset + 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              showBack
                  ? ElderNavButton(
                      label: 'واپس',
                      icon: YI.arrowRight, // RTL: points right
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    )
                  : const SizedBox(width: 80, height: 80),
              Expanded(
                child: title == null
                    ? const SizedBox()
                    : UrduText(title!, size: 36, height: 1.8, align: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              showHome
                  ? ElderNavButton(
                      label: 'گھر',
                      icon: YI.home,
                      onTap: onHome ?? () => Navigator.of(context).popUntil((r) => r.isFirst),
                    )
                  : const SizedBox(width: 80, height: 80),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: UrduText(subtitle!, size: 24, color: YaadainTheme.muted, align: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

/// 80x80 white labelled button (border 1px line, radius 20).
class ElderNavButton extends StatelessWidget {
  final String label;
  final YI icon;
  final VoidCallback onTap;
  const ElderNavButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: YaadainTheme.surface,
        borderRadius: YaadainTheme.radius20,
        child: InkWell(
          borderRadius: YaadainTheme.radius20,
          onTap: onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: YaadainTheme.radius20,
              border: Border.all(color: YaadainTheme.line, width: 1),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                YIcon(icon, size: 24, color: YaadainTheme.ink),
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: Center(child: UrduText(label, size: 20, height: 1.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
