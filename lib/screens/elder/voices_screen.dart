import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/care.dart';
import '../../models/family_member.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import '../../util/urdu_format.dart';
import 'widgets/elder_b_widgets.dart';

/// آوازیں: voice letters the family sent, newest first.
class VoicesScreen extends StatelessWidget {
  const VoicesScreen({super.key});

  static String when(DateTime now, DateTime at) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final d = today.difference(day).inDays;
    if (d <= 0) {
      return 'آج ${UrduFmt.period(at)}';
    }
    if (d == 1) {
      return 'کل';
    }
    if (d < 7) {
      return '${UrduFmt.weekday(at)} کو';
    }
    if (d < 14) {
      return 'پچھلے ہفتے';
    }
    return 'کچھ عرصہ پہلے';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final rows = <Widget>[];
    for (final l in app.letters) {
      final m = app.memberById(l.memberId);
      if (m == null) continue;
      if (rows.isNotEmpty)
        rows.add(
            const Divider(height: 1, thickness: 1, color: YaadainTheme.line));
      rows.add(_Row(letter: l, member: m, when: when(app.now, l.at), app: app));
    }
    return ElderScaffold(
      title: 'آوازیں',
      subtitle: 'گھر والوں کی بھیجی ہوئی آوازیں',
      bodyPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      body: rows.isEmpty
          ? const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EbEmptyNote('ابھی کوئی نئی آواز نہیں۔'))
          : Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: YaadainTheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: YaadainTheme.line),
              ),
              child: Column(children: rows),
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final VoiceLetter letter;
  final FamilyMember member;
  final String when;
  final AppState app;
  const _Row(
      {required this.letter,
      required this.member,
      required this.when,
      required this.app});

  @override
  Widget build(BuildContext context) {
    final m = member;
    final name = hasOwnName(m) ? m.nameUr : m.kinshipUrdu;
    final sub = hasOwnName(m) ? '${m.kinshipUrdu} · $when' : when;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, Routes.memberDetail,
          arguments: MemberDetailArgs(m.id)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            EbFace(m, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Flexible(
                          child: UrduText(name,
                              size: 24,
                              height: 1.8,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      if (!letter.seen) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                          decoration: BoxDecoration(
                            color: YaadainTheme.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const UrduText('نئی',
                              size: 20,
                              height: 1.6,
                              color: YaadainTheme.primaryDark),
                        ),
                      ],
                    ],
                  ),
                  Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: UrduText(sub,
                              size: 20,
                              height: 1.7,
                              color: YaadainTheme.muted))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            EbPlayCircle(
                playing: false,
                label: 'سنیے',
                onTap: () => app.playLetter(letter)),
          ],
        ),
      ),
    );
  }
}
