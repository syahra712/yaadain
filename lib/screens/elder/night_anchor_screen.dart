import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/episode_log.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../settings/locked_settings.dart';
import '../../state/app_state.dart';
import '../../util/urdu_format.dart';
import 'widgets/elder_a_parts.dart';

/// Night anchor: the elder wakes at 2 am and is told, simply, where he is.
/// Dark, quiet, two actions: Sukoon (calm) and wake Bilal (the one clay action).
class NightAnchorScreen extends StatelessWidget {
  const NightAnchorScreen({super.key});

  static String _timeLine(DateTime t) {
    var h = t.hour % 12;
    if (h == 0) h = 12;
    final hs = UrduFmt.digits(h);
    final clock = t.minute == 0 ? hs : '$hs:${UrduFmt.pad2(t.minute)}';
    final p = UrduFmt.period(t);
    if (t.minute == 0 && h == 1) return '$p کا $clock بجا ہے۔';
    return '$p کے $clock بجے ہیں۔';
  }

  Future<void> _wake(BuildContext context, AppState app) async {
    final p = app.primaryContact;
    final phone = p?.phone ?? '';
    final messenger = ScaffoldMessenger.of(context);
    app.logEpisode(Episode(category: 'night_pickup', at: app.now));
    if (phone.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: UrduText('ابھی کوئی نمبر محفوظ نہیں۔', size: 20, color: Colors.white)));
      return;
    }
    try {
      await Svc.launcher.call(phone);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    const ink = YaadainTheme.paper;
    final inside = app.elderStatus?.inside ?? true;
    final p = app.primaryContact;
    final wakeLabel = p == null ? 'گھر والوں کو جگائیں' : '${p.displayUr} کو جگائیں';

    return ElderScaffold(
      header: const SizedBox.shrink(),
      background: YaadainTheme.ink,
      scroll: false,
      body: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Padding(
              padding: const EdgeInsets.only(top: 118),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElderLogoGate(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: EldIcon(EldPaths.nightMoon, size: 40, color: YaadainTheme.gold, stroke: 2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: UrduText(_timeLine(app.now), size: 36, color: ink, height: 1.8, align: TextAlign.center),
                  ),
                  const SizedBox(height: 12),
                  UrduText('سب سو رہے ہیں۔', size: 28, color: ink.withOpacity(.9), height: 1.8, align: TextAlign.center),
                  UrduText(inside ? 'آپ گھر پر ہیں۔' : 'آپ گھر سے باہر ہیں۔',
                      size: 28, color: ink.withOpacity(.9), height: 1.8, align: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EldBtn(
            'سکون',
            bg: YaadainTheme.primary,
            fg: Colors.white,
            height: 80,
            size: 28,
            icon: EldIcon(EldPaths.waves, size: 28, color: Colors.white),
            onTap: () => Navigator.of(context).pushNamed(Routes.sukoon),
          ),
          const SizedBox(height: 16),
          EldBtn(
            wakeLabel,
            bg: YaadainTheme.accentDark,
            fg: Colors.white,
            height: 80,
            size: 24,
            shadow: true,
            icon: EldIcon(EldPaths.phone, size: 28, color: Colors.white),
            onTap: () => _wake(context, app),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
