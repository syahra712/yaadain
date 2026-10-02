/// Device-level settings: which role this install plays, and the family it is
/// linked to. Persisted locally alongside the family data.
///
/// Roles: unset | elder | family. A caregiver is `family` + [isCaregiver].
enum DeviceRole { unset, elder, family }

class AppSettings {
  DeviceRole role;

  /// The shared family code (stored without the "YD-" prefix, e.g. "7F3K").
  String? familyCode;

  /// Display name of the family member using THIS device (family role).
  String? contributorName;

  /// Id of the FamilyMember this device's user is (family role), if known.
  String? contributorMemberId;

  String? signedInEmail;

  /// Elder device: Google emails allowed to join (empty = anyone with code).
  List<String> authorizedEmails;

  /// Family role that sets up and runs the elder phone (sees Abu tab, edits).
  bool isCaregiver;

  /// Hijri day correction (-1, 0, +1). Default +1 matches the Karachi
  /// moon-sighting calendar for Oct 2026 (20 Rabi al-Thani on 2 Oct).
  int hijriOffsetDays;

  /// Elder-phone UI language: 'ur' (only fully supported value).
  String elderLanguage;

  /// True once onboarding finished on this device.
  bool onboarded;

  AppSettings({
    this.role = DeviceRole.unset,
    this.familyCode,
    this.contributorName,
    this.contributorMemberId,
    this.signedInEmail,
    List<String>? authorizedEmails,
    this.isCaregiver = false,
    this.hijriOffsetDays = 1,
    this.elderLanguage = 'ur',
    this.onboarded = false,
  }) : authorizedEmails = authorizedEmails ?? [];

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'familyCode': familyCode,
        'contributorName': contributorName,
        'contributorMemberId': contributorMemberId,
        'signedInEmail': signedInEmail,
        'authorizedEmails': authorizedEmails,
        'isCaregiver': isCaregiver,
        'hijriOffsetDays': hijriOffsetDays,
        'elderLanguage': elderLanguage,
        'onboarded': onboarded,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        role: DeviceRole.values.firstWhere((r) => r.name == j['role'],
            orElse: () => DeviceRole.unset),
        familyCode: j['familyCode'] as String?,
        contributorName: j['contributorName'] as String?,
        contributorMemberId: j['contributorMemberId'] as String?,
        signedInEmail: j['signedInEmail'] as String?,
        authorizedEmails: ((j['authorizedEmails'] ?? []) as List)
            .map((e) => e.toString())
            .toList(),
        isCaregiver: (j['isCaregiver'] ?? false) as bool,
        hijriOffsetDays: ((j['hijriOffsetDays'] ?? 1) as num).toInt(),
        elderLanguage: (j['elderLanguage'] ?? 'ur') as String,
        onboarded: (j['onboarded'] ?? false) as bool,
      );
}
