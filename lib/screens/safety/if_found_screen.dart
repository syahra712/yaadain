import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/family_member.dart';
import '../../state/app_state.dart';
import '../../util/urdu_format.dart';
import 'widgets/safety_elder_widgets.dart';

/// The card a stranger reads when the elder shows them the phone. Two pure
/// states, Urdu (default) and English, toggled by the 56 px globe button.
class IfFoundScreen extends StatefulWidget {
  /// Initial language: false = Urdu, true = English.
  final bool english;
  const IfFoundScreen({super.key, this.english = false});

  @override
  State<IfFoundScreen> createState() => _IfFoundScreenState();
}

class _IfFoundScreenState extends State<IfFoundScreen> {
  late bool _en = widget.english;

  Future<void> _call(FamilyMember m) async {
    final ok = await dialMember(m);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: _en
            ? const EnText('Could not place the call.',
                size: 16, weight: FontWeight.w700, color: Colors.white)
            : const UrduText('فون نہیں ہو سکا', size: 20, color: Colors.white),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final contacts = SafetyContacts.of(app);
    final id = SafetyIdentity.of(app);
    final photo = app.elder.photoPath;
    return _en
        ? _english(app, contacts, id, photo)
        : _urdu(app, contacts, id, photo);
  }

  // ── Urdu state ────────────────────────────────────────────────────────

  static String _relUr(FamilyMember m) {
    switch (m.relationshipId) {
      case 'beta':
        return 'ان کے بیٹے ${m.displayUr}';
      case 'beti':
        return 'ان کی بیٹی ${m.displayUr}';
      default:
        return m.displayUr;
    }
  }

  Widget _urdu(
      AppState app, SafetyContacts c, SafetyIdentity id, String? photo) {
    final first = c.first;
    final second = c.second;
    final address = (app.elder.homeAddressUr ?? '').trim().isNotEmpty &&
            RegExp(r'[؀-ۿ]').hasMatch(app.elder.homeAddressUr!)
        ? UrduFmt.digits(app.elder.homeAddressUr!.trim())
        : urduAddress(app.elder.homeAddress);
    final title = id.formal
        ? 'یہ ${id.nameUr} صاحب ہیں${id.age != null ? '، عمر ${UrduFmt.digits(id.age!)} سال' : ''}۔'
        : 'یہ ${id.nameUr} ہیں۔';
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ElderTheme(
      child: Scaffold(
        backgroundColor: YaadainTheme.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        ElderPhotoTile(photoPath: photo),
                        const SizedBox(width: 18),
                        Expanded(child: UrduText(title, size: 28, height: 2.0)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const UrduText('انہیں بھولنے کی بیماری ہے۔',
                        size: 24, height: 2.2),
                    UrduText(
                      first != null
                          ? 'براہِ کرم ${_relUr(first)} کو فون کریں۔'
                          : 'براہِ کرم ان کے گھر والوں کو فون کریں۔',
                      size: 24,
                      height: 2.2,
                    ),
                    if (first != null || second != null)
                      const SizedBox(height: 54),
                    if (first != null)
                      SafetyButton(
                        label: '${first.displayUr} کو فون کریں',
                        sub: UrduFmt.digits((first.phone ?? '').trim()),
                        icon: YI.phone,
                        bg: YaadainTheme.accentDark,
                        minHeight: 88,
                        iconSize: 30,
                        gap: 16,
                        onTap: () => _call(first),
                      ),
                    if (second != null) ...[
                      const SizedBox(height: 12),
                      SafetyButton(
                        label: '${second.displayUr} کو فون کریں',
                        icon: YI.phone,
                        bg: YaadainTheme.primary,
                        minHeight: 64,
                        fontSize: 22,
                        onTap: () => _call(second),
                      ),
                    ],
                    if (address != null) ...[
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        textDirection: TextDirection.rtl,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 14),
                            child: YIcon(YI.mapPin,
                                size: 22, color: YaadainTheme.stroke),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: UrduText('گھر کا پتہ: $address',
                                  size: 20,
                                  color: YaadainTheme.bodyDim,
                                  height: 2.0)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 32 + bottomPad),
              child: SizedBox(
                height: 56,
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const YIcon(YI.heart,
                        size: 24, color: YaadainTheme.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: UrduText('براہِ کرم ان کے ساتھ رہیں۔',
                            size: 24, height: 2.2)),
                    const SizedBox(width: 16),
                    _GlobeButton(
                        label: 'English',
                        onTap: () => setState(() => _en = true)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── English state ─────────────────────────────────────────────────────

  Widget _english(
      AppState app, SafetyContacts c, SafetyIdentity id, String? photo) {
    final first = c.first;
    final second = c.second;
    final address = app.elder.homeAddress?.trim();
    final title = id.formal
        ? 'This is Mr ${id.nameEn}${id.age != null ? ', ${id.age}' : ''}.'
        : 'This is ${id.nameEn}.';
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return FamilyTheme(
      child: Scaffold(
        backgroundColor: YaadainTheme.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        ElderPhotoTile(photoPath: photo),
                        const SizedBox(width: 18),
                        Expanded(
                            child: EnText(title,
                                size: 28,
                                weight: FontWeight.w600,
                                display: true,
                                height: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const EnText('He has a memory illness.',
                        size: 20, weight: FontWeight.w600, height: 1.5),
                    const SizedBox(height: 6),
                    EnText(
                      first != null
                          ? 'Please call his ${first.kinshipEnglish.toLowerCase()} ${first.displayEn}.'
                          : 'Please call his family.',
                      size: 20,
                      weight: FontWeight.w600,
                      height: 1.5,
                    ),
                    if (first != null || second != null)
                      const SizedBox(height: 38),
                    if (first != null)
                      SafetyButton(
                        label: 'Call ${first.displayEn}',
                        sub: (first.phone ?? '').trim().isEmpty
                            ? null
                            : first.phone!.trim(),
                        icon: YI.phone,
                        bg: YaadainTheme.accentDark,
                        english: true,
                        minHeight: 72,
                        fontSize: 20,
                        iconSize: 26,
                        onTap: () => _call(first),
                      ),
                    if (second != null) ...[
                      const SizedBox(height: 12),
                      SafetyButton(
                        label:
                            'Call his ${second.kinshipEnglish.toLowerCase()} ${second.displayEn}',
                        icon: YI.phone,
                        bg: YaadainTheme.primary,
                        english: true,
                        minHeight: 56,
                        fontSize: 17,
                        iconSize: 20,
                        gap: 10,
                        onTap: () => _call(second),
                      ),
                    ],
                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: YIcon(YI.mapPin,
                                size: 20, color: YaadainTheme.stroke),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: EnText('Home: $address',
                                  size: 16,
                                  weight: FontWeight.w600,
                                  color: YaadainTheme.bodyDim,
                                  height: 1.45)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 32 + bottomPad),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    _GlobeButton(
                        label: 'Urdu',
                        onTap: () => setState(() => _en = false)),
                    const SizedBox(width: 16),
                    const YIcon(YI.heart,
                        size: 24, color: YaadainTheme.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                        child: EnText('Please stay with him.',
                            size: 20, weight: FontWeight.w700, height: 1.3)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Status-bar inset plus the 6 px teal bar.
  Widget _topBar() {
    final inset = MediaQuery.of(context).padding.top;
    return Container(
        height: inset + 6,
        color: Colors.transparent,
        alignment: Alignment.bottomCenter,
        child: Container(height: 6, color: YaadainTheme.primary));
  }
}

/// 56 px icon-only globe toggle (label is for screen readers only, in the
/// language of the state it switches to).
class _GlobeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GlobeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: YaadainTheme.surface,
        shape: const CircleBorder(
            side: BorderSide(color: YaadainTheme.stroke, width: 1.5)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
              width: 56,
              height: 56,
              child: Center(
                  child: YIcon(YI.globe, size: 26, color: YaadainTheme.ink))),
        ),
      ),
    );
  }
}
