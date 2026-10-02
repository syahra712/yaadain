import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../demo/demo_controls.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../tracking/tracking_source.dart';
import 'chips.dart';
import 'icons.dart';
import 'text.dart';

/// Wraps [child] in the family flavour: family Theme, LTR, English locale.
class FamilyTheme extends StatelessWidget {
  final Widget child;
  const FamilyTheme({super.key, required this.child});

  static final ThemeData _theme = YaadainTheme.family();

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: const Locale('en'),
      delegates: GlobalMaterialLocalizations.delegates,
      child: Theme(
        data: _theme,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(style: YaadainTheme.en(15), child: child),
        ),
      ),
    );
  }
}

/// English screen frame (caregiver / family / English onboarding):
/// status-safe top, 48x48 back button, Fraunces title, optional trailing
/// widgets, the Demo chip, 16px gutter, optional pinned bottom action.
///
/// The Demo chip is added automatically (when the tracking backend is the
/// demo) unless [showDemo] is false. Long-press it opens the presenter sheet.
class FamilyScaffold extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget body;
  final Widget? bottom;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool showDemo;
  final Color background;
  final bool scroll;
  final EdgeInsetsGeometry? bodyPadding;

  /// Replaces the whole app bar (screens with their own hero header).
  final Widget? header;

  const FamilyScaffold({
    super.key,
    this.title,
    this.subtitle,
    required this.body,
    this.bottom,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.showDemo = true,
    this.background = YaadainTheme.paper,
    this.scroll = true,
    this.bodyPadding,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return FamilyTheme(
      child: Builder(builder: (context) {
        final mq = MediaQuery.of(context);
        final pad = bodyPadding ?? const EdgeInsets.symmetric(horizontal: YaadainTheme.familyGutter);
        final content = scroll
            ? SingleChildScrollView(padding: EdgeInsets.zero, child: Padding(padding: pad, child: body))
            : Padding(padding: pad, child: body);
        return Scaffold(
          backgroundColor: background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header ??
                  FamilyAppBar(
                    title: title,
                    subtitle: subtitle,
                    showBack: showBack,
                    onBack: onBack,
                    actions: actions,
                    showDemo: showDemo,
                  ),
              Expanded(child: content),
              if (bottom != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      YaadainTheme.familyGutter, 12, YaadainTheme.familyGutter, 16 + mq.padding.bottom),
                  child: bottom,
                )
              else
                SizedBox(height: mq.padding.bottom),
            ],
          ),
        );
      }),
    );
  }
}

/// The board app bar: [back] title/subtitle ... [actions] [Demo].
class FamilyAppBar extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool showDemo;
  final Color? foreground;

  const FamilyAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.showDemo = true,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();
    final fg = foreground ?? YaadainTheme.ink;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, inset + 8, 16, 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            if (showBack && canPop) ...[
              FamilyIconButton(
                icon: YI.chevronLeft,
                label: 'Back',
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    EnText(title!, size: showBack && canPop ? 24 : 28, weight: FontWeight.w600, display: true, color: fg, height: 1.15, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: EnText(subtitle!, size: 14, weight: FontWeight.w700, color: YaadainTheme.muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
            for (final a in actions) ...[const SizedBox(width: 8), a],
            if (showDemo && kTrackingIsDemo) ...[
              const SizedBox(width: 8),
              DemoChip(onLongPress: () => DemoControls.open(context)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 48x48 outlined square icon button (back, bell, share ...).
class FamilyIconButton extends StatelessWidget {
  final YI icon;
  final String label; // semantics + tooltip
  final VoidCallback? onTap;
  final Color? color;
  final Color? background;
  final Color? borderColor;
  final double size;

  const FamilyIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.background,
    this.borderColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background ?? YaadainTheme.surface,
        borderRadius: YaadainTheme.radius12,
        child: InkWell(
          borderRadius: YaadainTheme.radius12,
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: YaadainTheme.radius12,
              border: Border.all(color: borderColor ?? YaadainTheme.line),
            ),
            alignment: Alignment.center,
            child: YIcon(icon, size: 22, color: color ?? YaadainTheme.ink),
          ),
        ),
      ),
    );
  }
}

// ── Tab shells ─────────────────────────────────────────────────────────────

enum FamilyTab { home, abu, circle }

/// Bottom-tab frame for the three tab roots.
///   caregiver (Bilal): Home `/care` | Abu `/care/where` | Circle `/care/circle`
///   family  (Fatima) : Home `/family` | Dada Jaan `/care/where` | Circle `/care/circle`
/// Adds the 88px bottom nav and, above it, the live alert banner (taps open
/// `/care/alert`). With [title] set it draws the plain app bar; without, the
/// [body] is full-bleed (the home screens draw their own teal header and use
/// `MediaQuery.of(context).padding.top` for the status inset).
class FamilyTabScaffold extends StatelessWidget {
  final FamilyTab tab;
  final Widget body;
  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showDemo;
  final Color background;

  /// Hide the alert banner (e.g. a screen that already shows the alert).
  final bool showAlertBanner;

  const FamilyTabScaffold({
    super.key,
    required this.tab,
    required this.body,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.showDemo = true,
    this.background = YaadainTheme.paper,
    this.showAlertBanner = true,
  });

  /// Root route of a tab for the current device.
  static String routeFor(FamilyTab t, {required bool caregiver}) {
    switch (t) {
      case FamilyTab.home:
        return caregiver ? '/care' : '/family';
      case FamilyTab.abu:
        return '/care/where';
      case FamilyTab.circle:
        return '/care/circle';
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final caregiver = app.isCaregiver;
    return FamilyTheme(
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) FamilyAppBar(title: title, subtitle: subtitle, showBack: false, actions: actions, showDemo: showDemo),
              Expanded(child: body),
              if (showAlertBanner) const FamilyAlertBanner(),
              _FamilyNavBar(
                current: tab,
                abuLabel: caregiver ? 'Abu' : app.elderNameEn,
                onSelect: (t) {
                  if (t == tab) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    routeFor(t, caregiver: caregiver),
                    (r) => false,
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _FamilyNavBar extends StatelessWidget {
  final FamilyTab current;
  final String abuLabel;
  final ValueChanged<FamilyTab> onSelect;
  const _FamilyNavBar({required this.current, required this.abuLabel, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 64 + (bottom > 24 ? bottom : 24),
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottom > 24 ? bottom : 24),
      decoration: const BoxDecoration(
        color: YaadainTheme.surface,
        border: Border(top: BorderSide(color: YaadainTheme.line)),
      ),
      child: Row(
        children: [
          _item(FamilyTab.home, YI.home, 'Home'),
          _item(FamilyTab.abu, YI.map, abuLabel),
          _item(FamilyTab.circle, YI.users, 'Circle'),
        ],
      ),
    );
  }

  Widget _item(FamilyTab t, YI icon, String label) {
    final on = t == current;
    final c = on ? YaadainTheme.primaryDark : YaadainTheme.muted;
    return Expanded(
      child: Semantics(
        button: true,
        selected: on,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: () => onSelect(t),
          borderRadius: YaadainTheme.radius20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: on ? YaadainTheme.primarySoft : Colors.transparent,
                  borderRadius: YaadainTheme.radiusPill,
                ),
                alignment: Alignment.center,
                child: YIcon(icon, size: 22, color: c),
              ),
              const SizedBox(height: 4),
              EnText(label, size: 12, weight: FontWeight.w800, color: c, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

/// The alert banner above the tabs. Visible while an alert is active and not
/// resolved; taps open `/care/alert`. Red only for a help request.
class FamilyAlertBanner extends StatelessWidget {
  const FamilyAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ActiveAlert? a = app.activeAlert;
    if (a == null || a.isResolved) return const SizedBox.shrink();
    final help = a.kind == 'help';
    final bg = help ? YaadainTheme.emergencySoft : YaadainTheme.attentionSoft;
    final fg = help ? YaadainTheme.emergency : YaadainTheme.accentDark;
    final name = app.elderNameEn;
    final headline = help ? '$name pressed Help' : '$name left the home zone';
    final sub = a.isAcknowledged ? '${a.ackBy} is on it' : 'Tap to see where';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        color: bg,
        borderRadius: YaadainTheme.radius20,
        child: InkWell(
          borderRadius: YaadainTheme.radius20,
          onTap: () => Navigator.of(context).pushNamed('/care/alert'),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                YIcon(YI.alertTriangle, size: 22, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EnText(headline, size: 15, weight: FontWeight.w800, color: fg),
                      EnText(sub, size: 13, weight: FontWeight.w700, color: fg),
                    ],
                  ),
                ),
                YIcon(YI.chevronRight, size: 20, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
