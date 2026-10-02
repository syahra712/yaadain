import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/family_member.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import '../../tracking/tracking_source.dart';
import '../../util/time_mode.dart';
import 'widgets/safety_elder_widgets.dart';

/// "Bilal is coming" (visit state) and "you are home, you are safe"
/// (back-home state, closes itself after a minute).
class ImSafeScreen extends StatefulWidget {
  final String? byName;
  final String? memberId;
  final int? etaMin;
  const ImSafeScreen({super.key, this.byName, this.memberId, this.etaMin});

  @override
  State<ImSafeScreen> createState() => _ImSafeScreenState();
}

class _ImSafeScreenState extends State<ImSafeScreen> {
  bool _hadVisit = false;
  bool _playing = false;
  StreamSubscription<bool>? _playSub;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    try {
      _playSub = Svc.audio.playing.listen((p) {
        if (mounted) setState(() => _playing = p);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _playSub?.cancel();
    _closeTimer?.cancel();
    try {
      Svc.audio.stop();
    } catch (_) {}
    super.dispose();
  }

  bool get _hasArgs =>
      widget.byName != null || widget.memberId != null || widget.etaMin != null;

  FamilyMember? _visitor(AppState app, Visit? visit) {
    final id = widget.memberId ?? visit?.memberId;
    if (id != null) {
      final m = app.memberById(id);
      if (m != null) return m;
    }
    final by = (widget.byName ?? visit?.by)?.trim().toLowerCase();
    if (by != null && by.isNotEmpty) {
      for (final m in app.members) {
        if (!m.isDeceased && m.nameEn.trim().toLowerCase() == by) return m;
      }
    }
    return SafetyContacts.of(app).first;
  }

  void _goRest(AppState app) {
    final evening = app.timeMode == TimeMode.evening;
    goRoot(evening ? Routes.sukoon : elderRouteForTime(app.now));
  }

  void _scheduleClose(AppState app) {
    if (_closeTimer != null) return;
    _closeTimer = Timer(const Duration(seconds: 60), () {
      if (mounted) _goRest(app);
    });
  }

  Future<void> _togglePlay(FamilyMember m) async {
    final p = m.greetingAudioPath;
    if (p == null || p.isEmpty) return;
    try {
      if (_playing) {
        await Svc.audio.stop();
      } else {
        await Svc.audio.play(p);
      }
    } catch (_) {}
  }

  Future<void> _call(FamilyMember m) async {
    final ok = await dialMember(m);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: UrduText('فون نہیں ہو سکا', size: 20, color: Colors.white),
        duration: Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final visit = app.currentVisit;
    if (visit != null) _hadVisit = true;
    final inside = app.elderStatus?.inside ?? true;
    final backHome = visit == null && (_hadVisit || !_hasArgs) && inside;
    if (backHome) {
      _scheduleClose(app);
    } else {
      _closeTimer?.cancel();
      _closeTimer = null;
    }

    final bottomPad = MediaQuery.of(context).padding.bottom;
    final who = _visitor(app, visit);
    final eta = widget.etaMin ?? visit?.etaMin;

    return ElderTheme(
      child: Scaffold(
        backgroundColor: YaadainTheme.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafetyHeader(title: backHome ? 'آپ گھر پر ہیں' : 'آپ محفوظ ہیں'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: backHome ? _homeBody() : _visitBody(who, eta),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 32 + bottomPad),
              child: backHome ? _homeActions(app) : _visitActions(who),
            ),
          ],
        ),
      ),
    );
  }

  Widget _halo({required Widget face, required Widget badgeIcon}) {
    return SizedBox(
      width: 184,
      height: 184,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YaadainTheme.primary.withOpacity(0.07))),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: YaadainTheme.primary.withOpacity(0.10))),
          ),
          face,
          Positioned(
            right: 2,
            bottom: 6,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: YaadainTheme.primary,
                boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 4)],
              ),
              alignment: Alignment.center,
              child: badgeIcon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _visitBody(FamilyMember? who, int? eta) {
    final String headline;
    if (who == null) {
      headline = 'گھر والے آ رہے ہیں';
    } else if (who.kinshipUrdu.startsWith('آپ کی')) {
      headline = '${who.displayUr} آ رہی ہیں';
    } else {
      headline = '${who.displayUr} آ رہا ہے';
    }
    return Column(
      children: [
        _halo(
          face: SafetyFace(member: who, size: 160),
          badgeIcon: const YIcon(YI.clock,
              size: 26, color: Colors.white, strokeWidth: 2.2),
        ),
        const SizedBox(height: 8),
        UrduText(headline, size: 40, height: 1.8, align: TextAlign.center),
        if (eta != null)
          UrduText('تقریباً ${urduMinutesWord(eta)} منٹ میں',
              size: 28,
              color: YaadainTheme.muted,
              height: 2.0,
              align: TextAlign.center),
        const SizedBox(height: 4),
        const UrduText('آپ وہیں رہیں۔ آپ محفوظ ہیں۔',
            size: 24,
            color: YaadainTheme.bodyDim,
            height: 2.2,
            align: TextAlign.center),
      ],
    );
  }

  Widget _homeBody() {
    return Column(
      children: [
        _halo(
          face: Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: YaadainTheme.primarySoft,
              boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 5)],
            ),
            alignment: Alignment.center,
            child:
                const YIcon(YI.home, size: 72, color: YaadainTheme.primaryDark),
          ),
          badgeIcon: const YIcon(YI.check,
              size: 26, color: Colors.white, strokeWidth: 2.4),
        ),
        const SizedBox(height: 8),
        const UrduText('آپ گھر پر ہیں۔',
            size: 40, height: 1.8, align: TextAlign.center),
        const UrduText('آپ محفوظ ہیں۔',
            size: 28,
            color: YaadainTheme.muted,
            height: 2.0,
            align: TextAlign.center),
      ],
    );
  }

  Widget _visitActions(FamilyMember? who) {
    final voice = who != null && (who.greetingAudioPath ?? '').isNotEmpty;
    final canCall = who != null && (who.phone ?? '').trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (who != null && (voice || canCall)) ...[
          Container(
            height: 1,
            margin: const EdgeInsets.fromLTRB(48, 0, 48, 8),
            color: YaadainTheme.gold.withOpacity(0.55),
          ),
          if (voice) ...[
            SafetyButton(
              label:
                  _playing ? 'آواز بند کریں' : '${who.displayUr} کی آواز سنیے',
              icon: _playing ? YI.pause : YI.volumeMirrored,
              bg: YaadainTheme.primary,
              onTap: () => _togglePlay(who),
            ),
            const SizedBox(height: 12),
          ],
          if (canCall)
            SafetyButton(
              label: '${who.displayUr} کو فون کریں',
              icon: YI.phone,
              bg: YaadainTheme.accentDark,
              onTap: () => _call(who),
            ),
        ],
      ],
    );
  }

  Widget _homeActions(AppState app) {
    return SafetyButton(
      label: 'ٹھیک ہے',
      icon: YI.check,
      bg: YaadainTheme.primary,
      onTap: () => _goRest(app),
    );
  }
}
