import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadain/data/demo_seed.dart';
import 'package:yaadain/models/memory_story.dart';
import 'package:yaadain/screens/elder/family_tree_screen.dart';
import 'package:yaadain/screens/elder/member_detail_screen.dart';
import 'package:yaadain/screens/elder/poochhein_screen.dart';
import 'package:yaadain/screens/elder/voices_screen.dart';
import 'package:yaadain/screens/elder/who_is_this_screen.dart';

import 'harness.dart';

Future<void> _done(WidgetTester tester, String name) async {
  await settle(tester);
  expect(tester.takeException(), isNull);
  await snap(tester, name);
}

void main() {
  testWidgets('FamilyTree', (tester) async {
    await pumpScreen(tester, const FamilyTreeScreen(), height: 1200);
    await _done(tester, 'FamilyTree');
  });

  testWidgets('FamilyTree empty', (tester) async {
    await pumpScreen(tester, const FamilyTreeScreen(), seeded: false);
    await _done(tester, 'FamilyTree_empty');
  });

  testWidgets('WhoIsThis none', (tester) async {
    await pumpScreen(tester, const WhoIsThisScreen(), height: 1100);
    await _done(tester, 'WhoIsThis_none');
  });

  testWidgets('WhoIsThis selected', (tester) async {
    final app = await pumpScreen(tester, const WhoIsThisScreen());
    app.memberById(DemoIds.maryam)!.greetingAudioPath = '/tmp/maryam.m4a';
    app.refresh();
    await settle(tester);
    await tester.tapAt(const Offset(100, 400));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'WhoIsThis');
  });

  testWidgets('WhoIsThis empty', (tester) async {
    await pumpScreen(tester, const WhoIsThisScreen(), seeded: false);
    await _done(tester, 'WhoIsThis_empty');
  });

  testWidgets('MemberDetail', (tester) async {
    final app = await pumpScreen(tester, const MemberDetailScreen(memberId: DemoIds.bilal), height: 1100);
    final m = app.memberById(DemoIds.bilal)!;
    m.greetingAudioPath = '/tmp/bilal.m4a';
    m.stories
      ..add(MemoryStory(id: 's1', title: 'عید کی صبح', audioPath: '/tmp/s1.m4a'))
      ..add(MemoryStory(id: 's2', title: 'گاؤں کا پرانا گھر', audioPath: '/tmp/s2.m4a'));
    app.refresh();
    await _done(tester, 'MemberDetail');
  });

  testWidgets('MemberDetail bare', (tester) async {
    await pumpScreen(tester, const MemberDetailScreen(memberId: DemoIds.zaid));
    await _done(tester, 'MemberDetail_bare');
  });

  testWidgets('MemberDetail deceased', (tester) async {
    await pumpScreen(tester, const MemberDetailScreen(memberId: DemoIds.ruqayya));
    await _done(tester, 'MemberDetail_memorial');
  });

  testWidgets('MemberDetail missing', (tester) async {
    await pumpScreen(tester, const MemberDetailScreen(memberId: 'nobody'), seeded: false);
    await _done(tester, 'MemberDetail_missing');
  });

  testWidgets('Poochhein idle', (tester) async {
    await pumpScreen(tester, const PoochheinScreen(), height: 1000);
    await _done(tester, 'Poochhein_idle');
  });

  testWidgets('Poochhein answer', (tester) async {
    final app = await pumpScreen(tester, const PoochheinScreen(), height: 1000);
    app.answerFor('day').audioPath = '/tmp/day.m4a';
    app.answerFor('day').durationSec = 6;
    await tester.tap(find.text('آج کون سا دن ہے؟'));
    await tester.pump(const Duration(milliseconds: 1500));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'Poochhein');
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('Poochhein text only and empty', (tester) async {
    await pumpScreen(tester, const PoochheinScreen(), height: 1000, seeded: false);
    await tester.tap(find.text('رقیہ کہاں ہیں؟'));
    await _done(tester, 'Poochhein_empty');
  });

  testWidgets('Voices', (tester) async {
    await pumpScreen(tester, const VoicesScreen());
    await _done(tester, 'Voices');
  });

  testWidgets('Voices empty', (tester) async {
    await pumpScreen(tester, const VoicesScreen(), seeded: false);
    await _done(tester, 'Voices_empty');
  });
}
