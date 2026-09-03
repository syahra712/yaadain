import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../data/repository.dart';
import '../models/elder_profile.dart';
import '../models/family_member.dart';
import '../models/memory_story.dart';
import 'sync_service.dart';

/// Cloud sync over Firestore only (no Cloud Storage — stays on the free plan).
/// Each photo/voice file is base64-encoded into a `media` doc; member docs
/// reference it by {id, ext}. On the elder's device, referenced media is
/// downloaded once and cached to local files, so the rest of the app keeps
/// using ordinary file paths.
///
/// Firestore layout:
///   families/{CODE}
///     elder: { name, romanName, photo:{id,ext}? }
///     members/{memberId}: <cloud member>
///     media/{mediaId}: { ext, data(base64) }
class FirebaseSyncService implements SyncService {
  final Repository repo;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  FirebaseSyncService(this.repo);

  @override
  bool get isConnected => true;

  String? get _code => repo.settings.familyCode;
  DocumentReference<Map<String, dynamic>> _family(String code) =>
      _db.collection('families').doc(code);

  @override
  Future<String> createFamily() async {
    // Try a few codes in the unlikely event of a collision.
    for (var i = 0; i < 5; i++) {
      final code = SyncService.generateCode();
      final ref = _family(code);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({'createdAt': FieldValue.serverTimestamp()});
        return code;
      }
    }
    final code = SyncService.generateCode();
    await _family(code).set({'createdAt': FieldValue.serverTimestamp()});
    return code;
  }

  @override
  Future<bool> joinFamily(String code) async {
    final snap = await _family(code.trim().toUpperCase()).get();
    return snap.exists;
  }

  @override
  Future<void> pushElder(ElderProfile elder) async {
    final code = _code;
    if (code == null) return;
    final photo = await _uploadIfNeeded(code, elder.photoPath);
    await _family(code).set({
      'elder': {
        'name': elder.name,
        'romanName': elder.romanName,
        if (photo != null) 'photo': photo.toJson(),
      }
    }, SetOptions(merge: true));
  }

  @override
  Future<Map<String, String?>> fetchElderName() async {
    final code = _code;
    if (code == null) return const {};
    final snap = await _family(code).get();
    final e = snap.data()?['elder'] as Map<String, dynamic>?;
    return {'name': e?['name'] as String?, 'romanName': e?['romanName'] as String?};
  }

  @override
  Future<void> pushMember(FamilyMember m) async {
    final code = _code;
    if (code == null) return;
    final photo = await _uploadIfNeeded(code, m.photoPath);
    final greeting = await _uploadIfNeeded(code, m.greetingAudioPath);
    final stories = <Map<String, dynamic>>[];
    for (final s in m.stories) {
      final audio = await _uploadIfNeeded(code, s.audioPath);
      final sPhoto = await _uploadIfNeeded(code, s.photoPath);
      stories.add({
        'id': s.id,
        'title': s.title,
        'triggers': s.triggers,
        if (audio != null) 'audio': audio.toJson(),
        if (sPhoto != null) 'photo': sPhoto.toJson(),
      });
    }
    await _family(code).collection('members').doc(m.id).set({
      'id': m.id,
      'name': m.name,
      'romanName': m.romanName,
      'relationshipId': m.relationshipId,
      'phone': m.phone,
      'isDeceased': m.isDeceased,
      if (photo != null) 'photo': photo.toJson(),
      if (greeting != null) 'greeting': greeting.toJson(),
      'stories': stories,
      'contributor': repo.settings.contributorName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteMember(String id) async {
    final code = _code;
    if (code == null) return;
    await _family(code).collection('members').doc(id).delete();
  }

  @override
  Future<List<FamilyMember>> fetchMembers() async {
    final code = _code;
    if (code == null) return [];
    final snap = await _family(code).collection('members').get();
    final out = <FamilyMember>[];
    for (final d in snap.docs) {
      out.add(await _fromCloud(code, d.data()));
    }
    return out;
  }

  @override
  Stream<List<FamilyMember>> watchMembers() {
    final code = _code;
    if (code == null) return const Stream.empty();
    return _family(code).collection('members').snapshots().asyncMap((snap) async {
      final out = <FamilyMember>[];
      for (final d in snap.docs) {
        out.add(await _fromCloud(code, d.data()));
      }
      return out;
    });
  }

  @override
  Future<void> setAuthorizedEmails(List<String> emails) async {
    final code = _code;
    if (code == null) return;
    await _family(code).set({
      'authorizedEmails': emails.map((e) => e.trim().toLowerCase()).toList(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<String>> fetchAuthorizedEmails(String code) async {
    final snap = await _family(code.trim().toUpperCase()).get();
    final list = snap.data()?['authorizedEmails'] as List?;
    return list?.map((e) => e.toString()).toList() ?? const [];
  }

  @override
  Future<void> pushSafeZoneAlert({required bool outside, required double distanceMeters}) async {
    final code = _code;
    if (code == null) return;
    await _family(code).set({
      'lastAlert': {
        'outside': outside,
        'distanceMeters': distanceMeters,
        'at': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  @override
  Stream<Map<String, dynamic>?> watchSafeZoneAlert() {
    final code = _code;
    if (code == null) return const Stream.empty();
    return _family(code).snapshots().map((s) => s.data()?['lastAlert'] as Map<String, dynamic>?);
  }

  @override
  Future<void> pushSafeZoneConfig({
    required double lat,
    required double lng,
    String? address,
    required double radiusMeters,
  }) async {
    final code = _code;
    if (code == null) return;
    await _family(code).set({
      'safeZone': {
        'lat': lat,
        'lng': lng,
        'address': address,
        'radiusMeters': radiusMeters,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  @override
  Future<Map<String, dynamic>?> fetchSafeZoneConfig() async {
    final code = _code;
    if (code == null) return null;
    final snap = await _family(code).get();
    return snap.data()?['safeZone'] as Map<String, dynamic>?;
  }

  @override
  Stream<Map<String, dynamic>?> watchSafeZoneConfig() {
    final code = _code;
    if (code == null) return const Stream.empty();
    return _family(code).snapshots().map((s) => s.data()?['safeZone'] as Map<String, dynamic>?);
  }

  // ---- media helpers -------------------------------------------------------

  /// Uploads a local file to a media doc (unless it already came from the
  /// cloud), returning its reference. Skips re-uploading cloud-sourced files.
  Future<_MediaRef?> _uploadIfNeeded(String code, String? path) async {
    if (path == null) return null;
    final existing = _MediaRef.fromLocalPath(path);
    if (existing != null) return existing; // already a cached cloud file
    final file = File(path);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    // Firestore caps a document at ~1 MB; base64 inflates ~1.33x. Skip media
    // that won't fit rather than failing the whole sync. (Photos are already
    // shrunk on capture; only an unusually long recording hits this.)
    if (bytes.length > 700 * 1024) return null;
    final ext = _extOf(path);
    final id = _uuid.v4();
    await _family(code).collection('media').doc(id).set({
      'ext': ext,
      'data': base64Encode(bytes),
    });
    return _MediaRef(id, ext);
  }

  /// Downloads (once) a media reference to a local file and returns its path.
  Future<String?> _downloadIfNeeded(String code, _MediaRef? ref) async {
    if (ref == null) return null;
    if (repo.mediaExistsForId(ref.id, ref.ext)) {
      return repo.mediaPathForId(ref.id, ref.ext);
    }
    final doc = await _family(code).collection('media').doc(ref.id).get();
    final data = doc.data();
    if (data == null || data['data'] == null) return null;
    final bytes = base64Decode(data['data'] as String);
    return repo.writeMediaBytes(ref.id, bytes, ref.ext);
  }

  Future<FamilyMember> _fromCloud(String code, Map<String, dynamic> j) async {
    final photo = await _downloadIfNeeded(code, _MediaRef.fromJson(j['photo']));
    final greeting = await _downloadIfNeeded(code, _MediaRef.fromJson(j['greeting']));
    final stories = <MemoryStory>[];
    for (final s in (j['stories'] as List? ?? const [])) {
      final sm = s as Map<String, dynamic>;
      stories.add(MemoryStory(
        id: sm['id'] as String,
        title: (sm['title'] ?? '') as String,
        triggers: ((sm['triggers'] ?? []) as List).map((e) => e.toString()).toList(),
        audioPath: await _downloadIfNeeded(code, _MediaRef.fromJson(sm['audio'])),
        photoPath: await _downloadIfNeeded(code, _MediaRef.fromJson(sm['photo'])),
      ));
    }
    return FamilyMember(
      id: j['id'] as String,
      name: (j['name'] ?? '') as String,
      romanName: j['romanName'] as String?,
      relationshipId: (j['relationshipId'] ?? 'rishtedaar') as String,
      phone: j['phone'] as String?,
      isDeceased: (j['isDeceased'] ?? false) as bool,
      photoPath: photo,
      greetingAudioPath: greeting,
      stories: stories,
    );
  }

  String _extOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return 'dat';
    return path.substring(dot + 1).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

/// A pointer to a media blob stored in Firestore: its id and file extension.
class _MediaRef {
  final String id;
  final String ext;
  const _MediaRef(this.id, this.ext);

  Map<String, dynamic> toJson() => {'id': id, 'ext': ext};

  static _MediaRef? fromJson(dynamic j) {
    if (j is Map && j['id'] != null) {
      return _MediaRef(j['id'] as String, (j['ext'] ?? 'dat') as String);
    }
    return null;
  }

  /// Recovers a ref from a locally-cached cloud file path (cloud_<id>.<ext>).
  static _MediaRef? fromLocalPath(String path) {
    final name = path.split('/').last;
    if (!name.startsWith('cloud_')) return null;
    final dot = name.lastIndexOf('.');
    if (dot < 0) return null;
    return _MediaRef(name.substring(6, dot), name.substring(dot + 1));
  }
}
