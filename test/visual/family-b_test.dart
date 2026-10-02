import 'package:flutter_test/flutter_test.dart';
import 'package:yaadain/data/demo_seed.dart';
import 'package:yaadain/screens/family/add_relative_screen.dart';
import 'package:yaadain/screens/family/answers_editor_screen.dart';
import 'package:yaadain/screens/family/record_hello_screen.dart';
import 'package:yaadain/screens/family/routine_screen.dart';
import 'harness.dart';

void main() {
  testWidgets('AddRelative edit (Maryam, picker open)', (tester) async {
    await pumpScreen(tester, const AddRelativeScreen(memberId: DemoIds.maryam), role: DemoView.bilal, height: 1500);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text("Granddaughter (son's side)"));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamB_AddRelative_edit');
    await tester.tap(find.text('Record hello'));
    for (var i = 0; i < 18; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.text('Stop'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamB_AddRelative_recorded');
  });

  testWidgets('AddRelative add + validation', (tester) async {
    await pumpScreen(tester, const AddRelativeScreen(), role: DemoView.bilal, height: 1500);
    await settle(tester);
    await snap(tester, 'FamB_AddRelative_add');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamB_AddRelative_errors');
  });

  testWidgets('AddRelative empty family', (tester) async {
    await pumpScreen(tester, const AddRelativeScreen(), role: DemoView.bilal, seeded: false, height: 1500);
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AnswersEditor', (tester) async {
    await pumpScreen(tester, const AnswersEditorScreen(), role: DemoView.bilal, height: 1100);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamB_AnswersEditor');
  });

  testWidgets('AnswersEditor empty', (tester) async {
    await pumpScreen(tester, const AnswersEditorScreen(), role: DemoView.bilal, seeded: false, height: 1100);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamB_AnswersEditor_empty');
  });

  testWidgets('Routine', (tester) async {
    await pumpScreen(tester, const RoutineScreen(), role: DemoView.bilal, height: 1300);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamB_Routine');
  });

  testWidgets('Routine empty', (tester) async {
    await pumpScreen(tester, const RoutineScreen(), role: DemoView.bilal, seeded: false, height: 1300);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamB_Routine_empty');
  });

  testWidgets('RecordHello idle', (tester) async {
    await pumpScreen(tester, const RecordHelloScreen(), role: DemoView.bilal, height: 844);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamB_RecordHello');
  });

  testWidgets('RecordHello recorded', (tester) async {
    await pumpScreen(tester, const RecordHelloScreen(), role: DemoView.bilal, height: 844);
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Start recording'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.bySemanticsLabel('Stop recording'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'FamB_RecordHello_recorded');
  });
}
