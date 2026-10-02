import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import 'widgets/onboarding_parts.dart';

/// Step 1 of 3, on the elder's phone, done by the family member holding it.
///
/// The profile only stores the name he is addressed by (Urdu and English),
/// the photo, the home address and centre, and the script. The full legal
/// name and age are kept for this session only.
class ElderPhoneSetupScreen extends StatefulWidget {
  const ElderPhoneSetupScreen({super.key});

  @override
  State<ElderPhoneSetupScreen> createState() => _ElderPhoneSetupScreenState();
}

class _ElderPhoneSetupScreenState extends State<ElderPhoneSetupScreen> {
  static final _arabic = RegExp(r'[؀-ۿ]');

  final _fullName = TextEditingController();
  final _fullNameUr = TextEditingController();
  final _callEn = TextEditingController();
  final _callUr = TextEditingController();
  final _age = TextEditingController();
  final _address = TextEditingController();
  final _addressUr = TextEditingController();
  bool _roman = false;
  String? _photo;
  String? _locNote;
  bool _locBusy = false;

  @override
  void initState() {
    super.initState();
    final e = context.read<AppState>().elder;
    _callEn.text = e.romanName ?? '';
    _callUr.text = _arabic.hasMatch(e.name) ? e.name : '';
    _address.text = e.homeAddress ?? '';
    _addressUr.text = e.homeAddressUr ?? '';
    _roman = e.preferRomanScript;
    _photo = e.photoPath;
  }

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _fullNameUr,
      _callEn,
      _callUr,
      _age,
      _address,
      _addressUr
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _say(String msg) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: EnText(msg, color: Colors.white, weight: FontWeight.w700)));
  }

  Future<void> _pickPhoto() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: YaadainTheme.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => FamilyTheme(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OnbOutlineButton('Take a photo',
                      icon: YI.camera,
                      onTap: () => Navigator.pop(ctx, ImageSource.camera)),
                  const SizedBox(height: 12),
                  OnbOutlineButton('Choose from gallery',
                      icon: YI.image,
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
                ]),
          ),
        ),
      ),
    );
    if (src == null || !mounted) return;
    final app = context.read<AppState>();
    try {
      final f = await ImagePicker()
          .pickImage(source: src, maxWidth: 1280, imageQuality: 85);
      if (f == null) return;
      final stored = await app.storeMedia(f.path);
      if (!mounted) return;
      setState(() => _photo = stored ?? f.path);
    } catch (_) {
      if (mounted)
        _say(
            'Could not open the camera or gallery. You can add a photo later.');
    }
  }

  Future<void> _useLocation() async {
    if (_locBusy) return;
    setState(() {
      _locBusy = true;
      _locNote = null;
    });
    final app = context.read<AppState>();
    try {
      final ok = await Svc.location.ensurePermission();
      final fix = ok ? await Svc.location.current() : null;
      if (!mounted) return;
      if (fix == null) {
        setState(() => _locNote =
            'Could not get this phone’s location. Allow location, or type the address.');
      } else {
        app.elder
          ..homeLat = fix.lat
          ..homeLng = fix.lng;
        final z = app.homeZone;
        if (z != null) {
          z.lat = fix.lat;
          z.lng = fix.lng;
          await app.saveZone(z);
        }
        setState(
            () => _locNote = 'Home centre saved from this phone’s location.');
      }
    } catch (_) {
      if (mounted)
        setState(() => _locNote =
            'Could not get this phone’s location. Allow location, or type the address.');
    }
    if (mounted) setState(() => _locBusy = false);
  }

  Future<void> _continue() async {
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    final e = app.elder;
    final en = _callEn.text.trim();
    final ur = _callUr.text.trim();
    if (en.isNotEmpty) e.romanName = en;
    if (ur.isNotEmpty && _arabic.hasMatch(ur)) e.name = ur;
    final fe = _fullName.text.trim();
    final fu = _fullNameUr.text.trim();
    if (fe.isNotEmpty) e.fullNameEn = fe;
    if (fu.isNotEmpty && _arabic.hasMatch(fu)) e.fullNameUr = fu;
    final age = int.tryParse(_age.text.trim());
    if (age != null && age > 0 && age < 120) e.ageYears = age;
    e.homeAddress = _address.text.trim().isEmpty ? null : _address.text.trim();
    final au = _addressUr.text.trim();
    e.homeAddressUr = (au.isNotEmpty && _arabic.hasMatch(au)) ? au : null;
    e.preferRomanScript = _roman;
    if (_photo != null) e.photoPath = _photo;
    try {
      await app.saveElder();
    } catch (_) {}
    if (!mounted) return;
    nav.pushNamed(Routes.permissions);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return FamilyTheme(
      child: Scaffold(
        backgroundColor: YaadainTheme.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnbStepHeader(
                step: 1, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OnbTitle('Set up his phone',
                        lead:
                            'You are holding the phone he will use. Fill this in for him; he never sees these screens.'),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OnbSilhouette(size: 88, photoPath: _photo),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OnbOutlineButton('Change photo',
                                  icon: YI.camera, onTap: _pickPhoto),
                              const SizedBox(height: 8),
                              const EnText(
                                  'A clear, recent photo. It is also what anyone who finds him will see.',
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: YaadainTheme.bodyDim,
                                  height: 1.4),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const OnbLabel('His name'),
                    OnbField(
                        controller: _fullName,
                        hint: 'Full name',
                        capitalization: TextCapitalization.words,
                        textDirection: TextDirection.ltr,
                        semanticsLabel: 'His name'),
                    const SizedBox(height: 20),
                    const OnbLabel('His name in Urdu letters'),
                    OnbField(
                        controller: _fullNameUr,
                        hint: 'Urdu keyboard opens here',
                        urdu: true,
                        textDirection: TextDirection.rtl,
                        semanticsLabel: 'His name in Urdu letters'),
                    const OnbHelp('Type it as he reads it.'),
                    const SizedBox(height: 20),
                    const OnbLabel('How the app addresses him'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OnbField(
                                    controller: _callEn,
                                    hint: 'Dada Jaan',
                                    capitalization: TextCapitalization.words,
                                    textDirection: TextDirection.ltr,
                                    semanticsLabel:
                                        'What his family calls him'),
                                const OnbHelp('What his family calls him'),
                              ]),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OnbField(
                                    controller: _callUr,
                                    hint: 'Urdu keyboard',
                                    urdu: true,
                                    textDirection: TextDirection.rtl,
                                    semanticsLabel: 'In Urdu letters'),
                                const OnbHelp('In Urdu letters'),
                              ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const OnbLabel('Age'),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 112,
                        child: OnbField(
                            controller: _age,
                            hint: '78',
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            semanticsLabel: 'Age'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const OnbLabel('Home address'),
                    OnbField(
                        controller: _address,
                        hint: 'House, street, area, city',
                        maxLines: 3,
                        height: 72,
                        textDirection: TextDirection.ltr,
                        capitalization: TextCapitalization.words,
                        semanticsLabel: 'Home address'),
                    const SizedBox(height: 12),
                    const OnbLabel('Home address in Urdu letters'),
                    OnbField(
                        controller: _addressUr,
                        hint: 'Shown to anyone who finds him',
                        urdu: true,
                        maxLines: 2,
                        height: 64,
                        textDirection: TextDirection.rtl,
                        semanticsLabel: 'Home address in Urdu letters'),
                    const SizedBox(height: 12),
                    OnbOutlineButton('Use this phone’s location as home',
                        icon: YI.locate, onTap: _useLocation),
                    OnbHelp(_locNote ??
                        'You must be at his home. This sets the centre of his home zone.'),
                    const SizedBox(height: 20),
                    const OnbLabel('Language on his phone'),
                    OnbChoice(
                      title: 'Urdu',
                      body:
                          'Nastaliq script, right to left. Best if he reads Urdu newspapers and books.',
                      selected: !_roman,
                      radioDot: true,
                      onTap: () => setState(() => _roman = false),
                    ),
                    const SizedBox(height: 12),
                    OnbChoice(
                      title: 'Roman Urdu',
                      body:
                          'Urdu words in English letters. Best if he reads text messages this way.',
                      selected: _roman,
                      radioDot: true,
                      onTap: () => setState(() => _roman = true),
                    ),
                    const OnbHelp(
                        'Only you can change this later, from the locked settings on his phone.'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + mq.padding.bottom),
              child: OnbPrimaryButton('Continue', onTap: _continue),
            ),
          ],
        ),
      ),
    );
  }
}
