import 'package:flutter/material.dart';

import '../../../config.dart';
import '../../../design/design.dart';
import '../../../models/care.dart';
import '../../../state/app_state.dart';
import '../../../tracking/tracking_source.dart';
import '../../../util/en_format.dart';
import 'safety_family_radar.dart';

/// "7:10 am" (lower-case, as on the boards).
String tLower(DateTime t) {
  var h = t.hour % 12;
  if (h == 0) h = 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'am' : 'pm'}';
}

/// The elder as the family calls him on these screens.
String whoName(AppState app) =>
    app.isCaregiver || !app.isFamily ? 'Abu' : app.elderNameEn;

/// His phone number, if the family saved one. The model has no field for it
/// yet, so this reads the optional `elderPhone` key of the missing pack.
String? elderPhone(AppState app) {
  final p = app.care.missingPack['elderPhone'] ?? app.care.missingPack['phone'];
  return p is String && p.trim().isNotEmpty ? p.trim() : null;
}

/// Zone (other than home) that contains his latest position, if any.
SafeZone? zoneContaining(AppState app, ElderStatus? s) {
  if (s == null) return null;
  final home = app.homePoint;
  final here = _eastNorth(app, s);
  for (final z in app.zones) {
    if (!z.enabled) continue;
    final o = offsetMeters(home.lat, home.lng, z.lat, z.lng);
    final dx = o.east - here.$1, dy = o.north - here.$2;
    if ((dx * dx + dy * dy) <= z.radiusM * z.radiusM) return z;
  }
  return null;
}

(double, double) _eastNorth(AppState app, ElderStatus s) {
  final home = app.homePoint;
  final o = offsetMeters(home.lat, home.lng, s.lat, s.lng);
  return (o.east, o.north);
}

/// Other safe zones as radar places.
List<RadarPlace> radarPlaces(AppState app) {
  final home = app.homePoint;
  final out = <RadarPlace>[];
  for (final z in app.zones) {
    if (!z.enabled || z.id == 'zone-home' || z.name.toLowerCase() == 'home')
      continue;
    final o = offsetMeters(home.lat, home.lng, z.lat, z.lng);
    out.add(RadarPlace(z.name, o.east, o.north));
  }
  return out;
}

/// Street landmark for the demo script only (the app has no map data).
String? demoLandmark(AppState app, ElderStatus? s) {
  if (!kTrackingIsDemo || !app.hasDemoData || s == null || s.inside)
    return null;
  return s.distanceM > 200 ? 'Rashid Minhas Rd' : null;
}

/// "320 m north-east of home, near Rashid Minhas Road".
String locationSentence(AppState app, ElderStatus s) {
  final base =
      '${EnFmt.distance(s.distanceM)} ${bearingWords(s.bearingDeg)} of home';
  return demoLandmark(app, s) != null ? '$base, near Rashid Minhas Road' : base;
}

/// A card section header: "Today" ........ "Events, not locations".
class SafetySectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const SafetySectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: SizedBox(
        height: 32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: EnText(title, size: 18, weight: FontWeight.w800)),
            if (trailing != null)
              EnText(trailing!,
                  size: 13, weight: FontWeight.w700, color: YaadainTheme.muted),
          ],
        ),
      ),
    );
  }
}

/// Phone 64% . updated 2 min ago . Sharing on  (any item can be omitted).
class StatusMeta extends StatelessWidget {
  final int? battery;
  final DateTime? updatedAt;
  final bool sharing;
  final DateTime now;
  const StatusMeta(
      {super.key,
      this.battery,
      this.updatedAt,
      this.sharing = false,
      required this.now});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (battery != null) _item(YI.battery, 'Phone $battery%'),
      if (updatedAt != null)
        _item(YI.clock, 'updated ${EnFmt.relative(updatedAt!, now)}'),
      if (sharing) _item(YI.eye, 'Sharing on'),
    ];
    final spaced = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        spaced.add(Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
                color: YaadainTheme.stroke, shape: BoxShape.circle)));
      }
      spaced.add(items[i]);
    }
    return Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: spaced);
  }

  Widget _item(YI icon, String text) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        YIcon(icon, size: 16, color: YaadainTheme.muted, strokeWidth: 2.4),
        const SizedBox(width: 6),
        EnText(text,
            size: 14,
            weight: FontWeight.w700,
            color: YaadainTheme.muted,
            height: 1.2),
      ]);
}

/// Pill chip at board size (28 or 36 high).
class SafetyPill extends StatelessWidget {
  final String label;
  final YI? icon;
  final Color bg;
  final Color fg;
  final Color? border;
  final double height;
  const SafetyPill(this.label,
      {super.key,
      this.icon,
      this.bg = YaadainTheme.primarySoft,
      this.fg = YaadainTheme.primaryDark,
      this.border,
      this.height = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: YaadainTheme.radiusPill,
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          YIcon(icon!, size: 16, color: fg, strokeWidth: 2.4),
          const SizedBox(width: 6)
        ],
        EnText(label,
            size: 14,
            weight: FontWeight.w700,
            color: fg,
            height: 1.0,
            maxLines: 1),
      ]),
    );
  }
}

/// Fixed-size board buttons (the shared FamilyButton is 12px-radius; the
/// boards use 16 for 48px and 20 for 56px buttons).
class SafetyButton extends StatelessWidget {
  final String label;
  final YI? icon;
  final VoidCallback? onTap;
  final SafetyButtonStyle style;
  final double height;
  final double radius;
  final double fontSize;

  const SafetyButton.care(this.label,
      {super.key, this.icon, this.onTap, this.height = 56, this.fontSize = 17})
      : style = SafetyButtonStyle.care,
        radius = height == 56 ? 20 : 16;
  const SafetyButton.primary(this.label,
      {super.key, this.icon, this.onTap, this.height = 48, this.fontSize = 15})
      : style = SafetyButtonStyle.primary,
        radius = height == 56 ? 20 : 16;
  const SafetyButton.quiet(this.label,
      {super.key, this.icon, this.onTap, this.height = 48, this.fontSize = 15})
      : style = SafetyButtonStyle.quiet,
        radius = height == 56 ? 20 : 16;
  const SafetyButton.clayOutline(this.label,
      {super.key, this.icon, this.onTap, this.height = 48, this.fontSize = 15})
      : style = SafetyButtonStyle.clayOutline,
        radius = height == 56 ? 20 : 16;
  const SafetyButton.soft(this.label,
      {super.key, this.icon, this.onTap, this.height = 48, this.fontSize = 15})
      : style = SafetyButtonStyle.soft,
        radius = height == 56 ? 20 : 16;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, shadow) = switch (style) {
      SafetyButtonStyle.care => (
          YaadainTheme.accentDark,
          Colors.white,
          null,
          const [
            BoxShadow(
                color: Color(0x429E5626), blurRadius: 20, offset: Offset(0, 8))
          ]
        ),
      SafetyButtonStyle.primary => (
          YaadainTheme.primary,
          Colors.white,
          null,
          const [
            BoxShadow(
                color: Color(0x331F6F5C), blurRadius: 16, offset: Offset(0, 6))
          ]
        ),
      SafetyButtonStyle.quiet => (
          YaadainTheme.surface,
          YaadainTheme.ink,
          YaadainTheme.stroke,
          const <BoxShadow>[]
        ),
      SafetyButtonStyle.clayOutline => (
          YaadainTheme.surface,
          YaadainTheme.accentDark,
          YaadainTheme.accentDark,
          const <BoxShadow>[]
        ),
      SafetyButtonStyle.soft => (
          YaadainTheme.primarySoft,
          YaadainTheme.primaryDark,
          null,
          const <BoxShadow>[]
        ),
    };
    final disabled = onTap == null;
    final br = BorderRadius.circular(radius);
    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        // A confirmed care button ("On your way") keeps readable contrast.
        opacity: disabled ? (style == SafetyButtonStyle.care ? 0.88 : 0.55) : 1,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: br, boxShadow: disabled ? null : shadow),
          child: Material(
            color: bg,
            borderRadius: br,
            child: InkWell(
              borderRadius: br,
              onTap: onTap,
              child: Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: border == null
                    ? null
                    : BoxDecoration(
                        borderRadius: br,
                        border: Border.all(color: border, width: 1.5)),
                alignment: Alignment.center,
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        YIcon(icon!, size: 20, color: fg, strokeWidth: 2.2),
                        const SizedBox(width: 10)
                      ],
                      Flexible(
                        child: EnText(label,
                            size: fontSize,
                            weight: FontWeight.w800,
                            color: fg,
                            height: 1.2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum SafetyButtonStyle { care, primary, quiet, clayOutline, soft }

/// Shows a small English snackbar.
void safetyToast(BuildContext context, String msg) {
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(SnackBar(
    content:
        EnText(msg, size: 14, weight: FontWeight.w700, color: Colors.white),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
  ));
}
