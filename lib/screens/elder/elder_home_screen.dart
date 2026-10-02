import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/care.dart';
import '../../models/family_member.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../settings/locked_settings.dart';
import '../../state/app_state.dart';
import '../../config.dart';
import '../../models/memory_story.dart';
import '../../util/app_clock.dart';
import '../../util/prayer.dart';
import '../../util/time_mode.dart';
import '../../util/urdu_format.dart';
import 'widgets/elder_a_parts.dart';

/// The elder's home (Main + ElderHomeEvening). Day and evening share one
/// screen; the evening variant is calmer: a tinted orientation card, one big
/// Sukoon tile and only the two essential tiles.
class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends State<ElderHomeScreen> {
  Timer? _tick;
  final ScrollController _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    AppClock.revision.addListener(_refresh);
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tick?.cancel();
    _sc.dispose();
    AppClock.revision.removeListener(_refresh);
    super.dispose();
  }

  void _go(String route, [Object? args]) =>
      Navigator.of(context).pushNamed(route, arguments: args);

  void _help(AppState app) {
    unawaited(app.raiseHelp().catchError((_) {}));
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.madad, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final evening = app.timeMode == TimeMode.evening;
    final inset = MediaQuery.of(context).padding.top;
    final bandH = (evening ? 192.0 : 232.0) + inset;
    final overlap = evening ? 24.0 : 44.0;
    final now = app.now;
    final lines = _OrientLines.compute(app, evening);
    final story = evening ? null : _pickStory(app);
    final letter =
        evening || app.unseenLetters.isEmpty ? null : app.unseenLetters.first;
    final unseen = app.unseenLetters.isNotEmpty;
    final voices = app.members.where((m) => !m.isDeceased && m.hasVoice).length;
    final people = app.members.where((m) => !m.isDeceased).length;

    final body = Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: bandH,
          // The band scrolls away with the content so cards never slide over
          // its greeting.
          child: AnimatedBuilder(
            animation: _sc,
            builder: (context, child) => Transform.translate(
                offset: Offset(0, _sc.hasClients ? -_sc.offset : 0),
                child: child),
            child: _Band(app: app, now: now, evening: evening, inset: inset),
          ),
        ),
        SingleChildScrollView(
          controller: _sc,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: bandH - overlap),
                _OrientCard(lines: lines, now: now, app: app, evening: evening),
                const SizedBox(height: 16),
                if (evening) ...[
                  _SukoonTile(onTap: () => _go(Routes.sukoon)),
                  const SizedBox(height: 16),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: _Tile(
                          label: 'میرا خاندان',
                          icon: EldPaths.users,
                          evening: true,
                          onTap: () => _go(Routes.familyTree),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Tile(
                          label: 'آوازیں',
                          icon: EldPaths.audioLines,
                          evening: true,
                          badge: unseen ? 'نئی' : null,
                          onTap: () => _go(Routes.voices),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  if (story != null) ...[
                    _MemoryCard(
                      story: story.$2,
                      member: story.$1,
                      onTap: () => _playStory(story.$1, story.$2),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (letter != null) ...[
                    _VoiceTile(
                        app: app,
                        letter: letter,
                        onOpen: () => _go(Routes.voices),
                        onPlay: () => _playLetter(app, letter)),
                    const SizedBox(height: 16),
                  ],
                  _FamilyTile(
                    members: app.members
                        .where((m) => !m.isDeceased)
                        .take(3)
                        .toList(),
                    people: people,
                    voices: voices,
                    onTap: () => _go(Routes.familyTree),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                          child: _Tile(
                              label: 'یہ کون ہے؟',
                              icon: EldPaths.whoIs,
                              onTap: () => _go(Routes.whoIsThis))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _Tile(
                              label: 'پوچھیں',
                              icon: EldPaths.chat,
                              onTap: () => _go(Routes.poochhein))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: _Tile(
                          label: 'آوازیں',
                          icon: EldPaths.audioLines,
                          badge: unseen && letter == null ? 'نئی' : null,
                          onTap: () => _go(Routes.voices),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _Tile(
                              label: 'سکون',
                              icon: EldPaths.leaf,
                              onTap: () => _go(Routes.sukoon))),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        // Hidden caregiver gate over the avatar (the band sits under the
        // scroll view, so the gate has to live above it to get touches).
        Positioned(
          left: 24,
          top: inset + (evening ? 6 : 20),
          width: evening ? 88 : 96,
          height: evening ? 88 : 96,
          child: const ElderLogoGate(child: SizedBox.expand()),
        ),
      ],
    );

    return ElderScaffold(
      header: const SizedBox.shrink(),
      scroll: false,
      bodyPadding: EdgeInsets.zero,
      body: body,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EldBtn(
            'مجھے مدد چاہیے',
            bg: YaadainTheme.accentDark,
            fg: Colors.white,
            height: 80,
            size: 28,
            shadow: true,
            icon: EldIcon(EldPaths.shield, size: 28, color: Colors.white),
            onTap: () => _help(app),
          ),
          if (!evening) _SeeLine(app: app, onTap: () => _go(Routes.khayal)),
        ],
      ),
    );
  }

  (FamilyMember, MemoryStory)? _pickStory(AppState app) {
    for (final m in app.members) {
      if (m.isDeceased) continue;
      for (final s in m.stories) {
        if (s.audioPath != null || s.title.trim().isNotEmpty) return (m, s);
      }
    }
    for (final m in app.members) {
      for (final s in m.stories) {
        return (m, s);
      }
    }
    return null;
  }

  Future<void> _playStory(FamilyMember m, MemoryStory s) async {
    final p = s.audioPath;
    if (p != null && p.isNotEmpty) {
      try {
        await Svc.audio.play(p);
        return;
      } catch (_) {}
    }
    if (mounted) _go(Routes.memberDetail, MemberDetailArgs(m.id));
  }

  Future<void> _playLetter(AppState app, VoiceLetter l) async {
    if (l.audioPath == null) {
      _go(Routes.voices);
      return;
    }
    try {
      await app.playLetter(l);
    } catch (_) {
      if (mounted) _go(Routes.voices);
    }
  }
}

// ───────────────────────── orientation ─────────────────────────

class _OrientLine {
  final List<String> icon;
  final String text;
  const _OrientLine(this.icon, this.text);
}

class _OrientLines {
  final String headline;
  final List<_OrientLine> rows;
  const _OrientLines(this.headline, this.rows);

  static _OrientLines compute(AppState app, bool evening) {
    final now = app.now;
    final rows = <_OrientLine>[];

    final inside = app.elderStatus?.inside ?? true;
    final primary = app.primaryContact;
    final homeNames = <String>[];
    if (kTrackingIsDemo && inside) {
      if (primary != null) homeNames.add(primary.displayUr);
      for (final m in app.members) {
        if (m.id == primary?.id || m.isDeceased) continue;
        if (m.relationshipId == 'bahu' || m.relationshipId == 'daughter_in_law')
          homeNames.add(m.displayUr);
      }
    }
    final who = homeNames.isEmpty
        ? ''
        : homeNames.length == 1
            ? '${homeNames[0]} گھر پر ہے۔'
            : '${homeNames.take(2).join(' اور ')} گھر پر ہیں۔';
    final atHome = inside ? 'آپ گھر پر ہیں۔' : 'آپ گھر سے باہر ہیں۔';

    final pd = app.prayerToday;
    final next = pd.nextAfter(now);
    String? prayer;
    if (next != null) {
      prayer =
          '${next.ur} کی نماز ${eldBaje(pd.at(next)).replaceFirst(' بجے', '')} پر';
    } else {
      final fajr = pd.fajr.add(const Duration(days: 1));
      prayer = 'کل فجر کی نماز ${eldBaje(fajr).replaceFirst(' بجے', '')} پر';
    }

    final item = app.nextRoutineItem();
    String? food;
    if (item != null) {
      food = '${item.titleUr} ${eldBaje(app.routineDueAt(item))}';
    }

    final head = evening
        ? 'آج ${UrduFmt.weekday(now)} کی شام ہے۔'
        : UrduFmt.todayIs(now);
    if (evening) {
      rows.add(_OrientLine(EldPaths.calendar, head));
      rows.add(_OrientLine(EldPaths.moon, '$prayer۔'));
      rows.add(
          _OrientLine(EldPaths.home, who.isEmpty ? atHome : '$atHome $who'));
      if (food != null) rows.add(_OrientLine(EldPaths.utensils, food));
    } else {
      rows.add(_OrientLine(EldPaths.home, atHome));
      if (who.isNotEmpty) rows.add(_OrientLine(EldPaths.users, who));
      rows.add(_OrientLine(EldPaths.moon, '$prayer۔'));
      if (food != null) rows.add(_OrientLine(EldPaths.utensils, food));
    }
    return _OrientLines(head, rows);
  }
}

class _OrientCard extends StatelessWidget {
  final _OrientLines lines;
  final DateTime now;
  final AppState app;
  final bool evening;
  const _OrientCard(
      {required this.lines,
      required this.now,
      required this.app,
      required this.evening});

  @override
  Widget build(BuildContext context) {
    final iconSize = evening ? 28.0 : 24.0;
    final textSize = evening ? 28.0 : 24.0;
    final rows = <Widget>[
      for (final r in lines.rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: EldIcon(r.icon,
                    size: iconSize, color: YaadainTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(child: UrduText(r.text, size: textSize, height: 1.8)),
            ],
          ),
        ),
    ];

    return Semantics(
      container: true,
      child: Container(
        padding: evening
            ? const EdgeInsets.fromLTRB(20, 12, 20, 12)
            : const EdgeInsets.fromLTRB(24, 16, 24, 16),
        decoration: BoxDecoration(
          color: evening ? YaadainTheme.attentionSoft : YaadainTheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: Color(0x142C2620), blurRadius: 24, offset: Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!evening) ...[
              UrduText(lines.headline, size: 28, height: 1.8),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  UrduText(UrduFmt.date(now), size: 24, height: 1.8),
                  const SizedBox(width: 10),
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: YaadainTheme.gold, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Flexible(
                      child: UrduText(app.hijriToday.urdu,
                          size: 20, color: YaadainTheme.muted, height: 1.8)),
                ],
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: YaadainTheme.gold.withOpacity(.55)),
              const SizedBox(height: 8),
            ],
            ...rows,
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── header band ─────────────────────────

class _Band extends StatelessWidget {
  final AppState app;
  final DateTime now;
  final bool evening;
  final double inset;
  const _Band(
      {required this.app,
      required this.now,
      required this.evening,
      required this.inset});

  @override
  Widget build(BuildContext context) {
    final size = evening ? 88.0 : 96.0;
    final photo = app.elder.photoPath;
    final name = app.elderNameUr;
    // A kinship title is not his name: use the board's monogram (اکرم).
    final mono = name.isEmpty || name == 'دادا جان' ? 'ا' : name.characters.first;
    return Container(
      decoration: BoxDecoration(
        color: evening ? YaadainTheme.primaryDark : YaadainTheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: JaaliPattern(opacity: 0.08)),
          Padding(
            padding: EdgeInsets.fromLTRB(24, inset + (evening ? 6 : 20), 24, 0),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UrduText(UrduFmt.greeting(now),
                          size: 24,
                          color: Colors.white.withOpacity(.9),
                          height: 1.8),
                      UrduText(name,
                          size: 40,
                          color: Colors.white,
                          height: 1.8,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: YaadainTheme.attentionSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: EldPhotoOr(
                    path: photo,
                    size: size,
                    radius: size / 2,
                    fallback: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: UrduText(mono,
                            size: 40,
                            color: const Color(0xFF7D4219),
                            height: 1.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── cards ─────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color? border;
  final EdgeInsets padding;
  final double minHeight;
  final String? label;
  const _Card({
    required this.child,
    this.onTap,
    this.color = YaadainTheme.surface,
    this.border = YaadainTheme.line,
    this.padding = const EdgeInsets.all(16),
    this.minHeight = 0,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(28);
    return Semantics(
      button: onTap != null,
      label: label,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
            borderRadius: r,
            side:
                border == null ? BorderSide.none : BorderSide(color: border!)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final FamilyMember member;
  final MemoryStory story;
  final VoidCallback onTap;
  const _MemoryCard(
      {required this.member, required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final raw = story.title.trim();
    final title = raw.isEmpty || eldHasLatin(raw)
        ? '${member.displayUr} کی ایک پیاری یاد'
        : raw;
    return _Card(
      onTap: onTap,
      label: 'آج کی یاد۔ $title',
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          EldPhotoOr(
            path: story.photoPath,
            size: 64,
            radius: 16,
            fallback: const EldArtView(EldArt.mosque,
                width: 64, height: 64, radius: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const UrduText('آج کی یاد',
                    size: 20, color: YaadainTheme.muted, height: 1.8),
                UrduText(title,
                    size: 24,
                    height: 1.8,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          EldPlayDisc(label: 'یاد سنیں', onTap: onTap),
        ],
      ),
    );
  }
}

class _VoiceTile extends StatelessWidget {
  final AppState app;
  final VoiceLetter letter;
  final VoidCallback onOpen;
  final VoidCallback onPlay;
  const _VoiceTile(
      {required this.app,
      required this.letter,
      required this.onOpen,
      required this.onPlay});

  @override
  Widget build(BuildContext context) {
    FamilyMember? from;
    for (final m in app.members) {
      if (m.id == letter.memberId) from = m;
    }
    final name = from?.displayUr ?? 'آپ کا کوئی عزیز';
    final now = app.now;
    final sameDay = letter.at.year == now.year &&
        letter.at.month == now.month &&
        letter.at.day == now.day;
    final when = sameDay
        ? 'آج ${UrduFmt.period(letter.at)}'
        : UrduFmt.relative(letter.at, now);
    return _Card(
      onTap: onOpen,
      color: YaadainTheme.surface,
      border: YaadainTheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      minHeight: 88,
      label: 'نئی آواز: $name',
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          from == null
              ? const SizedBox(width: 56, height: 56)
              : Avatar.member(from, size: 56, urdu: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                UrduText('نئی آواز: $name',
                    size: 24,
                    height: 1.8,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                UrduText(when,
                    size: 20, color: YaadainTheme.muted, height: 1.8),
              ],
            ),
          ),
          const SizedBox(width: 12),
          EldPlayDisc(label: 'آواز سنیں', onTap: onPlay),
        ],
      ),
    );
  }
}

class _FamilyTile extends StatelessWidget {
  final List<FamilyMember> members;
  final int people;
  final int voices;
  final VoidCallback onTap;
  const _FamilyTile(
      {required this.members,
      required this.people,
      required this.voices,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = people == 0
        ? ''
        : voices > 0
            ? '${UrduFmt.digits(people)} لوگ، ${UrduFmt.digits(voices)} آوازیں'
            : '${UrduFmt.digits(people)} لوگ';
    return _Card(
      onTap: onTap,
      label: 'میرا خاندان',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Expanded(
                  child: UrduText('میرا خاندان', size: 28, height: 1.8)),
              EldIcon(EldPaths.chevronLeft,
                  size: 24, color: YaadainTheme.muted),
            ],
          ),
          if (members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  SizedBox(
                    width: 44.0 + (members.length - 1) * 32,
                    height: 44,
                    child: Stack(
                      children: [
                        for (var i = 0; i < members.length; i++)
                          Positioned(
                            right: i * 32.0,
                            child: Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3)),
                              child: Avatar.member(members[i],
                                  size: 44, urdu: true),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: UrduText(count,
                          size: 20, color: YaadainTheme.muted, height: 1.8)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final List<String> icon;
  final VoidCallback onTap;
  final bool evening;
  final String? badge;
  const _Tile(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.evening = false,
      this.badge});

  @override
  Widget build(BuildContext context) {
    final circle =
        evening ? YaadainTheme.attentionSoft : YaadainTheme.primarySoft;
    final fg = evening ? const Color(0xFF7D4219) : YaadainTheme.primary;
    return _Card(
      onTap: onTap,
      minHeight: evening ? 120 : 112,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(color: circle, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: EldIcon(icon, size: 24, color: fg),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                UrduChip(badge!)
              ],
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: UrduText(label,
                size: 24,
                height: 1.9,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _SukoonTile extends StatelessWidget {
  final VoidCallback onTap;
  const _SukoonTile({required this.onTap});

  @override
  Widget build(BuildContext context) => _Card(
        onTap: onTap,
        color: YaadainTheme.primarySoft,
        border: null,
        minHeight: 128,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        label: 'سکون',
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: EldIcon(EldPaths.play,
                  size: 32, color: YaadainTheme.primary, fill: true),
            ),
            const SizedBox(width: 20),
            const Expanded(child: UrduText('سکون', size: 36, height: 1.8)),
            EldIcon(EldPaths.leaf, size: 32, color: YaadainTheme.primary),
          ],
        ),
      );
}

/// Quiet transparency line under the help button (day only): the elder is
/// told, calmly, that family can see where he is.
class _SeeLine extends StatelessWidget {
  final AppState app;
  final VoidCallback onTap;
  const _SeeLine({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = app.primaryContact;
    final text = kTrackingIsDemo && p != null
        ? 'آج ${p.displayUr} نے ${UrduFmt.digits(2)} بار دیکھا کہ آپ کہاں ہیں'
        : 'آپ کے گھر والے دیکھ سکتے ہیں کہ آپ کہاں ہیں';
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EldIcon(EldPaths.eye, size: 20, color: YaadainTheme.muted),
                const SizedBox(width: 8),
                Flexible(
                    child: UrduText(text,
                        size: 20,
                        color: YaadainTheme.muted,
                        height: 1.8,
                        align: TextAlign.center)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
