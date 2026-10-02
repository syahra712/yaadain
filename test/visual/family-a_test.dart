import 'package:flutter_test/flutter_test.dart';
import 'package:yaadain/screens/family/care_circle_screen.dart';
import 'package:yaadain/screens/family/caregiver_home_screen.dart';
import 'package:yaadain/screens/family/family_home_screen.dart';
import 'package:yaadain/screens/family/weekly_report_screen.dart';
import 'harness.dart';

void main() {
  testWidgets('CaregiverHome', (tester) async {
    await pumpScreen(tester, const CaregiverHomeScreen(), role: DemoView.bilal, height: 1640);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamA_CaregiverHome');
  });

  testWidgets('FamilyHome', (tester) async {
    await pumpScreen(tester, const FamilyHomeScreen(), role: DemoView.fatima, height: 1400);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamA_FamilyHome');
  });

  testWidgets('FamilyHome alert', (tester) async {
    final app = await pumpScreen(tester, const FamilyHomeScreen(), role: DemoView.fatima, height: 1500);
    await app.tracking.fireAlertNow();
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamA_FamilyHome_alert');
  });

  testWidgets('CareCircle', (tester) async {
    await pumpScreen(tester, const CareCircleScreen(), role: DemoView.bilal, height: 1500);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamA_CareCircle');
  });

  testWidgets('WeeklyReport', (tester) async {
    await pumpScreen(tester, const WeeklyReportScreen(), role: DemoView.bilal, height: 1380);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamA_WeeklyReport');
  });

  testWidgets('empty family', (tester) async {
    for (final w in [const CaregiverHomeScreen(), const FamilyHomeScreen(), const CareCircleScreen(), const WeeklyReportScreen()]) {
      await pumpScreen(tester, w, role: DemoView.bilal, seeded: false, height: 1400);
      expect(tester.takeException(), isNull, reason: '${w.runtimeType} empty');
    }
    await snap(tester, 'FamA_Empty_WeeklyReport');
  });
}
