import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yaadain/data/demo_seed.dart';
import 'package:yaadain/design/design.dart';
import 'package:yaadain/models/family_member.dart';
import 'package:yaadain/screens/elder/elder_home_screen.dart';
import 'package:yaadain/screens/elder/member_detail_screen.dart';
import 'package:yaadain/screens/family/caregiver_home_screen.dart';
import 'package:yaadain/screens/family/family_home_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('elder stub: ElderHomeScreen', (tester) async {
    await pumpScreen(tester, const ElderHomeScreen());
    expect(find.text('آج ہفتہ ہے'), findsOneWidget);
    await snap(tester, 'Foundation_ElderHome');
  });

  testWidgets('elder stub: MemberDetailScreen shows Urdu name', (tester) async {
    await pumpScreen(tester, const MemberDetailScreen(memberId: DemoIds.bilal));
    expect(find.text('بلال'), findsOneWidget);
    await snap(tester, 'Foundation_MemberDetail');
  });

  testWidgets('caregiver stub with tabs and live alert banner', (tester) async {
    final app = await pumpScreen(tester, const CaregiverHomeScreen(), role: DemoView.bilal);
    expect(find.text('Abu'), findsOneWidget);
    await tester.runAsync(() => app.tracking.fireAlertNow());
    await settle(tester);
    expect(find.textContaining('left the home zone'), findsOneWidget);
    await snap(tester, 'Foundation_Caregiver_Alert');
  });

  testWidgets('family stub: tab is Dada Jaan', (tester) async {
    await pumpScreen(tester, const FamilyHomeScreen(), role: DemoView.fatima);
    expect(find.text('Dada Jaan'), findsOneWidget);
    await snap(tester, 'Foundation_FamilyHome');
  });

  testWidgets('empty install renders', (tester) async {
    await pumpScreen(tester, const ElderHomeScreen(), seeded: false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('widget gallery (family)', (tester) async {
    final members = demoMembers();
    await pumpWidgetIn(
      tester,
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EnText('Gallery', size: 28, weight: FontWeight.w600, display: true),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: [
              for (final m in members.take(6)) Avatar.member(m, size: 56),
              Avatar.member(members.first, size: 56),
            ]),
            const SizedBox(height: 16),
            const Wrap(spacing: 8, runSpacing: 8, children: [
              StatusChip('At home', tone: ChipTone.success, icon: YI.home),
              StatusChip('Left zone', tone: ChipTone.attention, icon: YI.alertTriangle),
              StatusChip('Help', tone: ChipTone.emergency),
              StatusChip('Phone 64%'),
              DemoChip(),
            ]),
            const SizedBox(height: 16),
            const FamilyButton('Mark found', kind: FamilyButtonKind.care, expand: true),
            const SizedBox(height: 8),
            const FamilyButton('Share code', kind: FamilyButtonKind.primary, expand: true, icon: YI.share),
            const SizedBox(height: 8),
            const FamilyButton('Not now', kind: FamilyButtonKind.quiet, expand: true),
            const SizedBox(height: 16),
            const YCard(child: EnText('A card, radius 20, line border.', size: 15)),
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: const BoxDecoration(color: YaadainTheme.primaryDark, borderRadius: YaadainTheme.radius28),
              child: const Stack(children: [
                Positioned.fill(child: JaaliPattern()),
                Center(child: LogoMark(size: 64)),
              ]),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final i in [YI.home, YI.map, YI.users, YI.bell, YI.mic, YI.pill, YI.moon, YI.shield, YI.phone, YI.heart])
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: YaadainTheme.surface, borderRadius: YaadainTheme.radius12, border: Border.all(color: YaadainTheme.line)),
                  child: Center(child: YIcon(i, size: 22)),
                ),
            ]),
          ],
        ),
      ),
      height: 900,
    );
    expect(tester.takeException(), isNull);
    await snap(tester, 'Foundation_Gallery_Family');
  });

  testWidgets('widget gallery (elder)', (tester) async {
    final members = demoMembers();
    await pumpWidgetIn(
      tester,
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const UrduText('نمونہ', size: 36, align: TextAlign.center),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [for (final m in members.take(4)) Avatar.member(m, size: 72, urdu: true)],
            ),
            const SizedBox(height: 16),
            const ElderButton('مدد کریں', kind: ElderButtonKind.care, icon: YI.lifebuoy, large: true, expand: true),
            const SizedBox(height: 12),
            const ElderButton('میرا خاندان', kind: ElderButtonKind.primary, icon: YI.users, expand: true),
            const SizedBox(height: 12),
            const ElderButton('واپس', kind: ElderButtonKind.quiet, expand: true),
            const SizedBox(height: 16),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [UrduChip('گھر پر ہیں', tone: ChipTone.success), UrduChip('دوا کا وقت', tone: ChipTone.attention)],
            ),
            const SizedBox(height: 16),
            const YCard(child: UrduText('بلال آپ کا بیٹا ہے۔ وہ کراچی میں رہتا ہے۔', size: 24)),
          ],
        ),
      ),
      role: DemoView.elder,
      height: 900,
    );
    expect(tester.takeException(), isNull);
    await snap(tester, 'Foundation_Gallery_Elder');
  });

  testWidgets('elder scaffold header + pinned action', (tester) async {
    await pumpScreen(
      tester,
      const ElderScaffold(
        title: 'میرا خاندان',
        body: StubLines(),
        bottom: ElderButton('ٹھیک ہے', kind: ElderButtonKind.primary, expand: true),
      ),
    );
    await snap(tester, 'Foundation_ElderScaffold');
  });

  test('migrated legacy member keeps name', () {
    final m = FamilyMember(id: 'x', name: 'Ali', relationshipId: 'beta');
    expect(m.name, 'Ali');
  });

  testWidgets('provider state is reachable', (tester) async {
    late AppState got;
    await pumpScreen(
      tester,
      Builder(builder: (c) {
        got = c.read<AppState>();
        return const SizedBox();
      }),
    );
    expect(got.members.length, greaterThan(5));
  });
}

class StubLines extends StatelessWidget {
  const StubLines({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 24),
        child: UrduText('یہاں مواد آئے گا۔', size: 28, align: TextAlign.center),
      );
}
