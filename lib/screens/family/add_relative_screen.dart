import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/family_member.dart';
import '../../models/relationship.dart';
import '../../state/app_state.dart';
import 'widgets/family_b_common.dart';

/// Family: add a relative, or edit one (`memberId` set). Route `/care/add-relative`.
class AddRelativeScreen extends StatefulWidget {
  /// null = add, set = edit.
  final String? memberId;
  const AddRelativeScreen({super.key, this.memberId});

  @override
  State<AddRelativeScreen> createState() => _AddRelativeScreenState();
}

class _Group {
  final String name;
  final List<String> ids;
  const _Group(this.name, this.ids);
}

const List<_Group> _groups = [
  _Group('Spouse', ['shohar', 'biwi']),
  _Group('Children', ['beta', 'beti']),
  _Group('Grandchildren', ['pota', 'poti', 'nawasa', 'nawasi']),
  _Group('Siblings', ['bhai', 'behn']),
  _Group('Parents', ['walid', 'walida', 'dada', 'dadi', 'nana', 'nani']),
  _Group('Uncles and aunts', ['chacha', 'taya', 'chachi', 'tai', 'mamu', 'mumani', 'khala', 'khalu', 'phupho', 'phupha']),
  _Group('Nieces and nephews', ['bhateeja', 'bhateeji', 'bhanja', 'bhanji']),
  _Group('In-laws', ['bahu', 'damaad', 'samdhi', 'samdhan', 'bhabhi', 'behnoi', 'saala', 'saali', 'devar', 'jeth', 'nand']),
  _Group('Friends and carers', ['dost', 'parosi', 'doctor', 'dekhbhaal', 'rishtedaar']),
];

class _AddRelativeScreenState extends State<AddRelativeScreen> {
  final _name = TextEditingController();
  final _nameUr = TextEditingController();
  final _callsThem = TextEditingController();
  final _callsHim = TextEditingController();
  final _phone = TextEditingController();
  final FbRecorder _rec = FbRecorder(maxSec: 10);

  FamilyMember? _existing;
  String? _relId;
  int _group = 0;
  bool _open = false;
  bool _deceased = false;
  String? _photo;
  String? _greeting; // existing stored greeting
  String _initThem = '';
  String _initHim = '';
  bool _saving = false;
  bool _submitted = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _rec.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final app = context.read<AppState>();
    final id = widget.memberId;
    final m = id == null ? null : app.memberById(id);
    if (m != null) {
      _existing = m;
      _name.text = m.nameEn;
      _nameUr.text = m.nameUr;
      _relId = relationshipById(m.relationshipId) == null ? null : m.relationshipId;
      _initThem = m.callsThemUr.isNotEmpty ? m.callsThemUr : m.callsThemEn;
      _initHim = m.callsHimUr.isNotEmpty ? m.callsHimUr : m.callsHimEn;
      _callsThem.text = _initThem;
      _callsHim.text = _initHim;
      _phone.text = m.phone ?? '';
      _deceased = m.isDeceased;
      _photo = m.photoPath;
      _greeting = m.greetingAudioPath;
      _group = _groupOf(_relId);
    } else {
      _open = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nameUr.dispose();
    _callsThem.dispose();
    _callsHim.dispose();
    _phone.dispose();
    _rec.dispose();
    super.dispose();
  }

  static int _groupOf(String? id) {
    for (var i = 0; i < _groups.length; i++) {
      if (_groups[i].ids.contains(id)) return i;
    }
    return 0;
  }

  Relationship? get _rel => relationshipById(_relId);
  bool get _female => _rel?.gender == Gender.female;
  bool get _male => _rel?.gender == Gender.male;
  String get _her => _female ? 'her' : (_male ? 'his' : 'their');

  // ── Validation ──────────────────────────────────────────────────────

  String? get _nameErr => _submitted && _name.text.trim().isEmpty ? 'Please enter a name.' : null;
  String? get _relErr => _submitted && _relId == null ? 'Please choose how they are related.' : null;
  String? get _phoneErr {
    if (!_submitted) return null;
    final t = _phone.text.trim();
    if (t.isEmpty) return null;
    final digits = t.replaceAll(RegExp(r'\D'), '');
    return digits.length < 7 ? 'That number looks too short.' : null;
  }

  // ── Photo ───────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: YaadainTheme.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => FamilyTheme(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EnText('Add photo', size: 22, weight: FontWeight.w600, display: true),
              const SizedBox(height: 16),
              FbSmallButton('Take a photo', icon: YI.camera, height: 52, onTap: () => Navigator.pop(ctx, ImageSource.camera)),
              const SizedBox(height: 10),
              FbSmallButton('Choose from gallery', icon: YI.image, height: 52, onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
              if (_photo != null) ...[
                const SizedBox(height: 10),
                FbSmallButton('Remove photo', height: 52, onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photo = null);
                }),
              ],
            ],
          ),
        ),
      ),
    );
    if (src == null) return;
    try {
      final f = await ImagePicker().pickImage(source: src, maxWidth: 1280, imageQuality: 85);
      if (f != null && mounted) setState(() => _photo = f.path);
    } catch (_) {
      if (mounted) fbSnack(context, 'The photo could not be added. You can save without it.');
    }
  }

  // ── Hello recording ─────────────────────────────────────────────────

  Future<void> _record() async {
    _greeting = null;
    _rec.reset();
    await _rec.start();
    if (_rec.error != null && mounted) fbSnack(context, _rec.error!);
  }

  Future<void> _playHello() async {
    try {
      await _rec.togglePlay(_rec.path ?? _greeting);
    } catch (_) {
      if (mounted) fbSnack(context, 'That recording could not be played.');
    }
  }

  // ── Save ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_name.text.trim().isEmpty || _relId == null || _phoneErr != null) return;
    if (_rec.recording) await _rec.stop();
    if (!mounted) return;
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _saving = true);
    try {
      final photo = await app.storeMedia(_photo) ?? _photo;
      final audio = _rec.path != null ? (await app.storeMedia(_rec.path) ?? _rec.path) : _greeting;
      final m = _existing ??
          FamilyMember(id: app.newId(), relationshipId: _relId!);
      m.nameEn = _name.text.trim();
      final nu = _nameUr.text.trim();
      // The Urdu name is shown on elder screens: Urdu letters only.
      m.nameUr = hasLatinLetters(nu) ? '' : nu;
      m.relationshipId = _relId!;
      m.kinshipEnOverride = '';
      m.kinshipUrOverride = '';
      m.photoPath = photo;
      m.greetingAudioPath = audio;
      m.isDeceased = _deceased;
      final ph = _phone.text.trim();
      m.phone = ph.isEmpty ? null : ph;
      _applyCalls(_callsThem.text.trim(), _initThem, m, them: true);
      _applyCalls(_callsHim.text.trim(), _initHim, m, them: false);
      await app.upsertMember(m);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(
        content: EnText(_existing == null ? '${m.nameEn} was added.' : 'Saved.', size: 14, weight: FontWeight.w700, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        backgroundColor: YaadainTheme.ink,
      ));
      if (nav.canPop()) nav.pop(m.id);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        fbSnack(context, 'Could not save. Please try again.');
      }
    }
  }

  void _applyCalls(String text, String initial, FamilyMember m, {required bool them}) {
    if (text == initial) return;
    final ur = hasUrduScript(text) ? text : '';
    final en = hasUrduScript(text) ? '' : text;
    if (them) {
      m.callsThemUr = ur;
      m.callsThemEn = en;
    } else {
      m.callsHimUr = ur;
      m.callsHimEn = en;
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final elder = app.elderNameEn;
    final edit = _existing != null;
    return FamilyScaffold(
      title: edit ? 'Edit relative' : 'Add relative',
      bottom: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FbBigButton('Save', onTap: _saving ? null : _save, busy: _saving),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _photoBlock(),
          const SizedBox(height: 20),
          FbField(label: 'Name', controller: _name, error: _nameErr, onChanged: (_) => setState(() {})),
          const SizedBox(height: 20),
          FbField(
            label: 'Name in Urdu letters',
            controller: _nameUr,
            helper: 'Type it as he reads it. Leave empty to show the name above.',
            capitalization: TextCapitalization.none,
          ),
          const SizedBox(height: 20),
          _relation(elder),
          const SizedBox(height: 20),
          _calls(elder),
          const SizedBox(height: 16),
          _passedAway(),
          const SizedBox(height: 20),
          FbField(
            label: 'Phone (optional)',
            controller: _phone,
            keyboardType: TextInputType.phone,
            capitalization: TextCapitalization.none,
            error: _phoneErr,
            helper: 'Lets him call ${_female ? 'her' : (_male ? 'him' : 'them')} from $_her page.',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          _helloCard(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _photoBlock() {
    final hasPhoto = _photo != null && _photo!.isNotEmpty;
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Add photo',
          child: GestureDetector(
            onTap: _pickPhoto,
            child: SizedBox(
              width: 96,
              height: 96,
              child: hasPhoto
                  ? Avatar(monogram: _name.text.trim().isEmpty ? '?' : _name.text.trim()[0].toUpperCase(), size: 96, photoPath: _photo)
                  : CustomPaint(
                      painter: FbDashedCircle(),
                      child: const Center(child: YIcon(YI.camera, size: 30, color: YaadainTheme.muted)),
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: _pickPhoto,
            child: EnText(hasPhoto ? 'Change photo' : 'Add photo', size: 15, weight: FontWeight.w800, color: YaadainTheme.primary),
          ),
        ),
      ],
    );
  }

  String _phrase() {
    final r = _rel;
    if (r == null) return '';
    final e = r.english;
    final mt = RegExp(r"^(.*) \((.*)'s side\)$").firstMatch(e);
    if (mt != null) return "a ${mt.group(2)}'s ${mt.group(1)!.toLowerCase()}";
    final l = e.toLowerCase();
    return 'a${'aeiou'.contains(l[0]) ? 'n' : ''} $l';
  }

  Widget _relation(String elder) {
    final r = _rel;
    final group = _groups[_group];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FbLabel('Relation to $elder'),
        Semantics(
          button: true,
          label: 'Relation to $elder',
          child: InkWell(
            borderRadius: YaadainTheme.radius12,
            onTap: () => setState(() => _open = !_open),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: YaadainTheme.surface,
                borderRadius: YaadainTheme.radius12,
                border: Border.all(
                    color: _relErr != null ? YaadainTheme.accentDark : (_open || r != null ? YaadainTheme.primary : YaadainTheme.line),
                    width: _open ? 1.5 : 1),
              ),
              child: Row(children: [
                Expanded(
                  child: EnText(r?.english ?? 'Choose a relation',
                      size: 16,
                      weight: FontWeight.w700,
                      color: r == null ? YaadainTheme.sepia : YaadainTheme.ink,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                RotatedBox(quarterTurns: _open ? 2 : 0, child: const YIcon(YI.chevronDown, size: 20, color: YaadainTheme.primaryDark)),
              ]),
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: YaadainTheme.surface,
              borderRadius: YaadainTheme.radius12,
              border: Border.all(color: YaadainTheme.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      stops: [0, .9, 1],
                    ).createShader(b),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemCount: _groups.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final on = i == _group;
                        return Semantics(
                          button: true,
                          selected: on,
                          label: _groups[i].name,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _group = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: on ? YaadainTheme.primarySoft : const Color(0xFFEFE8DA),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: EnText(_groups[i].name,
                                  size: 12,
                                  weight: FontWeight.w800,
                                  color: on ? YaadainTheme.primaryDark : YaadainTheme.bodyDim,
                                  height: 1.0),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: YaadainTheme.line),
                for (final id in group.ids) _option(id),
              ],
            ),
          ),
        ],
        if (_relErr != null) FbHelper(_relErr!, error: true)
        else if (r != null) FbHelper('He will hear the exact Urdu word for ${_phrase()}, in $_her own voice.'),
      ],
    );
  }

  Widget _option(String id) {
    final r = relationshipById(id);
    if (r == null) return const SizedBox.shrink();
    final on = id == _relId;
    return Semantics(
      button: true,
      selected: on,
      label: r.english,
      child: InkWell(
        onTap: () => setState(() {
          _relId = id;
          _open = false;
        }),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: on ? YaadainTheme.primarySoft : null,
          child: Row(children: [
            Expanded(
              child: EnText(r.english,
                  size: 16,
                  weight: on ? FontWeight.w800 : FontWeight.w600,
                  color: on ? YaadainTheme.primaryDark : YaadainTheme.ink,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (on) const YIcon(YI.check, size: 20, color: YaadainTheme.primaryDark),
          ]),
        ),
      ),
    );
  }

  Widget _calls(String elder) {
    final String l1, l2;
    if (_female) {
      l1 = 'What he calls her';
      l2 = 'What she calls him';
    } else if (_male) {
      l1 = 'What $elder calls him';
      l2 = 'What he calls $elder';
    } else {
      l1 = 'What he calls them';
      l2 = 'What they call him';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: FbField(label: l1, controller: _callsThem)),
            const SizedBox(width: 12),
            Expanded(child: FbField(label: l2, controller: _callsHim)),
          ],
        ),
        FbHelper('Both appear under $_her face on his phone.'),
      ],
    );
  }

  Widget _passedAway() {
    return Semantics(
      toggled: _deceased,
      label: 'Has passed away',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _deceased = !_deceased),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: YaadainTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: YaadainTheme.line),
          ),
          child: Row(children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EnText('Has passed away', size: 15, weight: FontWeight.w800),
                  SizedBox(height: 2),
                  EnText('Shown with a memorial ring, never in prompts',
                      size: 13, weight: FontWeight.w600, color: YaadainTheme.muted, height: 1.3),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Toggle(on: _deceased),
          ]),
        ),
      ),
    );
  }

  Widget _helloCard() {
    final recording = _rec.recording;
    final has = _rec.path != null && !recording;
    final existing = !has && !recording && _greeting != null;
    final done = has || existing;
    final label = recording
        ? 'Recording · ${fbClock(_rec.seconds)}'
        : has
            ? 'Recorded · ${fbClock(_rec.seconds)}'
            : existing
                ? 'Recorded'
                : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: YaadainTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YaadainTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EnText('Record a 10-second hello', size: 16, weight: FontWeight.w800, height: 1.3),
                    const SizedBox(height: 2),
                    EnText('${_her[0].toUpperCase()}${_her.substring(1)} voice plays when he taps $_her face',
                        size: 13, weight: FontWeight.w600, color: YaadainTheme.muted, height: 1.3),
                  ],
                ),
              ),
              if (label != null) ...[
                const SizedBox(width: 8),
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: recording ? YaadainTheme.attentionSoft : YaadainTheme.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (!recording) ...[const YIcon(YI.check, size: 14, color: YaadainTheme.primaryDark, strokeWidth: 2.6), const SizedBox(width: 5)],
                    EnText(label,
                        size: 12,
                        weight: FontWeight.w800,
                        color: recording ? YaadainTheme.accentDark : YaadainTheme.primaryDark,
                        height: 1.0),
                  ]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          FbWaveform(
            seed: (_rec.path ?? _greeting ?? 'x').hashCode,
            height: 40,
            flat: !done && !recording,
            color: done || recording ? YaadainTheme.primary : YaadainTheme.line,
            tick: recording ? _rec.seconds : 0,
          ),
          const SizedBox(height: 14),
          if (recording)
            FbSmallButton('Stop', icon: YI.pause, height: 48, filled: true, onTap: _rec.stop)
          else if (!done)
            FbSmallButton('Record hello', icon: YI.mic, height: 48, filled: true, onTap: _record)
          else
            Row(children: [
              Expanded(
                child: FbSmallButton(_rec.playing ? 'Stop' : 'Play',
                    icon: _rec.playing ? YI.pause : YI.play, height: 48, tonal: true, onTap: _playHello),
              ),
              const SizedBox(width: 10),
              Expanded(child: FbSmallButton('Re-record', icon: YI.refresh, height: 48, onTap: _record)),
            ]),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool on;
  const _Toggle({required this.on});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 48,
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? YaadainTheme.primary : const Color(0xFFD9D0BE),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
            BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
          ]),
        ),
      ),
    );
  }
}
