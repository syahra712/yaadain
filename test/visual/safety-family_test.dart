import 'package:flutter_test/flutter_test.dart';
import 'package:yaadain/screens/safety/alert_detail_screen.dart';
import 'package:yaadain/screens/safety/find_abu_screen.dart';
import 'package:yaadain/screens/safety/safe_zones_screen.dart';
import 'package:yaadain/screens/safety/where_is_abu_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('WhereIsAbu at home', (tester) async {
    await pumpScreen(tester, const WhereIsAbuScreen(), role: DemoView.bilal, height: 1400);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'WhereIsAbu');
  });

  testWidgets('WhereIsAbu outside', (tester) async {
    final app = await pumpScreen(tester, const WhereIsAbuScreen(), role: DemoView.bilal, height: 1400);
    await app.tracking.fireAlertNow();
    await settle(tester, frames: 20);
    expect(tester.takeException(), isNull);
    await snap(tester, 'WhereIsAbu_outside');
  });

  testWidgets('WhereIsAbu Fatima limited', (tester) async {
    await pumpScreen(tester, const WhereIsAbuScreen(), role: DemoView.fatima, height: 1200);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'WhereIsAbu_fatima');
  });

  testWidgets('WhereIsAbu empty family', (tester) async {
    await pumpScreen(tester, const WhereIsAbuScreen(), seeded: false, height: 900);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'WhereIsAbu_empty');
  });

  testWidgets('AlertDetail', (tester) async {
    final app = await pumpScreen(tester, const AlertDetailScreen(), role: DemoView.bilal, height: 1000);
    await app.tracking.fireAlertNow();
    await settle(tester, frames: 20);
    expect(tester.takeException(), isNull);
    await snap(tester, 'AlertDetail');
  });

  testWidgets('AlertDetail on my way', (tester) async {
    final app = await pumpScreen(tester, const AlertDetailScreen(), role: DemoView.bilal, height: 1000);
    await app.tracking.fireAlertNow();
    await settle(tester, frames: 10);
    await app.imOnMyWay();
    await settle(tester, frames: 20);
    expect(tester.takeException(), isNull);
    await snap(tester, 'AlertDetail_coming');
  });

  testWidgets('AlertDetail no alert', (tester) async {
    await pumpScreen(tester, const AlertDetailScreen(), role: DemoView.bilal, height: 844);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'AlertDetail_none');
  });

  testWidgets('SafeZones', (tester) async {
    await pumpScreen(tester, const SafeZonesScreen(), role: DemoView.bilal, height: 1200);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'SafeZones');
  });

  testWidgets('SafeZones empty family', (tester) async {
    await pumpScreen(tester, const SafeZonesScreen(), seeded: false, height: 844);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'SafeZones_empty');
  });

  testWidgets('FindAbu', (tester) async {
    final app = await pumpScreen(tester, const FindAbuScreen(), role: DemoView.bilal, height: 1400);
    await app.tracking.fireAlertNow();
    await settle(tester, frames: 20);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FindAbu');
  });

  testWidgets('FindAbu empty family', (tester) async {
    await pumpScreen(tester, const FindAbuScreen(), seeded: false, height: 1200);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FindAbu_empty');
  });
}
