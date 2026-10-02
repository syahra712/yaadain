import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadain/screens/onboarding/consent_record_screen.dart';
import 'package:yaadain/screens/onboarding/elder_phone_setup_screen.dart';
import 'package:yaadain/screens/onboarding/join_family_screen.dart';
import 'package:yaadain/screens/onboarding/khayal_screen.dart';
import 'package:yaadain/screens/onboarding/permissions_screen.dart';
import 'package:yaadain/screens/onboarding/role_selection_screen.dart';
import 'package:yaadain/screens/onboarding/splash_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('Splash', (tester) async {
    await pumpScreen(tester, const SplashScreen(autoAdvance: false), seeded: false);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Onb_Splash');
  });

  testWidgets('RoleSelection', (tester) async {
    await pumpScreen(tester, const RoleSelectionScreen(), seeded: false);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Onb_RoleSelection');
  });

  testWidgets('JoinFamily', (tester) async {
    await pumpScreen(tester, const JoinFamilyScreen(code: 'YD-7F3K'), role: DemoView.fatima, seeded: false, height: 1000);
    await tester.enterText(find.byType(TextField).at(1), 'Fatima');
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await snap(tester, 'Onb_JoinFamily');
  });

  testWidgets('JoinFamily empty', (tester) async {
    await pumpScreen(tester, const JoinFamilyScreen(), seeded: false, height: 1000);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Onb_JoinFamily_empty');
  });

  testWidgets('ElderPhoneSetup', (tester) async {
    await pumpScreen(tester, const ElderPhoneSetupScreen(), seeded: true, height: 1440);
    await tester.enterText(find.byType(TextField).at(0), 'Muhammad Akram');
    await tester.enterText(find.byType(TextField).at(4), '78');
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await snap(tester, 'Onb_ElderPhoneSetup');
  });

  testWidgets('ElderPhoneSetup empty install', (tester) async {
    await pumpScreen(tester, const ElderPhoneSetupScreen(), seeded: false, height: 1440);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Onb_ElderPhoneSetup_empty');
  });

  testWidgets('Permissions', (tester) async {
    await pumpScreen(tester, const PermissionsScreen(), seeded: true, height: 1100);
    await settle(tester);
    // Allow microphone (second Allow button) to match the board.
    final allow = find.text('Allow');
    if (allow.evaluate().length > 1) {
      await tester.tap(allow.first);
      await settle(tester);
    }
    expect(tester.takeException(), isNull);
    await snap(tester, 'Onb_Permissions');
  });

  testWidgets('Khayal', (tester) async {
    await pumpScreen(tester, const KhayalScreen(), seeded: true);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Onb_Khayal');
  });

  testWidgets('Khayal empty family', (tester) async {
    await pumpScreen(tester, const KhayalScreen(), seeded: false);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Onb_Khayal_empty');
  });

  testWidgets('ConsentRecord', (tester) async {
    await pumpScreen(tester, const ConsentRecordScreen(), seeded: true, height: 1300);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Onb_ConsentRecord');
  });

  testWidgets('ConsentRecord no consent', (tester) async {
    await pumpScreen(tester, const ConsentRecordScreen(), seeded: false, height: 1300);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Onb_ConsentRecord_empty');
  });
}
