import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/care.dart';
import '../../state/app_state.dart';
import '../../util/prayer.dart';
import 'widgets/family_b_common.dart';

/// Caregiver: medicine / meal / walk prompts for the elder phone, the week at
/// a glance, night rules. Route `/care/routine`.
class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  static const _bgNeutral = Color(0xFFEFE8DA);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final now = app.now;
    final items = List<RoutineItem>.of(app.routine)..sort((a, b) => app.routineDueAt(a).compareTo(app.routineDueAt(b)));
    final week = app.routineWeek();
    final cfg = app.care.routineConfig;

    return FamilyScaffold(
      title: 'Routine',
      body: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: StatusChip('On his phone · caregiver settings', icon: YI.lock),
            ),
            const SizedBox(height: 16),
            _WeekCard(app: app, taken: week.taken, total: week.total),
            const SizedBox(height: 24),
            FbSectionHeader('Today · ${EnFmtShort.weekday(now)}', action: 'History', onAction: () => _history(context, app)),
            if (items.isEmpty)
              const YCard(
                padding: EdgeInsets.all(20),
                child: EnText('No prompts yet. Add one below and it appears on his phone at the right time.',
                    size: 14, weight: FontWeight.w600, color: YaadainTheme.muted, height: 1.4),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: YaadainTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: YaadainTheme.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(height: 1, thickness: 1, indent: 60, color: YaadainTheme.line),
                        _ItemRow(item: items[i], app: app),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const _AddPromptCard(),
            const SizedBox(height: 24),
            const FbSectionHeader('Night'),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: YaadainTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: YaadainTheme.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NightRow(
                      icon: YI.moon,
                      title: 'Quiet hours · after Isha',
                      sub: 'Screen dims from ${fbTime(app.prayerToday.isha)}, prompts pause',
                      on: cfg.quietAfterIsha,
                      onTap: () => app.saveRoutineConfig(quietAfterIsha: !cfg.quietAfterIsha),
                    ),
                    const Divider(height: 1, thickness: 1, indent: 60, color: YaadainTheme.line),
                    _NightRow(
                      icon: YI.bell,
                      title: 'Night pickup nudge · 1 – 5 am',
                      sub: 'He lifts the phone, ${_nightPerson(app)} gets a quiet buzz',
                      on: cfg.nightPickupNudge,
                      onTap: () => app.saveRoutineConfig(nightPickupNudge: !cfg.nightPickupNudge),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _Note(icon: YI.clock, text: 'Scheduled on his phone and works offline. Delivery can be a few minutes late.'),
            const SizedBox(height: 8),
            const _Note(icon: YI.heart, text: 'These are reminders you set for him, in your voice. They are not medical advice.'),
          ],
        ),
      ),
    );
  }

  static String _nightPerson(AppState app) {
    for (final c in app.circle) {
      final l = (c.shiftLabel ?? '').toLowerCase();
      if (l.contains('night')) {
        final m = app.memberById(c.memberId);
        if (m != null && m.firstNameEn.isNotEmpty) return m.firstNameEn;
      }
    }
    final p = app.primaryContact;
    if (p != null && p.firstNameEn.isNotEmpty) return p.firstNameEn;
    return 'you';
  }

  void _history(BuildContext context, AppState app) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: YaadainTheme.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => FamilyTheme(child: _HistorySheet(app: app)),
    );
  }
}

/// Weekday name without importing EnFmt in the widget tree repeatedly.
class EnFmtShort {
  static const _names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static String weekday(DateTime d) => _names[d.weekday - 1];
}

// ── Week strip ──────────────────────────────────────────────────────────

class _WeekCard extends StatelessWidget {
  final AppState app;
  final int taken;
  final int total;
  const _WeekCard({required this.app, required this.taken, required this.total});

  /// 0 = no data, 1 = all taken, 2 = something skipped or missed.
  int _dayState(DateTime day) {
    final key = RoutineLog.dayKey(day);
    final ids = app.care.routine.where((i) => i.kind != RoutineKind.walk).map((i) => i.id).toSet();
    var seen = 0, bad = 0;
    for (final l in app.care.routineLogs) {
      if (l.day != key || !ids.contains(l.itemId)) continue;
      seen++;
      if (l.status != 'taken') bad++;
    }
    if (seen == 0) return 0;
    return bad == 0 ? 1 : 2;
  }

  @override
  Widget build(BuildContext context) {
    final n = app.now;
    final today = DateTime(n.year, n.month, n.day);
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return YCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(child: EnText('This week', size: 20, weight: FontWeight.w600, display: true)),
              EnText(total == 0 ? 'Nothing logged yet' : '$taken of $total taken',
                  size: 13, weight: FontWeight.w700, color: YaadainTheme.muted),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < days.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(child: _DayCell(letter: letters[days[i].weekday - 1], day: days[i].day, state: i == 6 ? -1 : _dayState(days[i]))),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Legend(color: YaadainTheme.primary, label: 'All taken'),
              _Legend(color: YaadainTheme.attentionSoft, ring: YaadainTheme.accentDark, label: 'One skipped'),
              _Legend(color: YaadainTheme.primarySoft, ring: YaadainTheme.primary, label: 'Today'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String letter;
  final int day;
  final int state; // -1 today
  const _DayCell({required this.letter, required this.day, required this.state});

  @override
  Widget build(BuildContext context) {
    final today = state == -1;
    Widget dot;
    switch (state) {
      case 1:
        dot = _dot(YaadainTheme.primary, null);
        break;
      case 2:
        dot = _dot(YaadainTheme.attentionSoft, YaadainTheme.accentDark);
        break;
      case -1:
        dot = _dot(YaadainTheme.primarySoft, YaadainTheme.primary);
        break;
      default:
        dot = _dot(YaadainTheme.line, null);
    }
    return Semantics(
      label: '$letter $day',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: today ? YaadainTheme.primarySoft : null, borderRadius: YaadainTheme.radius12),
        child: Column(
          children: [
            EnText(letter, size: 12, weight: FontWeight.w800, color: YaadainTheme.muted, height: 1.2),
            const SizedBox(height: 6),
            EnText('$day', size: 14, weight: FontWeight.w800, height: 1.2),
            const SizedBox(height: 6),
            dot,
          ],
        ),
      ),
    );
  }

  static Widget _dot(Color c, Color? ring) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c, border: ring == null ? null : Border.all(color: ring, width: 2)),
      );
}

class _Legend extends StatelessWidget {
  final Color color;
  final Color? ring;
  final String label;
  const _Legend({required this.color, this.ring, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: ring == null ? null : Border.all(color: ring!, width: 2)),
      ),
      const SizedBox(width: 5),
      EnText(label, size: 12, weight: FontWeight.w700, color: YaadainTheme.muted),
    ]);
  }
}

// ── Today's items ───────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final RoutineItem item;
  final AppState app;
  const _ItemRow({required this.item, required this.app});

  (AvatarTint, YI) get _look => switch (item.kind) {
        RoutineKind.medicine => (YaadainTheme.tintTeal, YI.pill),
        RoutineKind.meal => (YaadainTheme.tintGold, YI.utensils),
        RoutineKind.walk => (YaadainTheme.tintSage, YI.walking),
      };

  @override
  Widget build(BuildContext context) {
    final due = app.routineDueAt(item);
    final log = app.routineLogToday(item.id);
    final anchored = item.anchor != null;
    Prayer? prayer;
    if (anchored) {
      for (final p in Prayer.values) {
        if (p.name == item.anchor) prayer = p;
      }
    }
    final title = anchored && prayer != null ? '${item.titleEn} · ${prayer.en}' : '${item.titleEn} · ${fbTime(due)}';
    final by = (log?.by ?? '').isEmpty ? '' : ' · ${log!.by}';
    String sub;
    if (log != null && (log.status == 'skipped' || log.status == 'missed')) {
      sub = '${log.status == 'missed' ? 'Missed' : 'Skipped'} today';
    } else {
      final lead = anchored && prayer != null ? 'After ${prayer.en}, about ${fbTime(due)}' : item.detail;
      sub = [lead, if (by.isNotEmpty) by.substring(3)].where((s) => s.isNotEmpty).join(' · ');
      if (sub.isEmpty) sub = item.enabled ? 'On his phone' : 'Paused';
    }
    if (!item.enabled && log == null) sub = 'Paused · $sub';

    Widget chip;
    if (log == null) {
      chip = _StateChip(label: item.enabled ? 'Pending' : 'Paused', bg: RoutineScreen._bgNeutral, fg: YaadainTheme.muted);
    } else if (log.status == 'taken') {
      chip = _StateChip(
          label: item.kind == RoutineKind.walk ? 'Done' : 'Taken${log.at == null ? '' : ' ${_short(log.at!)}'}',
          bg: YaadainTheme.primarySoft,
          fg: YaadainTheme.primaryDark,
          icon: YI.check);
    } else {
      chip = _StateChip(
          label: log.status == 'missed' ? 'Missed' : 'Skipped', bg: YaadainTheme.attentionSoft, fg: YaadainTheme.accentDark);
    }
    final (tint, icon) = _look;
    return Semantics(
      button: true,
      label: '$title. Tap for options.',
      child: InkWell(
        onTap: () => _options(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: tint.bg, borderRadius: YaadainTheme.radius12),
                child: Center(child: YIcon(icon, size: 20, color: tint.fg)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnText(title, size: 15, weight: FontWeight.w800, height: 1.25),
                    const SizedBox(height: 2),
                    EnText(sub, size: 13, weight: FontWeight.w600, color: YaadainTheme.muted, height: 1.3),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              chip,
            ],
          ),
        ),
      ),
    );
  }

  static String _short(DateTime t) {
    var h = t.hour % 12;
    if (h == 0) h = 12;
    return '$h:${t.minute.toString().padLeft(2, '0')}';
  }

  void _options(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: YaadainTheme.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => FamilyTheme(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 20 + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EnText(item.titleEn, size: 22, weight: FontWeight.w600, display: true),
              const SizedBox(height: 4),
              EnText(item.kind == RoutineKind.walk ? 'Mark today’s walk' : 'Mark today’s ${item.kind == RoutineKind.meal ? 'meal' : 'dose'}',
                  size: 14, weight: FontWeight.w600, color: YaadainTheme.muted),
              const SizedBox(height: 16),
              FbBigButton(item.kind == RoutineKind.walk ? 'Done' : 'Taken', icon: YI.check, onTap: () {
                app.markRoutine(item.id, 'taken');
                Navigator.pop(ctx);
              }),
              const SizedBox(height: 10),
              FbSmallButton('Skipped today', height: 48, onTap: () {
                app.markRoutine(item.id, 'skipped');
                Navigator.pop(ctx);
              }),
              const SizedBox(height: 10),
              FbSmallButton(item.enabled ? 'Pause this prompt' : 'Turn this prompt back on', height: 48, onTap: () {
                item.enabled = !item.enabled;
                app.saveRoutineItem(item);
                Navigator.pop(ctx);
              }),
              const SizedBox(height: 10),
              FbSmallButton('Remove this prompt', icon: YI.trash, height: 48, onTap: () async {
                final ok = await showDialog<bool>(
                  context: ctx,
                  builder: (d) => FamilyTheme(
                    child: AlertDialog(
                      backgroundColor: YaadainTheme.surface,
                      title: EnText('Remove ${item.titleEn}?', size: 20, weight: FontWeight.w600, display: true),
                      content: const EnText('It will stop appearing on his phone.', size: 14, weight: FontWeight.w600, color: YaadainTheme.bodyDim),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d, false), child: const EnText('Keep it', size: 14, weight: FontWeight.w800, color: YaadainTheme.primary)),
                        TextButton(onPressed: () => Navigator.pop(d, true), child: const EnText('Remove', size: 14, weight: FontWeight.w800, color: YaadainTheme.accentDark)),
                      ],
                    ),
                  ),
                );
                if (ok == true) {
                  await app.removeRoutineItem(item.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final YI? icon;
  const _StateChip({required this.label, required this.bg, required this.fg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[YIcon(icon!, size: 13, color: fg, strokeWidth: 2.6), const SizedBox(width: 5)],
        EnText(label, size: 12, weight: FontWeight.w800, color: fg, height: 1.0),
      ]),
    );
  }
}

// ── Night ───────────────────────────────────────────────────────────────

class _NightRow extends StatelessWidget {
  final YI icon;
  final String title;
  final String sub;
  final bool on;
  final VoidCallback onTap;
  const _NightRow({required this.icon, required this.title, required this.sub, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: on,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: YaadainTheme.tintPlum.bg, borderRadius: YaadainTheme.radius12),
                child: Center(child: YIcon(icon, size: 20, color: YaadainTheme.tintPlum.fg)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnText(title, size: 15, weight: FontWeight.w800, height: 1.25),
                    const SizedBox(height: 2),
                    EnText(sub, size: 13, weight: FontWeight.w600, color: YaadainTheme.muted, height: 1.3),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StateChip(
                label: on ? 'On' : 'Off',
                bg: on ? YaadainTheme.primarySoft : RoutineScreen._bgNeutral,
                fg: on ? YaadainTheme.primaryDark : YaadainTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final YI icon;
  final String text;
  const _Note({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: YIcon(icon, size: 18, color: YaadainTheme.muted)),
          const SizedBox(width: 10),
          Expanded(child: EnText(text, size: 13, weight: FontWeight.w600, color: YaadainTheme.muted, height: 1.4)),
        ],
      ),
    );
  }
}

// ── Add a prompt ────────────────────────────────────────────────────────

class _AddPromptCard extends StatefulWidget {
  const _AddPromptCard();

  @override
  State<_AddPromptCard> createState() => _AddPromptCardState();
}

class _AddPromptCardState extends State<_AddPromptCard> {
  bool _afterPrayer = true;
  String? _photo;
  final FbRecorder _rec = FbRecorder(maxSec: 15);

  @override
  void initState() {
    super.initState();
    _rec.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _rec.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 85);
      if (f != null && mounted) setState(() => _photo = f.path);
    } catch (_) {
      if (mounted) fbSnack(context, 'Photos are not available right now.');
    }
  }

  Future<void> _toggleRecord() async {
    if (_rec.recording) {
      await _rec.stop();
    } else {
      await _rec.start();
      if (_rec.error != null && mounted) fbSnack(context, _rec.error!);
    }
  }

  Future<void> _add() async {
    final app = context.read<AppState>();
    if (_rec.recording) await _rec.stop();
    if (!mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: YaadainTheme.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => ChangeNotifierProvider<AppState>.value(
        value: app,
        child: _PromptSheet(afterPrayer: _afterPrayer, photo: _photo, linePath: _rec.path),
      ),
    );
    if (created == true && mounted) {
      setState(() => _photo = null);
      _rec.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return YCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EnText('Add a prompt', size: 20, weight: FontWeight.w600, display: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: RoutineScreen._bgNeutral, borderRadius: YaadainTheme.radius12),
            child: Row(children: [
              Expanded(child: _Seg(label: 'At a time', on: !_afterPrayer, onTap: () => setState(() => _afterPrayer = false))),
              Expanded(child: _Seg(label: 'After a prayer', on: _afterPrayer, onTap: () => setState(() => _afterPrayer = true))),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: FbSmallButton(_photo == null ? 'Add photo' : 'Photo added', icon: _photo == null ? YI.camera : YI.check, height: 48, onTap: _pickPhoto),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FbSmallButton(
                _rec.recording ? 'Stop · ${fbClock(_rec.seconds)}' : (_rec.hasRecording ? 'Line recorded' : 'Record your line'),
                icon: _rec.hasRecording ? YI.check : YI.mic,
                height: 48,
                onTap: _toggleRecord,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: Semantics(
              button: true,
              label: 'Add prompt',
              child: Material(
                color: YaadainTheme.primary,
                borderRadius: YaadainTheme.radius12,
                child: InkWell(
                  borderRadius: YaadainTheme.radius12,
                  onTap: _add,
                  child: const Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      YIcon(YI.plus, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      EnText('Add prompt', size: 15, weight: FontWeight.w800, color: Colors.white),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Seg({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? YaadainTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: on ? const [BoxShadow(color: Color(0x1F2C2620), blurRadius: 2, offset: Offset(0, 1))] : null,
          ),
          child: EnText(label, size: 14, weight: FontWeight.w800, color: on ? YaadainTheme.ink : YaadainTheme.muted),
        ),
      ),
    );
  }
}

class _PromptSheet extends StatefulWidget {
  final bool afterPrayer;
  final String? photo;
  final String? linePath;
  const _PromptSheet({required this.afterPrayer, this.photo, this.linePath});

  @override
  State<_PromptSheet> createState() => _PromptSheetState();
}

class _PromptSheetState extends State<_PromptSheet> {
  RoutineKind _kind = RoutineKind.medicine;
  final TextEditingController _title = TextEditingController();
  final TextEditingController _detail = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  Prayer _prayer = Prayer.maghrib;
  int _offset = 15;
  String? _err;
  bool _saving = false;

  static const _defaults = {
    RoutineKind.medicine: ('Medicine', 'دوا کا وقت'),
    RoutineKind.meal: ('Meal', 'کھانے کا وقت'),
    RoutineKind.walk: ('Walk', 'سیر کا وقت'),
  };

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final title = _title.text.trim().isEmpty ? _defaults[_kind]!.$1 : _title.text.trim();
    setState(() {
      _saving = true;
      _err = null;
    });
    try {
      final item = RoutineItem(
        id: app.newId(),
        kind: _kind,
        titleEn: title,
        titleUr: _defaults[_kind]!.$2,
        detail: _detail.text.trim(),
        hour: _time.hour,
        minute: _time.minute,
        anchor: widget.afterPrayer ? _prayer.name : null,
        anchorOffsetMin: widget.afterPrayer ? _offset : 0,
      );
      await app.saveRoutineItem(item);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _err = 'Could not save this prompt. Please try again.';
        });
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
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 20 + inset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: YaadainTheme.line, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const EnText('New prompt', size: 22, weight: FontWeight.w600, display: true),
              const SizedBox(height: 16),
              const FbLabel('What for'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final k in RoutineKind.values)
                  _Pick(label: _defaults[k]!.$1, on: _kind == k, onTap: () => setState(() => _kind = k)),
              ]),
              const SizedBox(height: 16),
              FbField(label: 'Name', controller: _title, hint: _defaults[_kind]!.$1),
              const SizedBox(height: 16),
              FbField(label: 'Note (optional)', controller: _detail, hint: 'For example, 10 mg after food'),
              const SizedBox(height: 16),
              if (widget.afterPrayer) ...[
                const FbLabel('After which prayer'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final p in Prayer.values) _Pick(label: p.en, on: _prayer == p, onTap: () => setState(() => _prayer = p)),
                ]),
                const SizedBox(height: 12),
                const FbLabel('How long after'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final m in const [0, 15, 30]) _Pick(label: m == 0 ? 'Right away' : '$m min', on: _offset == m, onTap: () => setState(() => _offset = m)),
                ]),
              ] else ...[
                const FbLabel('Time'),
                SizedBox(
                  height: 52,
                  child: FbSmallButton(_time.format(context), icon: YI.clock, height: 52, onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _time);
                    if (t != null) setState(() => _time = t);
                  }),
                ),
              ],
              if (widget.photo != null || widget.linePath != null)
                const FbHelper('Your photo and voice line are kept on this phone for now.'),
              if (_err != null) FbHelper(_err!, error: true),
              const SizedBox(height: 20),
              FbBigButton('Add prompt', icon: YI.plus, onTap: _save, busy: _saving),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pick extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Pick({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? YaadainTheme.primarySoft : YaadainTheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? YaadainTheme.primary : YaadainTheme.line, width: on ? 1.5 : 1),
          ),
          child: EnText(label, size: 14, weight: FontWeight.w800, color: on ? YaadainTheme.primaryDark : YaadainTheme.ink),
        ),
      ),
    );
  }
}

// ── History ─────────────────────────────────────────────────────────────

class _HistorySheet extends StatelessWidget {
  final AppState app;
  const _HistorySheet({required this.app});

  @override
  Widget build(BuildContext context) {
    final logs = List<RoutineLog>.of(app.care.routineLogs)..sort((a, b) => b.day.compareTo(a.day));
    final names = {for (final i in app.routine) i.id: i.titleEn};
    final shown = logs.take(24).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 20 + MediaQuery.of(context).padding.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EnText('History', size: 22, weight: FontWeight.w600, display: true),
            const SizedBox(height: 4),
            const EnText('What was taken, skipped or missed.', size: 14, weight: FontWeight.w600, color: YaadainTheme.muted),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EnText('Nothing logged yet. It fills in as he answers his prompts.',
                    size: 14, weight: FontWeight.w600, color: YaadainTheme.muted),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: YaadainTheme.line),
                  itemBuilder: (_, i) {
                    final l = shown[i];
                    final ok = l.status == 'taken';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            EnText(names[l.itemId] ?? 'Prompt', size: 15, weight: FontWeight.w800),
                            EnText(l.day, size: 13, weight: FontWeight.w600, color: YaadainTheme.muted),
                          ]),
                        ),
                        _StateChip(
                          label: ok ? 'Taken' : (l.status == 'missed' ? 'Missed' : 'Skipped'),
                          bg: ok ? YaadainTheme.primarySoft : YaadainTheme.attentionSoft,
                          fg: ok ? YaadainTheme.primaryDark : YaadainTheme.accentDark,
                        ),
                      ]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
