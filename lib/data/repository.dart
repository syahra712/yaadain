import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/care.dart';
import '../models/elder_profile.dart';
import '../models/episode_log.dart';
import '../models/family_member.dart';

/// Offline-first store. Everything lives in the app's private documents dir:
///   - data.json           : the whole family + elder profile
///   - media/<uuid>.<ext>   : photos and audio, copied in on capture
///
/// No network, no account, no cloud. Vulnerable family data never leaves the
/// device. This is a deliberate design + privacy choice, not a limitation.
class Repository {
  Repository._();

  /// A fresh, independent store (tests / harness). Use with `init(memory: true)`.
  Repository.create();
  static final Repository instance = Repository._();

  static const _uuid = Uuid();

  Directory? _root;
  Directory? _mediaDir;
  File? _dataFile;
  bool _ready = false;

  /// True when there is no disk (tests): load/save/media are no-ops.
  bool inMemory = false;

  Directory get _media => _mediaDir!;

  ElderProfile elder = ElderProfile();
  List<FamilyMember> members = [];
  AppSettings settings = AppSettings();
  List<Episode> episodes = [];
  CareData care = CareData();

  /// [root] overrides the documents dir (tests). Pass [memory] for a store
  /// that never touches disk.
  Future<void> init({Directory? root, bool memory = false}) async {
    if (_ready) return;
    if (memory) {
      inMemory = true;
      _ready = true;
      return;
    }
    try {
      _root = root ?? await getApplicationDocumentsDirectory();
      _mediaDir = Directory('${_root!.path}/media');
      if (!_mediaDir!.existsSync()) _mediaDir!.createSync(recursive: true);
      _dataFile = File('${_root!.path}/data.json');
      await _load();
    } catch (_) {
      inMemory = true; // never block the app on storage trouble
    }
    _ready = true;
  }

  /// Synchronous in-memory init (tests / harness): no disk, save is a no-op.
  void initMemory() {
    inMemory = true;
    _ready = true;
  }

  /// Wipes everything (and the file) back to an empty install.
  Future<void> wipe() async {
    elder = ElderProfile();
    members = [];
    settings = AppSettings();
    episodes = [];
    care = CareData();
    await save();
  }

  Future<void> _load() async {
    final f = _dataFile;
    if (f == null || !f.existsSync()) return;
    try {
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      elder = ElderProfile.fromJson((j['elder'] ?? {}) as Map<String, dynamic>);
      members = ((j['members'] ?? []) as List)
          .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
          .toList();
      settings = AppSettings.fromJson((j['settings'] ?? {}) as Map<String, dynamic>);
      episodes = ((j['episodes'] ?? []) as List)
          .map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList();
      care = CareData.fromJson((j['care'] ?? {}) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt file: start clean rather than crash on a vulnerable user.
      elder = ElderProfile();
      members = [];
      settings = AppSettings();
      episodes = [];
      care = CareData();
    }
  }

  Future<void> save() async {
    final j = {
      'elder': elder.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'settings': settings.toJson(),
      'episodes': episodes.map((e) => e.toJson()).toList(),
      'care': care.toJson(),
    };
    final f = _dataFile;
    if (inMemory || f == null) return;
    try {
      await f.writeAsString(jsonEncode(j));
    } catch (_) {/* disk full / unavailable: keep running */}
  }

  String newId() => _uuid.v4();

  /// Copies a captured file (photo/audio) into private media storage and
  /// returns the stored path. Keeps the original extension.
  Future<String> importMedia(String sourcePath) async {
    if (inMemory) return sourcePath;
    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'dat';
    final dest = '${_media.path}/${_uuid.v4()}.$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// Returns [path] unchanged if it already lives in permanent media storage,
  /// otherwise copies it in and returns the new permanent path. Lets screens
  /// hand us temp capture paths without worrying about where they came from.
  Future<String?> ensureStored(String? path) async {
    if (path == null) return null;
    if (inMemory) return path;
    if (path.startsWith(_media.path)) return path;
    if (!File(path).existsSync()) return null;
    return importMedia(path);
  }

  /// Local path a cloud media id maps to (named by id so it's cached/reused).
  String mediaPathForId(String id, String ext) => '${inMemory ? Directory.systemTemp.path : _media.path}/cloud_$id.$ext';

  bool mediaExistsForId(String id, String ext) =>
      File(mediaPathForId(id, ext)).existsSync();

  /// Writes downloaded bytes to the local media dir under a cloud id, returning
  /// the local path. Reuses the file if already present.
  Future<String> writeMediaBytes(String id, List<int> bytes, String ext) async {
    final path = mediaPathForId(id, ext);
    final f = File(path);
    if (!f.existsSync()) await f.writeAsBytes(bytes, flush: true);
    return path;
  }

  /// Best-effort delete of a media file we own.
  Future<void> deleteMedia(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (!inMemory && f.existsSync() && path.startsWith(_media.path)) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }

  FamilyMember? memberById(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> upsertMember(FamilyMember m) async {
    final i = members.indexWhere((e) => e.id == m.id);
    if (i >= 0) {
      members[i] = m;
    } else {
      members.add(m);
    }
    await save();
  }

  Future<void> removeMember(String id) async {
    members.removeWhere((e) => e.id == id);
    await save();
  }

  /// Contacts usable for the "if found" card and safe-zone alerts:
  /// living relatives with a phone number.
  List<FamilyMember> emergencyContacts() =>
      members.where((m) => !m.isDeceased && (m.phone?.trim().isNotEmpty ?? false)).toList();
}
