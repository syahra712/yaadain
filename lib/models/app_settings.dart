/// Device-level settings: which role this install plays, and the family it is
/// linked to. Persisted locally alongside the family data.
enum DeviceRole { unset, elder, family }

class AppSettings {
  DeviceRole role;

  /// The shared 6-character family code. The elder device generates it; family
  /// devices enter it to join. This is the linking key for cloud sync.
  String? familyCode;

  /// Display name of the family member contributing from THIS device (family
  /// role only), so their uploads are attributed.
  String? contributorName;

  /// Google account email this device signed in with (family role only), if
  /// they chose "Sign in with Google" instead of just typing a name.
  String? signedInEmail;

  /// Elder device only: Google emails allowed to join this family by code.
  /// Empty = anyone with the code can join (today's default, unrestricted).
  List<String> authorizedEmails;

  AppSettings({
    this.role = DeviceRole.unset,
    this.familyCode,
    this.contributorName,
    this.signedInEmail,
    List<String>? authorizedEmails,
  }) : authorizedEmails = authorizedEmails ?? [];

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'familyCode': familyCode,
        'contributorName': contributorName,
        'signedInEmail': signedInEmail,
        'authorizedEmails': authorizedEmails,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        role: DeviceRole.values.firstWhere(
          (r) => r.name == j['role'],
          orElse: () => DeviceRole.unset,
        ),
        familyCode: j['familyCode'] as String?,
        contributorName: j['contributorName'] as String?,
        signedInEmail: j['signedInEmail'] as String?,
        authorizedEmails: ((j['authorizedEmails'] ?? []) as List).map((e) => e.toString()).toList(),
      );
}
