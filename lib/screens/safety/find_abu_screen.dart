import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/family_member.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import '../../tracking/tracking_source.dart';
import '../../util/en_format.dart';
import 'widgets/safety_family_common.dart';

/// "I can't find him": one calm place with everything needed in the first
/// minutes: call, tell his phone, share the missing pack, who is helping.
class FindAbuScreen extends StatelessWidget {
  const FindAbuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final name = whoName(app);
    final status = app.elderStatus;
    final alert = app.activeAlert;
    final pack = _Pack.of(app);
    final inv = _lastKnown(app, status);
    final coming = alert?.etaMin != null && alert?.isAcknowledged == true;

    return FamilyScaffold(
      header: _Header(name: name, line: inv),
      bottom: SafetyButton.primary('Mark as found',
          icon: YI.checkCircle, height: 56, fontSize: 17, onTap: () async {
        await app.markFound();
        if (context.mounted) {
          safetyToast(context, '$name is marked as found.');
          Navigator.of(context).maybePop();
        }
      }),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 16),
        SafetyButton.care('Call $name',
            icon: YI.phone, onTap: () => _call(context, elderPhone(app))),
        const SizedBox(height: 10),
        SafetyButton.primary(
          coming ? 'You are on the way' : 'Send “I’m coming” to his phone',
          icon: coming ? YI.check : YI.send,
          onTap: coming ? null : () => app.imOnMyWay(),
        ),
        const SizedBox(height: 10),
        SafetyButton.quiet('Share live status with family',
            icon: YI.users, onTap: () => _shareStatus(context, app, status)),
        const SizedBox(height: 16),
        _PackCard(app: app, pack: pack),
        SafetySectionHeader('Who is helping', trailing: _responded(app, alert)),
        _Helpers(app: app, alert: alert),
        const SizedBox(height: 12),
        Row(children: [
          _Emergency(label: 'Police', number: '15'),
          const SizedBox(width: 8),
          _Emergency(label: 'Edhi', number: '115'),
          const SizedBox(width: 8),
          _Emergency(label: 'Chhipa', number: '1020'),
        ]),
        const SizedBox(height: 12),
      ]),
    );
  }

  static String _lastKnown(AppState app, ElderStatus? s) {
    if (s == null) return 'No position received from his phone yet';
    final b = StringBuffer('Last known ${tLower(s.at)}');
    b.write(s.inside ? ' · at home' : ' · ${locationSentence(app, s)}');
    if (s.battery != null) b.write(' · phone ${s.battery}%');
    return b.toString();
  }

  static String _responded(AppState app, ActiveAlert? alert) {
    final me = app.settings.contributorMemberId;
    final total = app.circle
        .where((c) => c.escalationOrder < 99 && c.memberId != me)
        .length;
    if (total == 0) return '';
    final n = alert?.isAcknowledged == true ? 1 : 0;
    return '$n of $total responded';
  }

  static Future<void> _call(BuildContext context, String? phone) async {
    if (phone == null) {
      safetyToast(context, 'Add his phone number to the missing pack first.');
      return;
    }
    final ok = await Svc.launcher.call(EnFmt.telDigits(phone));
    if (!ok && context.mounted)
      safetyToast(context, 'Could not open the dialer.');
  }

  static Future<void> _shareStatus(
      BuildContext context, AppState app, ElderStatus? s) async {
    final text = s == null
        ? '${app.elderNameEn} cannot be found and his phone has not reported a position. Please call ${app.myNameEn}.'
        : '${app.elderNameEn}: ${_lastKnown(app, s)}. Please call ${app.myNameEn} if you can help.';
    await _openShare(context, text);
  }
}

Future<void> _openShare(BuildContext context, String text) async {
  final ok = await Svc.launcher
      .openUrl('https://wa.me/?text=${Uri.encodeComponent(text)}');
  if (!ok) {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted)
      safetyToast(context, 'WhatsApp is not available. The message is copied.');
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String line;
  const _Header({required this.name, required this.line});

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, inset + 8, 16, 14),
      decoration: const BoxDecoration(
        color: YaadainTheme.emergencySoft,
        border: Border(bottom: BorderSide(color: Color(0x33B3261E))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          FamilyIconButton(
            icon: YI.chevronLeft,
            label: 'Back',
            color: YaadainTheme.emergency,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: EnText('Find $name',
                size: 26,
                weight: FontWeight.w700,
                display: true,
                color: YaadainTheme.emergency,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                color: YaadainTheme.emergency,
                borderRadius: YaadainTheme.radiusPill),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              EnText('Missing',
                  size: 12,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: YIcon(YI.clock,
                size: 16, color: YaadainTheme.emergency, strokeWidth: 2.4),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: EnText(line,
                  size: 14,
                  weight: FontWeight.w800,
                  color: YaadainTheme.emergency,
                  height: 1.3)),
        ]),
      ]),
    );
  }
}

/// Everything shown on the pack card, read from real data with gentle blanks.
class _Pack {
  final String fullName;
  final int? age;
  final String answers;
  final String speaks;
  final String looks;
  final String medication;
  final String home;
  final String places;
  final String contact;
  final bool ready;
  final String shareText;

  _Pack(
      this.fullName,
      this.age,
      this.answers,
      this.speaks,
      this.looks,
      this.medication,
      this.home,
      this.places,
      this.contact,
      this.ready,
      this.shareText);

  static String _s(Object? v) => v is String ? v.trim() : '';

  factory _Pack.of(AppState app) {
    final p = app.care.missingPack;
    final fullName =
        _s(p['fullName']).isNotEmpty ? _s(p['fullName']) : app.elderNameEn;
    final age = p['age'] is num ? (p['age'] as num).round() : null;
    final answers = _s(p['answersTo']).isNotEmpty
        ? _s(p['answersTo'])
        : 'Answers to ${app.elderNameEn}.';
    final speaks = _s(p['speaks']);
    final bits = <String>[];
    final build = [
      _s(p['height']),
      _s(p['build']).toLowerCase(),
      _s(p['beard']).toLowerCase(),
      _s(p['glasses']).toLowerCase()
    ].where((e) => e.isNotEmpty).join(', ');
    if (build.isNotEmpty) bits.add(build);
    final clothes = _s(p['clothes']);
    var looks = build;
    if (clothes.isNotEmpty)
      looks = looks.isEmpty
          ? 'Today: ${clothes.toLowerCase()}'
          : '$looks. Today: ${clothes[0].toLowerCase()}${clothes.substring(1)}';
    if (looks.isNotEmpty && !looks.endsWith('.')) looks = '$looks.';
    var med = _s(p['medication']);
    if (med.isEmpty) {
      med = app.routine
          .where((r) => r.kind.name == 'medicine' && r.detail.isNotEmpty)
          .map((r) => r.detail)
          .toSet()
          .join(' · ');
    }
    final home = app.elder.homeAddress ?? '';
    final placesList = p['places'] is List
        ? (p['places'] as List)
            .whereType<String>()
            .where((e) => e.trim().isNotEmpty)
            .toList()
        : <String>[];
    final primary = app.primaryContact;
    final phone = _s(p['contactPhone']).isNotEmpty
        ? _s(p['contactPhone'])
        : (primary?.phone ?? '');
    final contact = primary == null && phone.isEmpty
        ? ''
        : '${primary?.firstNameEn ?? ''} $phone'.trim();
    final ready = looks.isNotEmpty && contact.isNotEmpty;
    final text =
        StringBuffer('MISSING: $fullName${age != null ? ', $age' : ''}.\n')
          ..writeln(answers)
          ..writeln(speaks.isNotEmpty ? speaks : '')
          ..writeln(looks.isNotEmpty ? 'Looks: $looks' : '')
          ..writeln(med.isNotEmpty ? 'Medication: $med' : '')
          ..writeln(home.isNotEmpty ? 'Home: $home' : '')
          ..writeln(placesList.isNotEmpty
              ? 'Places he may go: ${placesList.join(', ')}'
              : '')
          ..writeln(contact.isNotEmpty ? 'Please call: $contact' : '');
    return _Pack(
        fullName,
        age,
        answers,
        speaks,
        looks,
        med,
        home,
        placesList.join(' · '),
        contact,
        ready,
        text.toString().replaceAll(RegExp(r'\n{2,}'), '\n').trim());
  }
}

class _PackCard extends StatelessWidget {
  final AppState app;
  final _Pack pack;
  const _PackCard({required this.app, required this.pack});

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EnText(label,
              size: 11,
              weight: FontWeight.w800,
              color: YaadainTheme.muted,
              letterSpacing: 0.9),
          const SizedBox(height: 4),
          value.isEmpty
              ? EnText('Not added yet',
                  size: 14, weight: FontWeight.w600, color: YaadainTheme.muted)
              : EnText(value, size: 15, weight: FontWeight.w700, height: 1.35),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final photo = app.elder.photoPath;
    final initial =
        pack.fullName.isEmpty ? 'D' : pack.fullName[0].toUpperCase();
    final div = const Divider(height: 1, color: YaadainTheme.line);
    return YCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
                child: EnText('Missing pack',
                    size: 22, weight: FontWeight.w700, display: true)),
            const SizedBox(width: 8),
            if (pack.ready)
              const SafetyPill('Ready to share', icon: YI.check, height: 40)
            else
              const SafetyPill('Add details',
                  icon: YI.pencil,
                  height: 40,
                  bg: YaadainTheme.attentionSoft,
                  fg: YaadainTheme.accentDark),
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: YaadainTheme.line)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: photo != null && photo.isNotEmpty
                    ? Avatar(
                        monogram: initial,
                        size: 70,
                        tint: YaadainTheme.tintGold,
                        photoPath: photo)
                    : Container(
                        color: YaadainTheme.tintGold.bg,
                        alignment: Alignment.bottomCenter,
                        child: const YIcon(YI.user,
                            size: 56,
                            color: Color(0xFFA9998A),
                            strokeWidth: 2.4),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnText(
                        '${pack.fullName}${pack.age != null ? ', ${pack.age}' : ''}',
                        size: 18,
                        weight: FontWeight.w800,
                        height: 1.25),
                    const SizedBox(height: 2),
                    EnText(
                        [pack.answers, pack.speaks]
                            .where((e) => e.isNotEmpty)
                            .join(' '),
                        size: 14,
                        weight: FontWeight.w600,
                        color: YaadainTheme.muted,
                        height: 1.35),
                  ]),
            ),
          ]),
          const SizedBox(height: 8),
          _field('LOOKS', pack.looks),
          div,
          _field('MEDICATION', pack.medication),
          div,
          _field('HOME', pack.home),
          div,
          _field('PLACES HE MAY GO', pack.places),
          div,
          _field('CONTACT', pack.contact),
          const SizedBox(height: 8),
          SafetyButton.soft('Share pack on WhatsApp',
              icon: YI.share, onTap: () => _openShare(context, pack.shareText)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: SafetyButton.quiet('Print', icon: YI.fileText,
                  onTap: () async {
                await Clipboard.setData(ClipboardData(text: pack.shareText));
                if (context.mounted)
                  safetyToast(context,
                      'Pack copied. Paste it into a document to print.');
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: SafetyButton.quiet('Edit pack',
                    icon: YI.pencil, onTap: () => _edit(context))),
          ]),
        ]),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final p = app.care.missingPack;
    String g(String k) => p[k] is String ? p[k] as String : '';
    final clothes = TextEditingController(text: g('clothes'));
    final med = TextEditingController(text: g('medication'));
    final phone = TextEditingController(
        text: g('elderPhone').isNotEmpty ? g('elderPhone') : g('phone'));
    final places = TextEditingController(
        text: p['places'] is List ? (p['places'] as List).join(', ') : '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: YaadainTheme.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => FamilyTheme(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 20, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EnText('Edit missing pack',
                      size: 22, weight: FontWeight.w700, display: true),
                  const SizedBox(height: 12),
                  _input('What he is wearing today', clothes),
                  _input('Medication', med),
                  _input('His phone number', phone,
                      keyboard: TextInputType.phone),
                  _input('Places he may go (separate with commas)', places),
                  const SizedBox(height: 8),
                  SafetyButton.primary('Save', icon: YI.check, onTap: () {
                    p['clothes'] = clothes.text.trim();
                    p['medication'] = med.text.trim();
                    p['elderPhone'] = phone.text.trim();
                    p['places'] = places.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    app.refresh();
                    Navigator.of(ctx).pop();
                  }),
                ]),
          ),
        ),
      ),
    );
    clothes.dispose();
    med.dispose();
    phone.dispose();
    places.dispose();
  }

  Widget _input(String label, TextEditingController c,
          {TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: keyboard,
          style: YaadainTheme.en(15, weight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: YaadainTheme.line)),
          ),
        ),
      );
}

class _Helpers extends StatelessWidget {
  final AppState app;
  final ActiveAlert? alert;
  const _Helpers({required this.app, required this.alert});

  @override
  Widget build(BuildContext context) {
    final entries = app.circle.where((c) => c.escalationOrder < 99).toList()
      ..sort((a, b) => a.escalationOrder.compareTo(b.escalationOrder));
    final rows = <Widget>[];
    for (final c in entries) {
      final m = app.memberById(c.memberId);
      if (m == null ||
          m.isDeceased ||
          c.memberId == app.settings.contributorMemberId) continue;
      final acked =
          alert?.isAcknowledged == true && alert!.ackBy == m.firstNameEn;
      final String line;
      final String when;
      if (acked) {
        line = alert!.etaMin != null
            ? '${m.firstNameEn} is on the way'
            : '${m.firstNameEn} has seen the alert';
        when = alert!.ackAt != null
            ? EnFmt.relative(alert!.ackAt!, app.now)
                .replaceAll(' ago', '')
                .replaceAll('just now', 'now')
            : 'now';
      } else {
        line = '${m.firstNameEn} has been told';
        when = 'waiting';
      }
      if (rows.isNotEmpty)
        rows.add(const Divider(
            height: 1, color: YaadainTheme.line, indent: 16, endIndent: 16));
      rows.add(_helperRow(m, line, when));
    }
    if (rows.isEmpty) {
      return YCard(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: EnText(
              'No one else is set up to help yet. Call someone you trust.',
              size: 14,
              weight: FontWeight.w600,
              color: YaadainTheme.muted,
              height: 1.35),
        ),
      );
    }
    return YCard(
        radius: 20,
        padding: EdgeInsets.zero,
        child: SizedBox(width: double.infinity, child: Column(children: rows)));
  }

  Widget _helperRow(FamilyMember m, String line, String when) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Avatar.member(m, size: 44),
          const SizedBox(width: 12),
          Expanded(
              child:
                  EnText(line, size: 15, weight: FontWeight.w800, height: 1.3)),
          const SizedBox(width: 8),
          const YIcon(YI.clock,
              size: 16, color: YaadainTheme.muted, strokeWidth: 2.4),
          const SizedBox(width: 4),
          EnText(when,
              size: 14, weight: FontWeight.w700, color: YaadainTheme.muted),
        ]),
      );
}

class _Emergency extends StatelessWidget {
  final String label;
  final String number;
  const _Emergency({required this.label, required this.number});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: YCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        onTap: () => Svc.launcher.call(number),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EnText(label,
              size: 12, weight: FontWeight.w800, color: YaadainTheme.bodyDim),
          const SizedBox(height: 4),
          Row(children: [
            const YIcon(YI.phone,
                size: 16, color: YaadainTheme.emergency, strokeWidth: 2.4),
            const SizedBox(width: 6),
            EnText(number,
                size: 22, weight: FontWeight.w700, display: true, height: 1.1),
          ]),
        ]),
      ),
    );
  }
}
