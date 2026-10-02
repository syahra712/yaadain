import '../theme.dart';
import 'kinship.dart';
import 'memory_story.dart';
import 'relationship.dart';

final RegExp _arabicScript = RegExp(r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');

bool hasUrduScript(String? s) => s != null && _arabicScript.hasMatch(s);

final RegExp _latinLetters = RegExp(r'[A-Za-z]');

/// True when [s] contains Latin letters (never allowed on an Urdu screen).
bool hasLatinLetters(String? s) => s != null && _latinLetters.hasMatch(s);

/// A relative, as the elder relates to them.
///
/// Two-script names: [nameUr] shows on Urdu (elder) screens, [nameEn] on
/// English (family) screens. Never mix them on one screen.
///
/// [greetingAudioPath] is the person's own voice saying who they are to the
/// elder — the core "simulated presence" moment. It is a REAL recording made
/// by that person; Yaadain never synthesises a voice.
class FamilyMember {
  final String id;

  /// Urdu-script name, e.g. "بلال". May be empty (then screens show [kinshipUrdu]).
  String nameUr;

  /// English / Latin name, e.g. "Bilal".
  String nameEn;

  /// Key into kRelationships, from the ELDER's point of view.
  String relationshipId;

  /// Explicit kinship strings; when empty the getters derive them from
  /// [relationshipId] (urdu-rules §7).
  String kinshipUrOverride; // "آپ کا بیٹا"
  String kinshipEnOverride; // "Son"

  /// What the elder calls them ("بلال بیٹا") / what they call him ("ابو").
  String callsThemUr;
  String callsThemEn;
  String callsHimUr;
  String callsHimEn;

  String? photoPath;
  String? greetingAudioPath;
  String? phone;
  bool isDeceased;

  /// Avatar tint name: teal | clay | gold | sage | plum ('' = derived).
  String tint;

  /// The person to call first (the caregiver).
  bool isPrimaryContact;

  /// Free note shown on Add-relative (e.g. "Lives in Lahore").
  String note;

  List<MemoryStory> stories;

  FamilyMember({
    required this.id,
    // Legacy single-name parameters (kept so older call sites and the cloud
    // sync keep compiling): `name` may be Urdu or Latin script.
    String? name,
    String? romanName,
    String? nameUr,
    String? nameEn,
    required this.relationshipId,
    String? kinshipUr,
    String? kinshipEn,
    this.callsThemUr = '',
    this.callsThemEn = '',
    this.callsHimUr = '',
    this.callsHimEn = '',
    this.photoPath,
    this.greetingAudioPath,
    this.phone,
    this.isDeceased = false,
    this.tint = '',
    this.isPrimaryContact = false,
    this.note = '',
    List<MemoryStory>? stories,
  })  : nameUr = nameUr ?? (hasUrduScript(name) ? name! : ''),
        nameEn = nameEn ??
            ((romanName ?? '').isNotEmpty
                ? romanName!
                : (name != null && !hasUrduScript(name) ? name : '')),
        kinshipUrOverride = kinshipUr ?? '',
        kinshipEnOverride = kinshipEn ?? '',
        stories = stories ?? [];

  // ── Legacy accessors (cloud sync + older code) ─────────────────────────
  String get name => nameUr.isNotEmpty ? nameUr : nameEn;
  set name(String v) {
    if (hasUrduScript(v)) {
      nameUr = v;
    } else {
      nameEn = v;
    }
  }

  String? get romanName => nameEn.isEmpty ? null : nameEn;
  set romanName(String? v) => nameEn = v ?? '';

  // ── Display helpers ────────────────────────────────────────────────────

  /// "آپ کا بیٹا" — Urdu kinship with gender agreement.
  String get kinshipUrdu => kinshipUrOverride.isNotEmpty
      ? kinshipUrOverride
      : Kinship.urdu(relationshipId, deceased: isDeceased);

  /// "Son" / "Late wife".
  String get kinshipEnglish => kinshipEnOverride.isNotEmpty
      ? kinshipEnOverride
      : Kinship.english(relationshipId, deceased: isDeceased);

  /// Name for an Urdu screen: the Urdu name, else the Urdu kinship term
  /// ("آپ کی پوتی"). NEVER falls back to Latin.
  String get displayUr =>
      nameUr.isNotEmpty && !hasLatinLetters(nameUr) ? nameUr : kinshipUrdu;

  /// Name for an English screen: the English name, else the English kinship.
  String get displayEn => nameEn.isNotEmpty ? nameEn : kinshipEnglish;

  Relationship? get relationship => relationshipById(relationshipId);

  /// First name only ("Bilal" from "Bilal Akram") for compact English labels.
  String get firstNameEn => nameEn.split(' ').first;

  AvatarTint get avatarTint =>
      YaadainTheme.tintByName(tint.isNotEmpty ? tint : _derivedTint());

  String _derivedTint() {
    var h = 0;
    for (final c in id.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return YaadainTheme.tintNames[h % YaadainTheme.tintNames.length];
  }

  bool get hasVoice => greetingAudioPath != null;

  /// Copies the newer non-empty fields of [remote] into this member while
  /// keeping local-only richer data the cloud schema does not carry yet.
  void mergeRemote(FamilyMember remote) {
    if (remote.nameUr.isNotEmpty) nameUr = remote.nameUr;
    if (remote.nameEn.isNotEmpty) nameEn = remote.nameEn;
    relationshipId = remote.relationshipId;
    photoPath = remote.photoPath ?? photoPath;
    greetingAudioPath = remote.greetingAudioPath ?? greetingAudioPath;
    phone = remote.phone ?? phone;
    isDeceased = remote.isDeceased;
    stories = remote.stories;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // Legacy keys stay for cloud sync + downgrade safety.
        'name': name,
        'romanName': romanName,
        'nameUr': nameUr,
        'nameEn': nameEn,
        'relationshipId': relationshipId,
        'kinshipUr': kinshipUrOverride,
        'kinshipEn': kinshipEnOverride,
        'callsThemUr': callsThemUr,
        'callsThemEn': callsThemEn,
        'callsHimUr': callsHimUr,
        'callsHimEn': callsHimEn,
        'photoPath': photoPath,
        'greetingAudioPath': greetingAudioPath,
        'phone': phone,
        'isDeceased': isDeceased,
        'tint': tint,
        'isPrimaryContact': isPrimaryContact,
        'note': note,
        'stories': stories.map((s) => s.toJson()).toList(),
      };

  /// Reads both the new schema and the old single-`name` schema (migration).
  factory FamilyMember.fromJson(Map<String, dynamic> j) {
    final legacyName = (j['name'] ?? '') as String;
    final legacyRoman = j['romanName'] as String?;
    return FamilyMember(
      id: j['id'] as String,
      name: j.containsKey('nameUr') || j.containsKey('nameEn')
          ? null
          : legacyName,
      romanName: j.containsKey('nameUr') || j.containsKey('nameEn')
          ? null
          : legacyRoman,
      nameUr: j['nameUr'] as String?,
      nameEn: j['nameEn'] as String?,
      relationshipId: (j['relationshipId'] ?? 'rishtedaar') as String,
      kinshipUr: j['kinshipUr'] as String?,
      kinshipEn: j['kinshipEn'] as String?,
      callsThemUr: (j['callsThemUr'] ?? '') as String,
      callsThemEn: (j['callsThemEn'] ?? '') as String,
      callsHimUr: (j['callsHimUr'] ?? '') as String,
      callsHimEn: (j['callsHimEn'] ?? '') as String,
      photoPath: j['photoPath'] as String?,
      greetingAudioPath: j['greetingAudioPath'] as String?,
      phone: j['phone'] as String?,
      isDeceased: (j['isDeceased'] ?? false) as bool,
      tint: (j['tint'] ?? '') as String,
      isPrimaryContact: (j['isPrimaryContact'] ?? false) as bool,
      note: (j['note'] ?? '') as String,
      stories: ((j['stories'] ?? []) as List)
          .map((e) => MemoryStory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
