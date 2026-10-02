import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/design.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../tracking/elder_reaction.dart';
import '../util/app_clock.dart';

/// Presenter-only controls (English). Open from anywhere:
///
///   DemoControls.open(context);           // any widget with a context
///   DemoControls.openGlobal();            // from non-widget code
///
/// Reached by long-press on the Demo chip and from the elder phone's locked
/// settings (long-press logo 3 s -> PIN 1947).
class DemoControls {
  DemoControls._();

  // Debounce only. A sheet whose route is removed by goRoot() never completes
  // its future, so an "is open" flag would stay stuck and block the next open.
  static DateTime? _last;

  static Future<void> open(BuildContext context) async {
    final n = DateTime.now();
    if (_last != null &&
        n.difference(_last!) < const Duration(milliseconds: 700)) return;
    _last = n;
    {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: YaadainTheme.paper,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => const FamilyTheme(child: DemoControlsSheet()),
      );
    }
  }

  static Future<void> openGlobal() async {
    final ctx = appNavigatorKey.currentContext;
    if (ctx != null) await open(ctx);
  }
}

/// The sheet body. Exposed so the golden harness / settings can embed it.
class DemoControlsSheet extends StatelessWidget {
  const DemoControlsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final nav = Navigator.of(context);
    final mq = MediaQuery.of(context);

    void run(Future<void> Function() f, {bool close = false, String? done}) {
      f().catchError((_) {});
      if (close && nav.canPop()) nav.pop();
      // Never show an English toast over an Urdu elder screen.
      if (done != null && !app.isElder) {
        final m = ScaffoldMessenger.maybeOf(context);
        m?.showSnackBar(SnackBar(
            content: EnText(done, color: Colors.white, weight: FontWeight.w700),
            duration: const Duration(seconds: 2)));
      }
    }

    Future<void> switchTo(DemoView v) async {
      await app.switchView(v);
      if (nav.canPop()) nav.pop();
      goRoot(app.initialRoute);
      ElderReaction.rearm();
    }

    final view = app.currentView;
    final ov = AppClock.isOverridden;
    final h = AppClock.now().hour;
    final alert = app.activeAlert;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + mq.padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: YaadainTheme.line,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Row(children: [
              Expanded(
                  child: EnText('Presenter controls',
                      size: 24, weight: FontWeight.w600, display: true)),
              DemoChip(),
            ]),
            const SizedBox(height: 4),
            const EnText(
                'Run the whole story on one phone. Not shown to families.',
                size: 14,
                color: YaadainTheme.muted,
                weight: FontWeight.w600),
            const SizedBox(height: 16),
            const _Label('Phone view'),
            Row(children: [
              _Seg('Elder', view == DemoView.elder,
                  () => switchTo(DemoView.elder)),
              const SizedBox(width: 8),
              _Seg('Bilal', view == DemoView.bilal,
                  () => switchTo(DemoView.bilal)),
              const SizedBox(width: 8),
              _Seg('Fatima', view == DemoView.fatima,
                  () => switchTo(DemoView.fatima)),
            ]),
            const SizedBox(height: 20),
            const _Label('Story'),
            FamilyButton(
              'Simulate leaving',
              icon: YI.mapPin,
              kind: FamilyButtonKind.care,
              expand: true,
              onTap: () => run(() => app.tracking.simulateLeaving(),
                  close: true, done: 'Dada Jaan is walking out of the zone'),
            ),
            const SizedBox(height: 8),
            FamilyButton(
              alert == null ? 'Fire the alert now' : 'Bilal: I’m on my way',
              icon: alert == null ? YI.bell : YI.walking,
              kind: FamilyButtonKind.quiet,
              expand: true,
              onTap: () => alert == null
                  ? run(() => app.tracking.fireAlertNow(), done: 'Alert raised')
                  : run(
                      () =>
                          app.tracking.onMyWay(by: 'Bilal', memberId: 'bilal'),
                      close: true,
                      done: 'Bilal is on his way'),
            ),
            const SizedBox(height: 8),
            FamilyButton(
              'Mark found / back home',
              icon: YI.checkCircle,
              kind: FamilyButtonKind.quiet,
              expand: true,
              onTap: () =>
                  run(() => app.markFound(), close: true, done: 'Alert closed'),
            ),
            const SizedBox(height: 20),
            const _Label('Time of day'),
            Row(children: [
              _Seg(
                  'Real time',
                  !AppClock.isOverridden,
                  () => run(() async {
                        app.clearTimePreview();
                        if (view == DemoView.elder) {
                          goRoot(app.initialRoute);
                          ElderReaction.rearm();
                        }
                      }, close: true)),
              const SizedBox(width: 8),
              _Seg(
                  'Day',
                  ov && h >= 5 && h < 17,
                  () => run(() async {
                        app.previewTime(10, 30);
                        if (view == DemoView.elder) {
                          goRoot(app.initialRoute);
                          ElderReaction.rearm();
                        }
                      }, close: true, done: 'Previewing 10:30 am')),
              const SizedBox(width: 8),
              _Seg(
                  'Evening',
                  ov && h >= 17 && h < 21,
                  () => run(() async {
                        app.previewTime(17, 10);
                        if (view == DemoView.elder) {
                          goRoot(app.initialRoute);
                          ElderReaction.rearm();
                        }
                      }, close: true, done: 'Previewing 5:10 pm')),
              const SizedBox(width: 8),
              _Seg(
                  'Night',
                  ov && (h >= 21 || h < 5),
                  () => run(() async {
                        app.previewTime(23, 30);
                        if (view == DemoView.elder) {
                          goRoot(app.initialRoute);
                          ElderReaction.rearm();
                        }
                      }, close: true, done: 'Previewing 11:30 pm')),
            ]),
            const SizedBox(height: 20),
            const _Label('Data'),
            FamilyButton(
              'Test routine prompt',
              icon: YI.pill,
              kind: FamilyButtonKind.quiet,
              expand: true,
              onTap: () {
                if (nav.canPop()) nav.pop();
                if (!app.isElder) {
                  switchTo(DemoView.elder).then((_) => Future<void>.delayed(
                      const Duration(milliseconds: 400),
                      app.testRoutinePrompt));
                } else {
                  app.testRoutinePrompt();
                }
              },
            ),
            const SizedBox(height: 8),
            FamilyButton(
              app.hasDemoData ? 'Reload demo family' : 'Load demo family',
              icon: YI.users,
              kind: FamilyButtonKind.quiet,
              expand: true,
              onTap: () => run(() => app.loadDemoFamily(view: view),
                  close: true, done: 'Demo family loaded'),
            ),
            const SizedBox(height: 8),
            FamilyButton(
              'Reset demo',
              icon: YI.refresh,
              kind: FamilyButtonKind.quiet,
              expand: true,
              onTap: () => run(() async {
                await app.resetDemo();
                {
                  goRoot(app.initialRoute);
                  ElderReaction.rearm();
                }
              }, close: true, done: 'Demo reset'),
            ),
            const SizedBox(height: 8),
            FamilyButton(
              'Erase everything and start over',
              icon: YI.trash,
              kind: FamilyButtonKind.quiet,
              expand: true,
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => FamilyTheme(
                    child: AlertDialog(
                      title: const EnText('Erase everything?',
                          size: 20, weight: FontWeight.w700, display: true),
                      content: const EnText(
                          'This removes the family, recordings and settings on this phone.',
                          size: 15),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const EnText('Cancel',
                                weight: FontWeight.w800)),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const EnText('Erase',
                                weight: FontWeight.w800,
                                color: YaadainTheme.accentDark)),
                      ],
                    ),
                  ),
                );
                if (ok == true) {
                  await app.resetAll();
                  if (nav.canPop()) nav.pop();
                  goRoot(Routes.splash);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EnText.eyebrow(text.toUpperCase()),
      );
}

class _Seg extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Seg(this.label, this.on, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: on,
        child: Material(
          color: on ? YaadainTheme.primarySoft : YaadainTheme.surface,
          borderRadius: YaadainTheme.radius12,
          child: InkWell(
            borderRadius: YaadainTheme.radius12,
            onTap: onTap,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: YaadainTheme.radius12,
                border: Border.all(
                    color: on ? YaadainTheme.primary : YaadainTheme.line,
                    width: on ? 1.5 : 1),
              ),
              child: EnText(label,
                  size: 14,
                  weight: FontWeight.w800,
                  color: on ? YaadainTheme.primaryDark : YaadainTheme.ink),
            ),
          ),
        ),
      ),
    );
  }
}
