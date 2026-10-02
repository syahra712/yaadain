import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/care.dart';
import '../../models/episode_log.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import '../../util/en_format.dart';
import '../../util/prayer.dart';
import 'widgets/family_a_common.dart';

/// Weekly report (`/care/report`). English, board WeeklyReport.
class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final r = _Report.of(app);
    final from = app.now.subtract(const Duration(days: 7));

    return FamilyScaffold(
      title: 'This week',
      subtitle: '${faRange(from, app.now)} · ${app.elderNameEn}',
      bodyPadding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Noticed(r: r),
          const SizedBox(height: 16),
          _ChartCard(r: r),
          const SizedBox(height: 16),
          _Tiles(r: r),
          if (r.suggestions.isNotEmpty) ...[
            const SizedBox(height: 22),
            _Worth(r: r),
          ],
          const SizedBox(height: 20),
          FamilyButton('Share doctor sheet', icon: YI.fileText, onTap: () => _share(context, r)),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 10, 8, 0),
            child: EnText(
              'One page: this week in plain words, prompts taken, nothing about where he went.',
              size: 13,
              weight: FontWeight.w600,
              color: YaadainTheme.muted,
              align: TextAlign.center,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context, _Report r) async {
    await Clipboard.setData(ClipboardData(text: r.doctorSheet()));
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Doctor sheet copied. Paste it into a message or document.')));
  }
}

// ── Data ─────────────────────────────────────────────────────────────────

class _Suggestion {
  final YI icon;
  final AvatarTint tint;
  final String title;
  final String sub;
  final String route;
  final Object? args;
  const _Suggestion(this.icon, this.tint, this.title, this.sub, this.route, [this.args]);
}

class _Report {
  final AppState app;
  final WeeklyStats st;
  final List<int> hours; // question counts per hour of day
  final int peak;
  final int hardStart; // first hardest hour (inclusive)
  final int hardEnd; // last hardest hour (inclusive)
  final DateTime asr;
  final String headline;
  final String body;
  final List<Episode> outings;
  final List<Episode> exits;
  final int calmAfterAsr;
  final List<String> nightPickups;
  final String promptsNote;
  final String voicesNote;
  final List<_Suggestion> suggestions;

  _Report._({
    required this.app,
    required this.st,
    required this.hours,
    required this.peak,
    required this.hardStart,
    required this.hardEnd,
    required this.asr,
    required this.headline,
    required this.body,
    required this.outings,
    required this.exits,
    required this.calmAfterAsr,
    required this.nightPickups,
    required this.promptsNote,
    required this.voicesNote,
    required this.suggestions,
  });

  static const _words = ['no', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'];
  static String _count(int n) => n < _words.length ? _words[n] : '$n';
  static String _times(int n) => n == 1 ? 'once' : (n == 2 ? 'twice' : '${_count(n)} times');

  factory _Report.of(AppState app) {
    final st = app.weeklyStats();
    final now = app.now;
    final es = app.episodesSince(now.subtract(const Duration(days: 7)));
    final hours = List<int>.filled(24, 0);
    for (final e in es) {
      if (e.category == 'question') hours[e.at.hour]++;
    }
    final peak = hours.fold<int>(0, (a, b) => b > a ? b : a);
    final asr = app.prayerToday.asr;
    final hardStart = asr.minute == 0 ? asr.hour : asr.hour + 1;
    final hardEnd = app.prayerToday.maghrib.hour;

    // Headline and body
    String headline;
    String body;
    final q = st.questions;
    if (q == 0) {
      headline = 'A quiet week: no questions asked.';
      body = 'Nothing to report yet. As ${app.elderNameEn} uses Ask on his phone, the pattern of his day will show here.';
    } else {
      if (st.questionsAfterAsr * 2 >= q) {
        headline = 'Most questions come after Asr: ${st.questionsAfterAsr} of $q. Evenings are his hardest time.';
      } else {
        final ph = hours.indexOf(peak);
        headline = 'Most questions come around ${faHour(ph)}: $peak of $q.';
      }
      final cg = app.primaryContact?.firstNameEn;
      if (st.ruqayyaAfterMaghrib > 0) {
        final n = st.ruqayyaAfterMaghrib;
        final total = st.byQuestion['ruqayya'] ?? n;
        final when = n == total ? 'all after Maghrib' : '$n of them after Maghrib';
        final rec = app.answerFor('ruqayya').isRecorded;
        body = 'He asked where Ruqayya is ${_times(total)}, $when. '
            '${rec ? 'A recorded answer is waiting for him there.' : 'There is no recorded answer for that one yet; a calm line in ${cg == null ? 'a relative' : '$cg’s'} voice would meet him there.'}';
      } else {
        final top = st.byQuestion.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final qq = questionById(top.first.key);
        body = qq == null
            ? 'He asked ${_times(q)} this week.'
            : 'He asked “${qq.textEn}” ${_times(top.first.value)}.';
      }
    }

    final exits = faUnplannedExits(app);
    final outings = faOutings(app);
    var calmAfterAsr = 0;
    for (final e in es) {
      if (e.category == 'calm' && !e.at.isBefore(PrayerTimes.forDate(e.at).asr)) calmAfterAsr++;
    }
    final nights = es.where((e) => e.category == 'night_pickup').toList()..sort((a, b) => a.at.compareTo(b.at));
    final nightTxt = [for (final e in nights) '${EnFmt.weekdayShort(e.at)} ${EnFmt.time(e.at).toLowerCase()}'];

    // Missed prompts note
    final key = <String, List<String>>{};
    final weekKeys = {for (var i = 1; i <= 7; i++) RoutineLog.dayKey(now.subtract(Duration(days: i)))};
    for (final l in app.care.routineLogs) {
      if (l.status == 'taken' || !weekKeys.contains(l.day)) continue;
      final d = DateTime.tryParse(l.day);
      if (d == null) continue;
      key.putIfAbsent(l.itemId, () => []).add('${l.status}|${EnFmt.weekdayShort(d)}');
    }
    String promptsNote = 'Nothing missed';
    if (key.isNotEmpty) {
      final id = key.keys.first;
      RoutineItem? item;
      for (final r in app.routine) {
        if (r.id == id) item = r;
      }
      final entries = key[id]!;
      final status = entries.first.split('|').first;
      final days = entries.map((e) => e.split('|').last).toList();
      final name = item == null
          ? 'Prompt'
          : (item.kind == RoutineKind.walk ? 'Walk' : (item.kind == RoutineKind.meal ? 'Meal' : 'Medicine'));
      final joined = days.length <= 1 ? days.join() : '${days.sublist(0, days.length - 1).join(', ')} and ${days.last}';
      promptsNote = '$name $status $joined';
    }

    // Voices
    String voicesNote = 'No hellos played yet';
    if (st.voicesByMember.isNotEmpty) {
      final top = st.voicesByMember.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final m = app.memberById(top.first.key);
      if (m != null) voicesNote = '${m.firstNameEn}’s hello most often';
    }

    // Suggestions
    final sugg = <_Suggestion>[];
    final unanswered = st.byQuestion.entries.where((e) => !app.answerFor(e.key).isRecorded && questionById(e.key) != null).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (unanswered.isNotEmpty) {
      final qq = questionById(unanswered.first.key)!;
      final cg = app.primaryContact?.firstNameEn;
      sugg.add(_Suggestion(
        YI.mic,
        YaadainTheme.tintClay,
        'Record “${qq.textEn}”',
        'Two minutes · ${cg == null ? 'your' : '$cg’s'} voice · opens Answers',
        Routes.careAnswers,
        AnswersEditorArgs(questionId: qq.id),
      ));
    }
    RoutineItem? walk;
    for (final r in app.routine) {
      if (r.kind == RoutineKind.walk && r.enabled) walk = r;
    }
    if (walk != null && q > 0 && st.questionsAfterAsr * 2 >= q) {
      final t = asr.subtract(const Duration(minutes: 10));
      sugg.add(_Suggestion(
        YI.walking,
        YaadainTheme.tintSage,
        'Move the walk to ${t.hour % 12 == 0 ? 12 : t.hour % 12}:${t.minute.toString().padLeft(2, '0')}',
        'Before his hard hours · opens Routine',
        Routes.careRoutine,
      ));
    }

    return _Report._(
      app: app,
      st: st,
      hours: hours,
      peak: peak,
      hardStart: hardStart,
      hardEnd: hardEnd,
      asr: asr,
      headline: headline,
      body: body,
      outings: outings,
      exits: exits,
      calmAfterAsr: calmAfterAsr,
      nightPickups: nightTxt,
      promptsNote: promptsNote,
      voicesNote: voicesNote,
      suggestions: sugg,
    );
  }

  /// Plain-words one page for a doctor. Deliberately has no places or maps.
  String doctorSheet() {
    final now = app.now;
    final from = now.subtract(const Duration(days: 7));
    final b = StringBuffer()
      ..writeln('${app.elderNameEn}: week of ${faRange(from, now)}')
      ..writeln()
      ..writeln(headline)
      ..writeln(body)
      ..writeln()
      ..writeln('Questions asked: ${st.questions} (${st.questionsAfterAsr} after Asr)')
      ..writeln('Prompts taken: ${st.dosesTaken} of ${st.dosesTotal}. $promptsNote')
      ..writeln('Calm clips played: ${st.calmPlays}')
      ..writeln('Night pickups: ${st.nightPickups}${nightPickups.isEmpty ? '' : ' (${nightPickups.join(', ')})'}')
      ..writeln('Family voices played: ${st.voicesPlayed}');
    return b.toString();
  }
}

// ── Noticed ──────────────────────────────────────────────────────────────

class _Noticed extends StatelessWidget {
  final _Report r;
  const _Noticed({required this.r});

  @override
  Widget build(BuildContext context) {
    return YCard(
      padding: const EdgeInsets.all(18),
      radius: 28,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EnText.eyebrow('WHAT WE NOTICED'),
            const SizedBox(height: 10),
            EnText(r.headline, size: 21, weight: FontWeight.w500, display: true, height: 1.3),
            const SizedBox(height: 12),
            EnText(r.body, size: 14, weight: FontWeight.w500, color: YaadainTheme.bodyDim, height: 1.45),
          ],
        ),
      ),
    );
  }
}

// ── Chart ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final _Report r;
  const _ChartCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final hard = '${_hh(r.hardStart)} – ${_hh(r.hardEnd + 1)} pm, his hardest hours';
    return YCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(child: EnText('Questions by hour', size: 15, weight: FontWeight.w800)),
              EnText('${r.st.questions} this week', size: 13, weight: FontWeight.w700, color: YaadainTheme.muted),
            ]),
            const SizedBox(height: 12),
            Semantics(
              label: r.st.questions == 0
                  ? 'Chart of questions by hour. No questions this week.'
                  : 'Chart of questions by hour. ${r.headline}',
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                  painter: _HourChartPainter(
                    counts: r.hours,
                    peak: r.peak,
                    hardStart: r.hardStart,
                    hardEnd: r.hardEnd,
                    asr: r.asr,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _Legend(color: YaadainTheme.accentDark, label: hard),
                const _Legend(color: YaadainTheme.primary, label: 'Other hours'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _hh(int h) => '${h % 12 == 0 ? 12 : h % 12}';
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      EnText(label, size: 12, weight: FontWeight.w700, color: YaadainTheme.bodyDim),
    ]);
  }
}

class _HourChartPainter extends CustomPainter {
  final List<int> counts;
  final int peak;
  final int hardStart;
  final int hardEnd;
  final DateTime asr;
  _HourChartPainter({required this.counts, required this.peak, required this.hardStart, required this.hardEnd, required this.asr});

  static const double left = 22;
  static const double base = 128;
  static const double maxBar = 110;

  void _text(Canvas c, String t, double x, double y, {Color color = YaadainTheme.muted, double size = 11, FontWeight w = FontWeight.w700, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: YaadainTheme.en(size, weight: w, color: color, height: 1.1)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = align == TextAlign.right ? x - tp.width : (align == TextAlign.center ? x - tp.width / 2 : x);
    tp.paint(c, Offset(dx, y - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final right = size.width - 4;
    final step = (right - left) / 24;
    final top = peak <= 4 ? 4 : (peak.isOdd ? peak + 1 : peak);
    final unit = peak <= 4 ? 27.5 : maxBar / top;

    final grid = Paint()
      ..color = YaadainTheme.line
      ..strokeWidth = 1;
    for (final v in [top ~/ 2, top]) {
      if (peak <= 4 && v > 4) continue;
      final y = base - v * unit;
      canvas.drawLine(Offset(left, y), Offset(right, y), grid);
      _text(canvas, '$v', 0, y);
    }
    canvas.drawLine(
      const Offset(left, base),
      Offset(right, base),
      Paint()
        ..color = YaadainTheme.stroke
        ..strokeWidth = 1.5,
    );

    // Asr line
    final ax = left + (asr.hour + asr.minute / 60) * step;
    canvas.drawLine(
      Offset(ax, 10),
      Offset(ax, base),
      Paint()
        ..color = YaadainTheme.gold
        ..strokeWidth = 1.2,
    );
    final asrLabel = 'Asr ${asr.hour % 12 == 0 ? 12 : asr.hour % 12}:${asr.minute.toString().padLeft(2, '0')}';
    _text(canvas, asrLabel, ax - 5, 18, color: YaadainTheme.gold, w: FontWeight.w800, align: TextAlign.right);

    // Bars
    for (var h = 0; h < 24; h++) {
      final n = counts[h];
      if (n == 0) continue;
      final hard = h >= hardStart && h <= hardEnd;
      final bh = n * unit;
      final x = left + h * step + (step - 9) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, base - bh, 9, bh),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = hard ? YaadainTheme.accentDark : YaadainTheme.primary);
      if (n == peak && peak >= 2) {
        _text(canvas, '$n', x + 4.5, base - bh - 8, color: YaadainTheme.ink, size: 12, w: FontWeight.w800, align: TextAlign.center);
      }
    }

    // X labels
    const labels = {0: '12 am', 6: '6 am', 12: '12 pm', 18: '6 pm'};
    labels.forEach((h, t) {
      _text(canvas, t, left + h * step + step / 2, 144, align: TextAlign.center);
    });
  }

  @override
  bool shouldRepaint(covariant _HourChartPainter old) =>
      old.counts != counts || old.peak != peak || old.asr != asr || old.hardStart != hardStart || old.hardEnd != hardEnd;
}

// ── Tiles ────────────────────────────────────────────────────────────────

class _Tiles extends StatelessWidget {
  final _Report r;
  const _Tiles({required this.r});

  @override
  Widget build(BuildContext context) {
    final st = r.st;
    String outNote = 'None this week';
    if (r.outings.isNotEmpty) {
      final names = r.outings.map((e) => e.note ?? '').where((n) => n.isNotEmpty).toSet().toList();
      outNote = names.isEmpty ? 'Planned outings' : names.take(2).join(', ');
    }
    String exitNote = 'None this week';
    if (r.exits.isNotEmpty) {
      final e = r.exits.last;
      Episode? back;
      for (final x in r.app.episodes) {
        if (x.category == 'zone_return' && x.at.isAfter(e.at) && (back == null || x.at.isBefore(back.at))) back = x;
      }
      exitNote = '${EnFmt.weekdayShort(e.at)} ${EnFmt.time(e.at).toLowerCase().replaceAll(' ', ' ')}'
          '${back != null ? ' · back ${faClock(back.at)}' : ''}';
    }
    final tiles = <_Tile>[
      _Tile('Outings', '${r.outings.length}', null, outNote),
      _Tile('Zone exits', '${r.exits.length}', null, exitNote),
      _Tile('Calm played', '${st.calmPlays}', null, st.calmPlays == 0 ? 'None this week' : '${r.calmAfterAsr} of them after Asr'),
      _Tile('Night pickups', '${st.nightPickups}', null, r.nightPickups.isEmpty ? 'None this week' : r.nightPickups.join(' · ')),
      _Tile('Prompts taken', '${st.dosesTaken}', st.dosesTotal == 0 ? null : 'of ${st.dosesTotal}', st.dosesTotal == 0 ? 'No prompts set yet' : r.promptsNote),
      _Tile('Voices played', '${st.voicesPlayed}', null, r.voicesNote),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? 12 : 0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 12),
              Expanded(child: tiles[i + 1]),
            ],
          ),
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String note;
  const _Tile(this.label, this.value, this.unit, this.note);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label ${unit == null ? value : '$value $unit'}. $note',
      child: ExcludeSemantics(
        child: YCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EnText(label, size: 13, weight: FontWeight.w700, color: YaadainTheme.muted),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    EnText(value, size: 30, weight: FontWeight.w800, height: 1.3),
                    if (unit != null) ...[
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: EnText(unit!, size: 14, weight: FontWeight.w800, color: YaadainTheme.muted),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                EnText(note, size: 12, weight: FontWeight.w600, color: YaadainTheme.bodyDim, height: 1.35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Worth trying ─────────────────────────────────────────────────────────

class _Worth extends StatelessWidget {
  final _Report r;
  const _Worth({required this.r});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FaSectionHeader('Worth trying'),
        const SizedBox(height: 8),
        FaCardList(
          children: [
            for (final s in r.suggestions)
              FaRow(
                minHeight: 64,
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                leading: FaIconBox(s.icon, bg: s.tint.bg, fg: s.tint.fg),
                title: s.title,
                sub: s.sub,
                chevron: true,
                onTap: () => Navigator.pushNamed(context, s.route, arguments: s.args),
              ),
          ],
        ),
      ],
    );
  }
}
