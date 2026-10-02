import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/care.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import 'widgets/family_b_common.dart';

/// Caregiver: record / replace the answers the elder hears on Poochhein.
/// Route `/care/answers`.
class AnswersEditorScreen extends StatefulWidget {
  final String? questionId;
  const AnswersEditorScreen({super.key, this.questionId});

  @override
  State<AnswersEditorScreen> createState() => _AnswersEditorScreenState();
}

class _AnswersEditorScreenState extends State<AnswersEditorScreen> {
  @override
  void initState() {
    super.initState();
    final q = widget.questionId;
    if (q != null && questionById(q) != null && q != 'medicine') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openRecorder(q);
      });
    }
  }

  String _label(AppState app, String id) {
    switch (id) {
      case 'day':
        return 'What day is it?';
      case 'where':
        return 'Where am I?';
      case 'bilal':
        final p = app.primaryContact;
        final n = (p == null || p.firstNameEn.isEmpty) ? 'Bilal' : p.firstNameEn;
        return 'Where is $n?';
      case 'food':
        return 'When is food?';
      case 'medicine':
        return 'When is my medicine?';
      case 'ruqayya':
        return 'Where is Ruqayya?';
    }
    return questionById(id)?.textEn ?? id;
  }

  Future<void> _openRecorder(String id) async {
    final app = context.read<AppState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: YaadainTheme.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => ChangeNotifierProvider<AppState>.value(
        value: app,
        child: _AnswerSheet(questionId: id, title: _label(app, id)),
      ),
    );
  }

  Future<void> _play(Answer a) async {
    final p = a.audioPath;
    if (p == null) return;
    try {
      await Svc.audio.stop();
      await Svc.audio.play(p);
    } catch (_) {
      if (mounted) fbSnack(context, 'That recording cannot be played.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final today = DateTime(app.now.year, app.now.month, app.now.day);
    var asked = 0, afterFive = 0;
    for (final e in app.episodes) {
      if (e.category != 'question') continue;
      if (e.at.isBefore(today) || e.at.isAfter(today.add(const Duration(days: 1)))) continue;
      asked++;
      if (e.at.hour >= 17) afterFive++;
    }
    final rows = <Widget>[];
    for (var i = 0; i < kQuestions.length; i++) {
      final q = kQuestions[i];
      if (i > 0) rows.add(const Divider(height: 1, thickness: 1, indent: 12, color: YaadainTheme.line));
      rows.add(q.id == 'medicine' ? _medicineRow(app, q) : _questionRow(app, q));
    }

    return FamilyScaffold(
      title: 'Answers',
      body: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: StatusChip('On his phone · caregiver settings', icon: YI.lock),
            ),
            const SizedBox(height: 16),
            const EnText('He presses a button, hears your voice. As many times as he likes.',
                size: 21, weight: FontWeight.w500, display: true, height: 1.35),
            const SizedBox(height: 6),
            const EnText('Record each answer the way you would say it to him at the table. Short, warm, present tense.',
                size: 14, weight: FontWeight.w600, color: YaadainTheme.muted, height: 1.4),
            const SizedBox(height: 24),
            const FbSectionHeader('Six questions he asks'),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: YaadainTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: YaadainTheme.line),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FbSmallButton('Add a question he asks', icon: YI.plus, height: 48,
                  onTap: () => fbSnack(context, 'Custom questions are coming soon. The six above are ready now.')),
            ),
            const SizedBox(height: 16),
            YCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: YaadainTheme.tintGold.bg, borderRadius: YaadainTheme.radius12),
                    child: Center(child: YIcon(YI.barChart, size: 22, color: YaadainTheme.tintGold.fg)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EnText(
                          asked == 0
                              ? 'Not asked yet today'
                              : 'Asked $asked ${asked == 1 ? 'time' : 'times'} today · $afterFive after 5 pm',
                          size: 15,
                          weight: FontWeight.w800,
                          height: 1.3,
                        ),
                        const SizedBox(height: 2),
                        const EnText('Every press goes into the weekly report. He never sees a count.',
                            size: 13, weight: FontWeight.w600, color: YaadainTheme.muted, height: 1.35),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medicineRow(AppState app, PoochheinQuestion q) {
    return Semantics(
      button: true,
      label: 'When is my medicine? Linked to Routine',
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(Routes.careRoutine),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
          child: Row(
            children: [
              Expanded(child: _rowText(_label(app, q.id), 'Linked to Routine · reads his next prompt')),
              const YIcon(YI.chevronRight, size: 20, color: YaadainTheme.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowText(String title, String sub, {Widget? subWidget}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EnText(title, size: 15, weight: FontWeight.w800, height: 1.25),
          const SizedBox(height: 2),
          subWidget ?? EnText(sub, size: 13, weight: FontWeight.w600, color: YaadainTheme.muted, height: 1.3),
        ],
      );

  Widget _questionRow(AppState app, PoochheinQuestion q) {
    final a = app.answerFor(q.id);
    final title = _label(app, q.id);
    final recorded = a.isRecorded && (a.audioPath != null || a.hasText);
    if (!recorded) {
      final showTip = q.id == 'ruqayya';
      return Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 14, showTip ? 14 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _rowText(
                    title,
                    '',
                    subWidget: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: YaadainTheme.accentDark, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: EnText(
                            a.askedCount > 0
                                ? 'Not recorded · asked ${a.askedCount} ${a.askedCount == 1 ? 'time' : 'times'}'
                                : 'Not recorded yet',
                            size: 13,
                            weight: FontWeight.w800,
                            color: YaadainTheme.accentDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _RecordPill(onTap: () => _openRecorder(q.id)),
              ],
            ),
            if (showTip) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: YaadainTheme.attentionSoft,
                  borderRadius: YaadainTheme.radius12,
                  border: Border.all(color: const Color(0xFFE8CDB7)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnText('Answer the feeling, not the fact.', size: 14, weight: FontWeight.w800),
                    SizedBox(height: 4),
                    EnText(
                      'Example: “Ammi is resting. I am here with you, Abu.” Correcting him each time brings the grief back as new.',
                      size: 14,
                      weight: FontWeight.w600,
                      color: YaadainTheme.bodyDim,
                      height: 1.4,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    final by = a.byName.isEmpty ? '' : ' · ${a.byName}';
    final dur = a.durationSec > 0 ? fbClock(a.durationSec) : null;
    String sub;
    if (q.id == 'day') {
      sub = 'Live date, your intro${dur != null ? ' · $dur' : ''}$by';
    } else if (a.audioPath == null) {
      sub = 'Written answer$by';
    } else {
      sub = 'Recorded${dur != null ? ' $dur' : ''}$by';
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      child: Row(
        children: [
          Expanded(child: _rowText(title, sub)),
          FbRoundButton(icon: YI.play, label: 'Play $title', tonal: true, onTap: a.audioPath == null ? null : () => _play(a)),
          FbRoundButton(icon: YI.mic, label: 'Record $title again', onTap: () => _openRecorder(q.id)),
        ],
      ),
    );
  }
}

class _RecordPill extends StatelessWidget {
  final VoidCallback onTap;
  const _RecordPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Record',
      child: Material(
        color: YaadainTheme.primary,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              YIcon(YI.mic, size: 16, color: Colors.white),
              SizedBox(width: 6),
              EnText('Record', size: 14, weight: FontWeight.w800, color: Colors.white),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet: record (max 30 s), listen back, optionally type the Urdu
/// line he reads, save.
class _AnswerSheet extends StatefulWidget {
  final String questionId;
  final String title;
  const _AnswerSheet({required this.questionId, required this.title});

  @override
  State<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends State<_AnswerSheet> {
  final FbRecorder _rec = FbRecorder(maxSec: 30);
  final TextEditingController _text = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = context.read<AppState>().answerFor(widget.questionId);
    _text.text = a.textUr;
  }

  @override
  void dispose() {
    _rec.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _saving = true);
    try {
      await _rec.stopPlayback();
      await app.saveAnswer(
        widget.questionId,
        textUr: _text.text.trim(), // '' clears the written answer
        audioTempPath: _rec.path,
        durationSec: _rec.path == null ? null : _rec.seconds,
        byName: app.myNameEn,
      );
      messenger?.showSnackBar(const SnackBar(
        content: EnText('Saved. He will hear this answer.', size: 14, weight: FontWeight.w700, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        backgroundColor: YaadainTheme.ink,
      ));
      if (nav.canPop()) nav.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        fbSnack(context, 'Could not save. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return FamilyTheme(
      child: Material(
        color: YaadainTheme.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: AnimatedBuilder(
          animation: _rec,
          builder: (context, _) {
            final recording = _rec.recording;
            final done = _rec.hasRecording;
            final canSave = done || _text.text.trim().isNotEmpty;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 20 + inset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: YaadainTheme.line, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  EnText(widget.title, size: 22, weight: FontWeight.w600, display: true),
                  const SizedBox(height: 4),
                  const EnText('Say it the way you would at the table. Up to 30 seconds.',
                      size: 14, weight: FontWeight.w600, color: YaadainTheme.muted),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(fbClock(_rec.seconds),
                        style: YaadainTheme.en(36, weight: FontWeight.w800, height: 1.1)
                            .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: EnText(
                      recording ? 'Recording · tap to stop' : (done ? (_rec.playing ? 'Playing' : 'Recorded') : 'Tap to record'),
                      size: 14,
                      weight: FontWeight.w700,
                      color: YaadainTheme.muted,
                    ),
                  ),
                  if (_rec.error != null && !recording)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Center(child: EnText(_rec.error!, size: 13, weight: FontWeight.w700, color: YaadainTheme.accentDark)),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (done) ...[
                        FbRoundButton(
                          icon: _rec.playing ? YI.pause : YI.play,
                          label: _rec.playing ? 'Stop' : 'Play',
                          tonal: true,
                          onTap: _rec.togglePlay,
                        ),
                        const SizedBox(width: 16),
                      ],
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Material(
                          color: recording ? YaadainTheme.accentDark : YaadainTheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: recording ? _rec.stop : _rec.start,
                            child: Semantics(
                              button: true,
                              label: recording ? 'Stop recording' : (done ? 'Record again' : 'Start recording'),
                              child: Center(child: YIcon(recording ? YI.pause : YI.mic, size: 30, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FbField(
                    label: 'Written version in Urdu letters (optional)',
                    controller: _text,
                    capitalization: TextCapitalization.none,
                    helper: 'He reads this on screen if the recording cannot play.',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  FbBigButton('Save answer', onTap: canSave && !recording ? _save : null, busy: _saving),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
