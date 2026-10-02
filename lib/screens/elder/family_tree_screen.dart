import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/family_member.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import 'widgets/elder_b_widgets.dart';

/// میرا خاندان: the family by generation. Tap a face to open MemberDetail.
class FamilyTreeScreen extends StatelessWidget {
  const FamilyTreeScreen({super.key});

  static const _elders = {
    'walid',
    'walida',
    'chacha',
    'phupho',
    'mamu',
    'khala',
    'taya',
    'chachi',
    'tai',
    'mumani',
    'khalu',
    'phupha',
    'dada',
    'dadi',
    'nana',
    'nani',
  };
  static const _children = {'beta', 'beti', 'bahu', 'damaad'};
  static const _grand = {'pota', 'poti', 'nawasa', 'nawasi'};

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final members = app.members;
    final peers = <FamilyMember>[];
    final kids = <FamilyMember>[];
    final grand = <FamilyMember>[];
    final elders = <FamilyMember>[];
    for (final m in members) {
      final r = m.relationshipId;
      if (_children.contains(r)) {
        kids.add(m);
      } else if (_grand.contains(r)) {
        grand.add(m);
      } else if (_elders.contains(r)) {
        elders.add(m);
      } else {
        peers.add(m);
      }
    }

    final sections = <Widget>[];
    void add(String title, List<FamilyMember> list, {bool stacked = false}) {
      if (list.isEmpty) return;
      sections.add(Padding(
        padding: EdgeInsets.only(top: sections.isEmpty ? 4 : 16, bottom: 8),
        child: EbSectionTitle(title, stacked: stacked),
      ));
      sections.add(_Grid(list));
    }

    add('آپ کے ہم عمر', peers);
    add('آپ کی اولاد', kids);
    add('آپ کے پوتے پوتیاں اور نواسے نواسیاں', grand, stacked: true);
    add('آپ کے بزرگ', elders);

    return ElderScaffold(
      title: 'میرا خاندان',
      body: members.isEmpty
          ? const EbEmptyNote('ابھی کوئی نام شامل نہیں کیا گیا۔')
          : Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 48),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: sections),
            ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<FamilyMember> list;
  const _Grid(this.list);

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final pairs = list.length ~/ 2;
    for (var i = 0; i < pairs; i++) {
      rows.add(IntrinsicHeight(
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Tile(list[i * 2])),
            const SizedBox(width: 12),
            Expanded(child: _Tile(list[i * 2 + 1])),
          ],
        ),
      ));
    }
    if (list.length.isOdd) rows.add(_WideTile(list.last));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          rows[i],
        ],
      ],
    );
  }
}

void _open(BuildContext context, FamilyMember m) =>
    Navigator.pushNamed(context, Routes.memberDetail,
        arguments: MemberDetailArgs(m.id));

class _Tile extends StatelessWidget {
  final FamilyMember m;
  const _Tile(this.m);

  @override
  Widget build(BuildContext context) {
    final label =
        hasOwnName(m) ? '${m.displayUr}، ${m.kinshipUrdu}' : m.displayUr;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: YaadainTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: YaadainTheme.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _open(context, m),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 3),
                Align(child: EbFace(m, size: 128, badge: true)),
                const SizedBox(height: 4),
                UrduText(m.displayUr,
                    size: 28, height: 1.8, align: TextAlign.center),
                if (hasOwnName(m))
                  UrduText(m.kinshipUrdu,
                      size: 24,
                      height: 1.8,
                      color: YaadainTheme.muted,
                      align: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WideTile extends StatelessWidget {
  final FamilyMember m;
  const _WideTile(this.m);

  @override
  Widget build(BuildContext context) {
    final label =
        hasOwnName(m) ? '${m.displayUr}، ${m.kinshipUrdu}' : m.displayUr;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: YaadainTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: YaadainTheme.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _open(context, m),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                EbFace(m, size: 128, badge: true),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UrduText(m.displayUr, size: 28, height: 1.8),
                      if (hasOwnName(m))
                        UrduText(m.kinshipUrdu,
                            size: 24, height: 1.8, color: YaadainTheme.muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
