import 'package:flutter_test/flutter_test.dart';
import 'package:yaadain/data/demo_seed.dart';
import 'package:yaadain/models/memory_story.dart';
import 'package:yaadain/screens/elder/elder_home_screen.dart';
import 'package:yaadain/screens/elder/night_anchor_screen.dart';
import 'package:yaadain/screens/elder/routine_prompt_screen.dart';
import 'package:yaadain/screens/elder/sukoon_screen.dart';

import 'harness.dart';

Future<void> _done(WidgetTester tester, String name) async {
  await settle(tester);
  expect(tester.takeException(), isNull);
  await snap(tester, name);
}

Future<void> _addStory(AppState app) async {
  final m = app.memberById(DemoIds.bilal)!;
  m.stories.add(MemoryStory(id: 's1', title: 'عید کی نماز، بلال کی زبانی'));
  await app.upsertMember(m);
}

void main() {
  testWidgets('Main', (tester) async {
    final app = await pumpScreen(tester, const ElderHomeScreen(), height: 1380);
    await _addStory(app);
    await _done(tester, 'Main');
  });

  testWidgets('Main 844', (tester) async {
    final app = await pumpScreen(tester, const ElderHomeScreen());
    await _addStory(app);
    await _done(tester, 'Main_844');
  });

  testWidgets('ElderHomeEvening', (tester) async {
    await pumpScreen(tester, const ElderHomeScreen(), now: DateTime(2026, 10, 3, 17, 10));
    await _done(tester, 'ElderHomeEvening');
  });

  testWidgets('NightAnchor', (tester) async {
    await pumpScreen(tester, const NightAnchorScreen(), now: DateTime(2026, 10, 3, 2, 0));
    await _done(tester, 'NightAnchor');
  });

  testWidgets('RoutinePrompt', (tester) async {
    final app = await pumpScreen(tester, const RoutinePromptScreen(), now: DateTime(2026, 10, 3, 8, 5));
    expect(app.care.routine, isNotEmpty);
    await _done(tester, 'RoutinePrompt');
  });

  testWidgets('Sukoon', (tester) async {
    await pumpScreen(tester, const SukoonScreen());
    await _done(tester, 'Sukoon');
  });

  testWidgets('empty family', (tester) async {
    await pumpScreen(tester, const ElderHomeScreen(), seeded: false);
    await _done(tester, 'ElderHome_empty');
    await pumpScreen(tester, const NightAnchorScreen(), seeded: false, now: DateTime(2026, 10, 3, 2, 0));
    await _done(tester, 'NightAnchor_empty');
    await pumpScreen(tester, const RoutinePromptScreen(), seeded: false);
    await _done(tester, 'RoutinePrompt_empty');
    await pumpScreen(tester, const SukoonScreen(), seeded: false);
    await _done(tester, 'Sukoon_empty');
  });
}
