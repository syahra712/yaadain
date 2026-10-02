import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/care.dart';
import '../../models/family_member.dart';
import '../../state/app_state.dart';
import 'widgets/elder_a_parts.dart';

/// A routine item is due (medicine, meal, walk): a caregiver voice-led,
/// one-question screen. "لے لی" logs it; "تھوڑی دیر بعد" snoozes once, then
/// the caregiver is told (logged as skipped).
class RoutinePromptScreen extends StatefulWidget {
  final String? itemId;
  const RoutinePromptScreen({super.key, this.itemId});

  /// Items already snoozed once today (by id).
  static final Set<String> _snoozed = {};

  @override
  State<RoutinePromptScreen> createState() => _RoutinePromptScreenState();
}

class _RoutinePromptScreenState extends State<RoutinePromptScreen> {
  RoutineItem? _item(AppState app) {
    final id = widget.itemId;
    if (id != null) {
      for (final i in app.care.routine) {
        if (i.id == id) return i;
      }
    }
    return app.nextRoutineItem();
  }

  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.popUntil((r) => r.isFirst);
    }
  }

  Future<void> _taken(AppState app, RoutineItem? item) async {
    if (item != null) {
      try {
        await app.markRoutine(item.id, 'taken', by: app.elderNameEn);
      } catch (_) {}
    }
    if (mounted) _close();
  }

  Future<void> _later(AppState app, RoutineItem? item) async {
    if (item != null) {
      final key = '${RoutineLog.dayKey(app.now)}/${item.id}';
      if (RoutinePromptScreen._snoozed.contains(key)) {
        // Second ask: the caregiver sees it as skipped.
        try {
          await app.markRoutine(item.id, 'skipped', by: app.elderNameEn);
        } catch (_) {}
      } else {
        RoutinePromptScreen._snoozed.add(key);
        Timer(const Duration(minutes: 10), () {
          if (app.routineLogToday(item.id) == null) app.testRoutinePrompt();
        });
      }
    }
    if (mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final item = _item(app);
    final FamilyMember? who = app.primaryContact;
    final call = who != null && who.callsHimUr.isNotEmpty ? who.callsHimUr : app.elderNameUr;
    final isMed = item == null || item.kind == RoutineKind.medicine;
    final title = item == null
        ? '$call، دوا کا وقت ہے'
        : isMed
            ? '$call، دوا کا وقت ہے'
            : '$call، ${item.titleUr} کا وقت ہے';
    final detail = item == null
        ? 'ایک گولی، پانی کے ساتھ۔'
        : isMed
            ? '${item.titleUr}۔ ایک گولی، پانی کے ساتھ۔'
            : '${item.titleUr}۔';
    final voiceName = who == null ? 'آپ کے گھر والے' : who.displayUr;

    return ElderScaffold(
      header: const SizedBox.shrink(),
      background: Colors.white,
      scroll: false,
      body: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Padding(
              padding: const EdgeInsets.only(top: 48, bottom: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (who != null) Avatar.member(who, size: 80, urdu: true),
                        if (who != null) const SizedBox(width: 12),
                        Flexible(
                            child: UrduText('$voiceName کی آواز',
                                size: 20, color: YaadainTheme.muted, height: 1.8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(liveRegion: true, child: UrduText(title, size: 36, height: 1.8, align: TextAlign.center)),
                  const SizedBox(height: 16),
                  if (isMed) ...[
                    DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: YaadainTheme.line),
                      ),
                      child: const EldArtView(EldArt.medicineScene,
                          radius: 24, shadow: true),
                    ),
                    const SizedBox(height: 16),
                  ],
                  UrduText(detail, size: 28, height: 1.8, align: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EldBtn(
            'لے لی',
            bg: YaadainTheme.accentDark,
            fg: Colors.white,
            height: 80,
            size: 28,
            shadow: true,
            icon: EldIcon(EldPaths.check, size: 28, color: Colors.white, stroke: 2.5),
            onTap: () => _taken(app, item),
          ),
          const SizedBox(height: 12),
          EldBtn(
            'تھوڑی دیر بعد',
            bg: Colors.white,
            fg: YaadainTheme.ink,
            border: YaadainTheme.stroke,
            borderWidth: 2,
            height: 64,
            size: 24,
            icon: EldIcon(EldPaths.clock, size: 24, color: YaadainTheme.ink),
            onTap: () => _later(app, item),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
