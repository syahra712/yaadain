import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadain/data/demo_seed.dart';
import 'package:yaadain/routes.dart';
import 'package:yaadain/screens/safety/if_found_screen.dart';
import 'package:yaadain/screens/safety/im_safe_screen.dart';
import 'package:yaadain/screens/safety/madad_screen.dart';

import 'harness.dart';

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

void main() {
  testWidgets('Madad at home', (tester) async {
    await pumpScreen(tester, const MadadScreen());
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Madad_home');
  });

  testWidgets('Madad outside', (tester) async {
    final app = await pumpScreen(tester, const SizedBox());
    await app.tracking.fireAlertNow();
    appNavigatorKey.currentState!.pushReplacement(MaterialPageRoute<void>(builder: (_) => const MadadScreen()));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Madad');
  });

  testWidgets('Madad empty family', (tester) async {
    await pumpScreen(tester, const MadadScreen(), seeded: false);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Madad_empty');
  });

  testWidgets('ImSafe visit', (tester) async {
    final app = await pumpScreen(tester, const ImSafeScreen(byName: 'Bilal', memberId: DemoIds.bilal, etaMin: 10));
    app.memberById(DemoIds.bilal)!.greetingAudioPath = '/tmp/bilal-hello.m4a';
    app.refresh();
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'ImSafe');
  });

  testWidgets('ImSafe visit without voice', (tester) async {
    await pumpScreen(tester, const ImSafeScreen(byName: 'Bilal', memberId: DemoIds.bilal, etaMin: 8));
    expect(tester.takeException(), isNull);
    await snap(tester, 'ImSafe_novoice');
  });

  testWidgets('ImSafe back home', (tester) async {
    await pumpScreen(tester, const ImSafeScreen());
    expect(tester.takeException(), isNull);
    await snap(tester, 'ImSafe_home');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ImSafe empty family', (tester) async {
    await pumpScreen(tester, const ImSafeScreen(byName: 'Bilal', etaMin: 8), seeded: false);
    expect(tester.takeException(), isNull);
    await snap(tester, 'ImSafe_empty');
  });

  testWidgets('IfFoundUr', (tester) async {
    await pumpScreen(tester, const IfFoundScreen());
    expect(tester.takeException(), isNull);
    await snap(tester, 'IfFoundUr');
  });

  testWidgets('IfFoundEn via globe', (tester) async {
    await pumpScreen(tester, const IfFoundScreen());
    await tester.tap(_label('English'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'IfFoundEn');
    await tester.tap(_label('Urdu'));
    await settle(tester);
    expect(_label('English'), findsOneWidget);
  });

  testWidgets('IfFound empty family', (tester) async {
    await pumpScreen(tester, const IfFoundScreen(), seeded: false);
    expect(tester.takeException(), isNull);
    await snap(tester, 'IfFound_empty_ur');
    await pumpScreen(tester, const IfFoundScreen(english: true), seeded: false);
    expect(tester.takeException(), isNull);
    await snap(tester, 'IfFound_empty_en');
  });

  testWidgets('IfFound Back returns to Madad', (tester) async {
    await pumpScreen(tester, const SizedBox());
    final nav = appNavigatorKey.currentState!;
    nav.pushNamed(Routes.madad);
    await settle(tester);
    nav.pushNamed(Routes.ifFound, arguments: const IfFoundArgs());
    await settle(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(IfFoundScreen), findsNothing);
    expect(find.byType(MadadScreen), findsOneWidget);
  });

  testWidgets('IfFound Back with nothing underneath keeps the app open', (tester) async {
    final exits = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') exits.add(call.method);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpScreen(tester, const IfFoundScreen());
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(exits, isEmpty);
    expect(find.byType(IfFoundScreen), findsNothing);
    expect(find.byType(MadadScreen), findsOneWidget);
    expect(appNavigatorKey.currentState!.canPop(), isTrue);
  });
}
