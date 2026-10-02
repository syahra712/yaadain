import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/care.dart';
import '../../models/family_member.dart';
import '../../state/app_state.dart';
import '../../util/urdu_format.dart';
import 'widgets/elder_b_widgets.dart';

/// پوچھیں: six questions he can ask as often as he likes. Every press is
/// logged; a recording plays when one exists, otherwise the text is shown.
class PoochheinScreen extends StatefulWidget {
  const PoochheinScreen({super.key});

  @override
  State<PoochheinScreen> createState() => _PoochheinScreenState();
}

class _PoochheinScreenState extends State<PoochheinScreen> {
  final EbPlayer _player = EbPlayer();
  final GlobalKey _cardKey = GlobalKey();
  String? _selected;

  @override
  void initState() {
    super.initState();
    _player.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _ask(AppState app, PoochheinQuestion q) async {
    setState(() => _selected = q.id);
    try {
      await app.recordQuestionAsked(q.id);
    } catch (_) {}
    _play(app, q.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _cardKey.currentContext;
      if (c != null)
        Scrollable.ensureVisible(c,
            duration: const Duration(milliseconds: 300), alignment: 0.3);
    });
  }

  void _play(AppState app, String qid) {
    final a = app.answerFor(qid);
    final has = (a.audioPath ?? '').isNotEmpty;
    if (has)
      _player.start('a-$qid',
          path: a.audioPath, seconds: a.durationSec, minSeconds: 3);
  }

  String _text(AppState app, String qid) {
    final t = app.answerText(qid);
    if (t.isNotEmpty && !hasLatinLetters(t)) {
      return t;
    }
    final n = app.now;
    switch (qid) {
      case 'day':
        final home = app.elderStatus?.inside != false;
        return 'آج ${UrduFmt.weekday(n)} ہے۔ ${UrduFmt.period(n)} کا وقت ہے۔${home ? ' آپ گھر پر ہیں۔' : ''}';
      case 'where':
        return 'آپ اپنے گھر میں ہیں۔ سب خیریت ہے۔';
      case 'medicine':
        return app.medicineAnswerUr();
      default:
        return 'گھر والے ابھی اس کا جواب دیں گے۔ آپ آرام سے بیٹھیں۔';
    }
  }

  FamilyMember? _responder(AppState app, String qid) {
    final by = app.answerFor(qid).byName.trim().toLowerCase();
    if (by.isNotEmpty) {
      for (final m in app.members) {
        if (m.nameEn.trim().toLowerCase() == by) {
          return m;
        }
      }
    }
    return app.primaryContact;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final rows = <Widget>[];
    for (var i = 0; i < kQuestions.length; i += 2) {
      final pair = kQuestions.sublist(
          i, i + 2 > kQuestions.length ? kQuestions.length : i + 2);
      rows.add(IntrinsicHeight(
          child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var j = 0; j < 2; j++) ...[
            if (j > 0) const SizedBox(width: 12),
            Expanded(
              child: j < pair.length
                  ? _QTile(
                      q: pair[j],
                      selected: _selected == pair[j].id,
                      onTap: () => _ask(app, pair[j]))
                  : const SizedBox(),
            ),
          ],
        ],
      )));
      rows.add(const SizedBox(height: 12));
      if (_selected != null && pair.any((q) => q.id == _selected)) {
        final qid = _selected!;
        final a = app.answerFor(qid);
        rows.add(_AnswerCard(
          key: _cardKey,
          text: _text(app, qid),
          responder: _responder(app, qid),
          hasAudio: (a.audioPath ?? '').isNotEmpty,
          playing: _player.isPlaying('a-$qid'),
          progress: _player.isPlaying('a-$qid') ? _player.progress : 0,
          onReplay: () => _play(app, qid),
        ));
        rows.add(const SizedBox(height: 12));
      }
    }
    return ElderScaffold(
      title: 'پوچھیں',
      subtitle: 'جتنی بار چاہیں پوچھیں۔',
      bodyPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }
}

class _QTile extends StatelessWidget {
  final PoochheinQuestion q;
  final bool selected;
  final VoidCallback onTap;
  const _QTile({required this.q, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: q.textUr,
      excludeSemantics: true,
      child: Material(
        color: selected ? YaadainTheme.primarySoft : YaadainTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: selected ? YaadainTheme.primary : YaadainTheme.line,
              width: selected ? 3 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            alignment: Alignment.center,
            child: UrduText(q.textUr,
                size: 24, height: 1.8, align: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final String text;
  final FamilyMember? responder;
  final bool hasAudio;
  final bool playing;
  final double progress;
  final VoidCallback onReplay;
  const _AnswerCard({
    super.key,
    required this.text,
    required this.responder,
    required this.hasAudio,
    required this.playing,
    required this.progress,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final r = responder;
    final who = r == null
        ? 'گھر والوں کا جواب'
        : '${hasOwnName(r) ? r.nameUr : r.kinshipUrdu} کا جواب';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: YaadainTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: YaadainTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              if (r != null) ...[
                EbFace(r, size: 64),
                const SizedBox(width: 12)
              ],
              Expanded(
                  child: UrduText(who,
                      size: 20, height: 1.8, color: YaadainTheme.muted)),
            ],
          ),
          const SizedBox(height: 8),
          UrduText(text, size: 28, height: 1.9),
          if (hasAudio) ...[
            const SizedBox(height: 12),
            EbWaveform(progress: progress),
            const SizedBox(height: 12),
            ElderButton('دوبارہ سنیں',
                icon: YI.volumeMirrored, onTap: onReplay),
          ],
        ],
      ),
    );
  }
}
