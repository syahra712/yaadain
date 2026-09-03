/// Minimal 2-script string layer. Elder-facing screens pick Urdu script or
/// Roman-Urdu based on the elder's preference; a full ARB/l10n setup is
/// deliberately deferred — this keeps the demo readable and hackable.
class S {
  final bool roman;
  const S(this.roman);

  String get appName => roman ? 'Yaadain' : 'یادیں';
  String get tagline => roman
      ? 'Aap ka khandan, hamesha aap ke saath'
      : 'آپ کا خاندان، ہمیشہ آپ کے ساتھ';

  String get myFamily => roman ? 'Mera Khandan' : 'میرا خاندان';
  String get whoIsThis => roman ? 'Yeh kaun hai?' : 'یہ کون ہے؟';
  String get imSafe => roman ? 'Main theek hoon' : 'میں ٹھیک ہوں';
  String get playVoice => roman ? 'Awaaz suniye' : 'آواز سنیے';
  String get theirStories => roman ? 'Un ki baatein' : 'اُن کی باتیں';

  String yourRel(String relEnglishGloss, String relTerm) =>
      roman ? 'Aap ke/ki $relTerm' : 'آپ کے/کی $relTerm';

  // Caregiver side stays English for the setup flow (built for family, not elder).
  static const caregiver = 'Family setup';
  static const addMember = 'Add a family member';
  static const recordGreeting = 'Record their greeting';
  static const safeZone = 'Safe zone';
  static const ifFoundCard = '“If found” card';
}
