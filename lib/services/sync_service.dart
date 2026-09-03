import 'dart:math';

import '../data/repository.dart';
import '../models/elder_profile.dart';
import '../models/family_member.dart';

/// The seam between the app and the cloud. The elder device creates a family
/// and mirrors the cloud into the local store; family devices join by code and
/// push their contributions up.
///
/// [LocalSyncService] is a no-network stub so the whole role/join/contribute
/// flow works today. A `FirebaseSyncService` implementing this same interface
/// drops in once the Firebase project is connected — no UI changes needed.
abstract class SyncService {
  /// Whether a real backend is wired (false for the local stub).
  bool get isConnected;

  /// Elder device: provision a new family, returns the shareable join code.
  Future<String> createFamily();

  /// Family device: link this device to an existing family by code.
  /// Returns false if the code is unknown (stub always accepts).
  Future<bool> joinFamily(String code);

  /// Push the elder profile up (elder device).
  Future<void> pushElder(ElderProfile elder);

  /// Family device: one-shot fetch of the elder's display name only (never
  /// their home coordinates — those never leave the elder's device) so
  /// alerts and screens can address them by name.
  Future<Map<String, String?>> fetchElderName();

  /// Push (create/update) a member and its media up (family or elder device).
  Future<void> pushMember(FamilyMember member);

  /// Remove a member everywhere.
  Future<void> deleteMember(String id);

  /// One-shot fetch of the family's members (elder device pulls + caches).
  Future<List<FamilyMember>> fetchMembers();

  /// Realtime stream of the family's members (media downloaded + cached to
  /// local files, so the rest of the app keeps working with file paths). The
  /// local stub emits nothing.
  Stream<List<FamilyMember>> watchMembers();

  /// Elder device: restrict who may join this family by code to a specific
  /// list of Google account emails. An empty list means "anyone with the
  /// code" (today's behaviour, kept as the default).
  Future<void> setAuthorizedEmails(List<String> emails);

  /// The family's current email allow-list, looked up by code (used before
  /// the joining device has a role/family of its own yet).
  Future<List<String>> fetchAuthorizedEmails(String code);

  /// Elder device: record a safe-zone boundary crossing so family devices can
  /// be alerted in (near) real time.
  Future<void> pushSafeZoneAlert({required bool outside, required double distanceMeters});

  /// Family device: the family's latest safe-zone alert, if any
  /// ({outside, distanceMeters, at}). The local stub emits nothing.
  Stream<Map<String, dynamic>?> watchSafeZoneAlert();

  /// Family device: set (or update) the elder's safe zone remotely — a
  /// family member is the one who should define this, not the elder. The
  /// address is only ever the text a person typed; there is no geocoding.
  Future<void> pushSafeZoneConfig({
    required double lat,
    required double lng,
    String? address,
    required double radiusMeters,
  });

  /// Family device: one-shot read of the safe zone currently on file, so a
  /// setup screen can prefill instead of starting blank every time.
  Future<Map<String, dynamic>?> fetchSafeZoneConfig();

  /// Elder device: realtime stream of the safe zone a family member set
  /// remotely ({lat, lng, address, radiusMeters}), null if none yet. The
  /// local stub emits nothing (there's no other device to receive it from).
  Stream<Map<String, dynamic>?> watchSafeZoneConfig();

  /// Generates a friendly 6-char code (no ambiguous chars).
  static String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }
}

/// No-network implementation over the local [Repository]. Data already lives
/// locally, so pushes are no-ops and fetch returns what's on device.
class LocalSyncService implements SyncService {
  final Repository repo;
  LocalSyncService(this.repo);

  @override
  bool get isConnected => false;

  @override
  Future<String> createFamily() async => SyncService.generateCode();

  @override
  Future<bool> joinFamily(String code) async => code.trim().length >= 4;

  @override
  Future<void> pushElder(ElderProfile elder) async {/* local-only stub */}

  @override
  Future<Map<String, String?>> fetchElderName() async =>
      {'name': repo.elder.name, 'romanName': repo.elder.romanName};

  @override
  Future<void> pushMember(FamilyMember member) async {/* local-only stub */}

  @override
  Future<void> deleteMember(String id) async {/* local-only stub */}

  @override
  Future<List<FamilyMember>> fetchMembers() async => List.of(repo.members);

  @override
  Stream<List<FamilyMember>> watchMembers() => const Stream.empty();

  @override
  Future<void> setAuthorizedEmails(List<String> emails) async {
    repo.settings.authorizedEmails = emails;
    await repo.save();
  }

  @override
  Future<List<String>> fetchAuthorizedEmails(String code) async => repo.settings.authorizedEmails;

  @override
  Future<void> pushSafeZoneAlert({required bool outside, required double distanceMeters}) async {
    /* offline: nothing to notify — no other device to reach */
  }

  @override
  Stream<Map<String, dynamic>?> watchSafeZoneAlert() => const Stream.empty();

  @override
  Future<void> pushSafeZoneConfig({
    required double lat,
    required double lng,
    String? address,
    required double radiusMeters,
  }) async {/* local-only stub */}

  @override
  Future<Map<String, dynamic>?> fetchSafeZoneConfig() async => null;

  @override
  Stream<Map<String, dynamic>?> watchSafeZoneConfig() => const Stream.empty();
}
