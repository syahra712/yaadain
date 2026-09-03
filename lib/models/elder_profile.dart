/// The elder Yaadain belongs to. Kept deliberately small.
///
/// The safe-zone fields power the geofence safety layer. There is NO
/// continuous location history stored — only a home point and a radius, so
/// the app can tell "inside" from "outside" without ever watching the elder.
class ElderProfile {
  String name;
  String? romanName;
  String? photoPath;

  // Safe zone (optional). Event-based only: we compare current position to
  // this circle to decide if the elder has left. We never log a track.
  double? homeLat;
  double? homeLng;
  double safeRadiusMeters;
  // Human-readable address, shown on the "if found" card (GPS coordinates
  // alone mean nothing to a stranger who finds the elder).
  String? homeAddress;

  // Preferred script for the elder's own screens.
  bool preferRomanScript;

  // Reactive core: a REAL recorded calming clip played when confusion is
  // detected, and which family member's face to show with it.
  String? reassuranceAudioPath;
  String? reassuranceMemberId;

  // Whether always-listening reactive mode is on (elder device).
  bool listeningEnabled;

  ElderProfile({
    this.name = '',
    this.romanName,
    this.photoPath,
    this.homeLat,
    this.homeLng,
    this.safeRadiusMeters = 300,
    this.homeAddress,
    this.preferRomanScript = false,
    this.reassuranceAudioPath,
    this.reassuranceMemberId,
    this.listeningEnabled = false,
  });

  bool get hasSafeZone => homeLat != null && homeLng != null;

  Map<String, dynamic> toJson() => {
        'name': name,
        'romanName': romanName,
        'photoPath': photoPath,
        'homeLat': homeLat,
        'homeLng': homeLng,
        'safeRadiusMeters': safeRadiusMeters,
        'homeAddress': homeAddress,
        'preferRomanScript': preferRomanScript,
        'reassuranceAudioPath': reassuranceAudioPath,
        'reassuranceMemberId': reassuranceMemberId,
        'listeningEnabled': listeningEnabled,
      };

  factory ElderProfile.fromJson(Map<String, dynamic> j) => ElderProfile(
        name: (j['name'] ?? '') as String,
        romanName: j['romanName'] as String?,
        photoPath: j['photoPath'] as String?,
        homeLat: (j['homeLat'] as num?)?.toDouble(),
        homeLng: (j['homeLng'] as num?)?.toDouble(),
        safeRadiusMeters: ((j['safeRadiusMeters'] ?? 300) as num).toDouble(),
        homeAddress: j['homeAddress'] as String?,
        preferRomanScript: (j['preferRomanScript'] ?? false) as bool,
        reassuranceAudioPath: j['reassuranceAudioPath'] as String?,
        reassuranceMemberId: j['reassuranceMemberId'] as String?,
        listeningEnabled: (j['listeningEnabled'] ?? false) as bool,
      );
}
