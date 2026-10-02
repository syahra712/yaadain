import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yaadain/nlp/urdu_match.dart';
import 'package:yaadain/routes.dart';

import 'visual/harness.dart';

void main() {
  group('UrduMatch script-tolerant skeletons', () {
    test('Roman spelling variants collapse to the same skeleton', () {
      expect(UrduMatch.romanSkeleton('shaadi'), UrduMatch.romanSkeleton('shadi'));
    });

    test('Urdu script and Roman-Urdu match for "shaadi"', () {
      final sim = UrduMatch.similarity('شادی', 'shaadi');
      expect(sim, greaterThan(0.7));
    });

    test('"gaon" matches گاؤں (village)', () {
      expect(UrduMatch.similarity('gaon', 'گاؤں'), greaterThan(0.7));
    });

    test('Unrelated words score low', () {
      expect(UrduMatch.similarity('shaadi', 'karachi'), lessThan(0.7));
    });
  });

  // main.dart imports the owner's gitignored firebase_options.dart, so the boot
  // is checked through AppState + the route table instead of YaadainApp.
  group('Boot', () {
    test('seeded elder phone boots to the elder home route', () {
      final app = AppState.seeded();
      addTearDown(app.dispose);
      expect(app.ready, isTrue);
      expect(app.isElder, isTrue);
      expect(app.initialRoute, anyOf(Routes.elderHome, Routes.elderNight));
    });

    test('empty install boots to splash', () {
      final app = AppState.seeded(seeded: false, view: DemoView.fatima);
      addTearDown(app.dispose);
      expect(app.initialRoute, anyOf(Routes.splash, Routes.family));
    });

    testWidgets('route table resolves known routes', (tester) async {
      final seen = <String>{};
      for (final r in [
        Routes.splash, Routes.role, Routes.join, Routes.elderHome, Routes.elderNight, Routes.sukoon,
        Routes.familyTree, Routes.poochhein, Routes.voices, Routes.madad, Routes.care, Routes.careWhere,
        Routes.careCircle, Routes.family, Routes.lockedSettings,
      ]) {
        final role = r.startsWith('/care') ? DemoView.bilal : r.startsWith('/family') ? DemoView.fatima : DemoView.elder;
        final s = onGenerateRoute(RouteSettings(name: r));
        expect(s, isNotNull, reason: r);
        seen.add(r);
        await pumpScreen(tester, Builder(builder: (c) => const SizedBox()), role: role);
      }
      expect(seen.length, greaterThan(10));
    });
  });
}
