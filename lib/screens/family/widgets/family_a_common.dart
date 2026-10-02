import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/design.dart';
import '../../../models/episode_log.dart';
import '../../../state/app_state.dart';
import '../../../util/en_format.dart';
import '../../../services/platform/platform.dart';

/// Shared private helpers for the family-a screens (CaregiverHome, FamilyHome,
/// CareCircle, WeeklyReport). English only.

/// "Saturday 3 October" (board style, no comma).
String faDate(DateTime d) => '${EnFmt.weekday(d)} ${d.day} ${EnFmt.month(d.month)}';

/// "25 Sep – 2 Oct"
String faRange(DateTime from, DateTime to) =>
    '${from.day} ${EnFmt.monthShort(from.month)} – ${to.day} ${EnFmt.monthShort(to.month)}';

/// "north-east" from a bearing in degrees.
String faCompass(double deg) {
  const names = ['north', 'north-east', 'east', 'south-east', 'south', 'south-west', 'west', 'north-west'];
  final i = (((deg % 360) + 360) % 360 / 45).round() % 8;
  return names[i];
}

/// "6 pm" / "6:30 pm" / "12 am".
String faHour(int h, [int m = 0]) {
  var x = h % 12;
  if (x == 0) x = 12;
  final ap = (h % 24) < 12 ? 'am' : 'pm';
  return m == 0 ? '$x $ap' : '$x:${m.toString().padLeft(2, '0')} $ap';
}

/// "9:04" (no am/pm) for sublines.
String faClock(DateTime t) {
  var h = t.hour % 12;
  if (h == 0) h = 12;
  return '$h:${t.minute.toString().padLeft(2, '0')}';
}

/// Copies the family code and shows a snackbar.
Future<void> faCopyCode(BuildContext context, AppState app) async {
  await Clipboard.setData(ClipboardData(text: app.familyCodeDisplay));
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Family code copied')));
}

/// Shares the family code as a text message (no share plugin available).
Future<void> faShareCode(BuildContext context, AppState app) async {
  final body = 'Join ${app.elderNameEn}\'s family on Yaadain. Family code: ${app.familyCodeDisplay}';
  final ok = await Svc.launcher.sms('', body: body);
  if (ok || !context.mounted) return;
  await Clipboard.setData(ClipboardData(text: body));
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Invite copied. Paste it into any chat.')));
}

/// Section header: Fraunces title, optional right action.
class FaSectionHeader extends StatelessWidget {
  final String title;
  final String? count;
  final String? action;
  final YI? actionIcon;
  final VoidCallback? onAction;
  final double size;
  const FaSectionHeader(this.title, {super.key, this.count, this.action, this.actionIcon, this.onAction, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              EnText(title, size: size, weight: FontWeight.w600, display: true),
              if (count != null) ...[
                const SizedBox(width: 8),
                EnText(count!, size: 14, weight: FontWeight.w700, color: YaadainTheme.muted),
              ],
            ],
          ),
        ),
        if (action != null)
          InkWell(
            onTap: onAction,
            borderRadius: YaadainTheme.radius12,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (actionIcon != null) ...[
                    YIcon(actionIcon!, size: 18, color: YaadainTheme.primary, strokeWidth: 2.4),
                    const SizedBox(width: 4),
                  ],
                  EnText(action!, size: 14, weight: FontWeight.w800, color: YaadainTheme.primary),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

/// White card with hairline dividers between its children (inset on the left).
class FaCardList extends StatelessWidget {
  final List<Widget> children;
  final double dividerInset;
  final EdgeInsets padding;
  const FaCardList({super.key, required this.children, this.dividerInset = 60, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final kids = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        kids.add(Padding(
          padding: EdgeInsets.only(left: dividerInset),
          child: const Divider(height: 1, thickness: 1, color: YaadainTheme.line),
        ));
      }
      kids.add(children[i]);
    }
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: YaadainTheme.surface,
        borderRadius: YaadainTheme.radius20,
        border: Border.all(color: YaadainTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: kids),
    );
  }
}

/// Rounded icon box (36 / 40 / 44).
class FaIconBox extends StatelessWidget {
  final YI icon;
  final double size;
  final Color bg;
  final Color fg;
  const FaIconBox(this.icon, {super.key, this.size = 36, this.bg = YaadainTheme.primarySoft, this.fg = YaadainTheme.primaryDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: YaadainTheme.radius12),
      alignment: Alignment.center,
      child: YIcon(icon, size: size >= 40 ? 22 : 20, color: fg),
    );
  }
}

/// Standard list row: leading widget, title + sub, trailing widget or chevron.
class FaRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? sub;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;
  final double minHeight;
  final double titleSize;
  final EdgeInsets padding;
  const FaRow({
    super.key,
    this.leading,
    required this.title,
    this.sub,
    this.trailing,
    this.chevron = false,
    this.onTap,
    this.minHeight = 56,
    this.titleSize = 15,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                EnText(title, size: titleSize, weight: FontWeight.w800, height: 1.25),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: EnText(sub!, size: 13, weight: FontWeight.w600, color: YaadainTheme.muted, height: 1.3),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          if (chevron) ...[
            const SizedBox(width: 6),
            const YIcon(YI.chevronRight, size: 20, color: YaadainTheme.stroke),
          ],
        ],
      ),
    );
    final boxed = ConstrainedBox(constraints: BoxConstraints(minHeight: minHeight), child: Align(alignment: Alignment.centerLeft, child: row));
    if (onTap == null) return boxed;
    return InkWell(onTap: onTap, child: boxed);
  }
}

/// Small pill label (26 px high).
class FaPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const FaPill(this.label, {super.key, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: YaadainTheme.radiusPill),
      alignment: Alignment.center,
      child: EnText(label, size: 12, weight: FontWeight.w800, color: fg, height: 1.1),
    );
  }
}

/// Status dot with a soft halo.
class FaDot extends StatelessWidget {
  final Color color;
  final Color halo;
  final double size;
  const FaDot({super.key, this.color = YaadainTheme.primary, this.halo = YaadainTheme.primarySoft, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: halo, spreadRadius: 4)],
      ),
    );
  }
}

/// Round play button (40) used for voice rows.
class FaPlayCircle extends StatelessWidget {
  final VoidCallback? onTap;
  final bool enabled;
  final String label;
  const FaPlayCircle({super.key, this.onTap, this.enabled = true, this.label = 'Play'});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        radius: 28,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: enabled ? YaadainTheme.primary : YaadainTheme.line,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: YIcon(YI.play, size: 18, color: enabled ? Colors.white : YaadainTheme.stroke),
            ),
          ),
        ),
      ),
    );
  }
}

/// 44 px square white icon button with a hairline border.
class FaSquareButton extends StatelessWidget {
  final YI icon;
  final String label;
  final VoidCallback? onTap;
  const FaSquareButton({super.key, required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: YaadainTheme.radius12,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: YaadainTheme.surface,
            borderRadius: YaadainTheme.radius12,
            border: Border.all(color: YaadainTheme.line),
          ),
          alignment: Alignment.center,
          child: YIcon(icon, size: 20, color: YaadainTheme.primaryDark),
        ),
      ),
    );
  }
}

/// Zone exits in the last 7 days that were not routine outings (severity >= 2).
List<Episode> faUnplannedExits(AppState app) => app.episodesSince(app.now.subtract(const Duration(days: 7)))
    .where((e) => e.category == 'zone_exit' && e.severity >= 2)
    .toList()
  ..sort((a, b) => a.at.compareTo(b.at));

/// Routine outings (severity 1 zone exits) in the last 7 days.
List<Episode> faOutings(AppState app) => app.episodesSince(app.now.subtract(const Duration(days: 7)))
    .where((e) => e.category == 'zone_exit' && e.severity < 2)
    .toList()
  ..sort((a, b) => a.at.compareTo(b.at));
