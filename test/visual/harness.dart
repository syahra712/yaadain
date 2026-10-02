// Golden harness for screen builders.
//
//   import 'harness.dart';
//
//   void main() {
//     testWidgets('MemberDetail', (tester) async {
//       await pumpScreen(tester, const MemberDetailScreen(memberId: 'bilal'), height: 900);
//       await snap(tester, 'MemberDetail');          // -> test/visual/goldens/MemberDetail.png
//     });
//   }
//
// Real fonts (Nunito, NastaliqUrdu, Fraunces, MaterialIcons) are loaded,
// the phone is 390 x height logical px at DPR 1 (same pixels as the boards),
// demo state is injected and the plugin wrappers are fakes.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yaadain/design/design.dart';
import 'package:yaadain/routes.dart';
import 'package:yaadain/services/platform/platform.dart';
import 'package:yaadain/state/app_state.dart';
import 'package:yaadain/tracking/demo_tracking_source.dart';
import 'package:yaadain/util/app_clock.dart';

export 'package:yaadain/state/app_state.dart' show AppState, DemoView;

/// Saturday 3 October 2026, 9:41 am (the boards' status-bar time).
final DateTime kHarnessNow = DateTime(2026, 10, 3, 9, 41);

bool _fontsLoaded = false;

/// Loads the real fonts. Called by [pumpScreen]; call it yourself in
/// `setUpAll` only if you render widgets without [pumpScreen].
Future<void> loadFonts() async {
  if (_fontsLoaded) return;
  Future<ByteData> bytes(String path) async {
    final b = await File(path).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(b));
  }

  final nunito = FontLoader('Nunito')..addFont(bytes('assets/fonts/Nunito.ttf'));
  final urdu = FontLoader('NastaliqUrdu')..addFont(bytes('assets/fonts/NotoNastaliqUrdu.ttf'));
  final fraunces = FontLoader('Fraunces')
    ..addFont(bytes('assets/fonts/Fraunces-Regular.ttf'))
    ..addFont(bytes('assets/fonts/Fraunces-SemiBold.ttf'))
    ..addFont(bytes('assets/fonts/Fraunces-Bold.ttf'));
  await nunito.load();
  await urdu.load();
  await fraunces.load();

  final home = Platform.environment['HOME'] ?? '';
  final icons = File('$home/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final l = FontLoader('MaterialIcons')..addFont(bytes(icons.path));
    await l.load();
  }
  _fontsLoaded = true;
}

final GlobalKey _shotKey = GlobalKey(debugLabel: 'harness-shot');

/// Pumps [screen] inside the app shell and returns the injected [AppState].
///
/// * [role]: which phone the state represents. `DemoView.elder` (default;
///   Urdu, RTL), `DemoView.bilal` (caregiver) or `DemoView.fatima` (family).
/// * [seeded]: true = the full BRIEF demo family; false = an empty install.
/// * [now]: frozen clock (default Saturday 3 Oct 2026 9:41 am).
/// * [height]: phone height in logical px (844 fixed screens; taller to
///   capture a scrolling screen in full).
/// * [statusBar]: draw a fake 32px status bar (the real app uses SafeArea).
///
/// The screen is the Navigator's first route, so `Navigator.pushNamed(...)`
/// works against the real route table.
Future<AppState> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  DemoView role = DemoView.elder,
  bool seeded = true,
  DateTime? now,
  double height = 844,
  bool statusBar = true,
}) async {
  await tester.runAsync(loadFonts);
  Svc.useFakes();
  AppClock.freeze(now ?? kHarnessNow);
  tester.view
    ..physicalSize = Size(390, height)
    ..devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    AppClock.reset();
  });

  final app = AppState.seeded(now: now ?? kHarnessNow, view: role, seeded: seeded, tracking: DemoTrackingSource(now: AppClock.now));
  addTearDown(app.dispose);

  final elder = role == DemoView.elder;
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: app,
      child: RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          theme: elder ? YaadainTheme.elder() : YaadainTheme.family(),
          locale: elder ? const Locale('ur') : const Locale('en'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ur'), Locale('en')],
          onGenerateRoute: (s) => s.name == '/' ? MaterialPageRoute<void>(settings: s, builder: (_) => screen) : onGenerateRoute(s),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(padding: mq.padding.copyWith(top: statusBar ? 32 : 0)),
              child: Stack(
                children: [
                  Positioned.fill(child: child ?? const SizedBox()),
                  if (statusBar) const Positioned(top: 0, left: 0, right: 0, height: 32, child: IgnorePointer(child: _FakeStatusBar())),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  await settle(tester);
  return app;
}

/// Lets layout, images and short animations finish without hanging on
/// infinite animations (never use pumpAndSettle with spinners / pulses).
Future<void> settle(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Writes the current screen to `test/visual/goldens/<name>.png` (390 x height).
/// Overwrites; never fails on a missing baseline. Open the PNG with the Read tool.
Future<String> snap(WidgetTester tester, String name) async {
  final path = 'test/visual/goldens/$name.png';
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
    final image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final f = File(path);
    await f.parent.create(recursive: true);
    await f.writeAsBytes(data!.buffer.asUint8List());
  });
  return path;
}

/// Pumps a bare widget (no routes) in the family or elder shell, for gallery
/// style tests of design pieces.
Future<AppState> pumpWidgetIn(
  WidgetTester tester,
  Widget child, {
  DemoView role = DemoView.bilal,
  double height = 844,
  Color background = YaadainTheme.paper,
}) {
  final elder = role == DemoView.elder;
  return pumpScreen(
    tester,
    Scaffold(
      backgroundColor: background,
      body: elder ? ElderTheme(child: child) : FamilyTheme(child: child),
    ),
    role: role,
    height: height,
  );
}

class _FakeStatusBar extends StatelessWidget {
  const _FakeStatusBar();
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('9:41', style: YaadainTheme.en(14, weight: FontWeight.w700, color: YaadainTheme.ink)),
            const Row(children: [
              YIcon(YI.battery, size: 16, color: YaadainTheme.ink),
            ]),
          ],
        ),
        ),
      ),
    );
  }
}
