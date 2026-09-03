import 'memory_story.dart';

/// A relative, as the elder relates to them.
///
/// [greetingAudioPath] is the person's own voice saying who they are to the
/// elder — the core "simulated presence" moment. It is a REAL recording made
/// by that person; Yaadain never synthesises a voice.
class FamilyMember {
  final String id;
  String name; // shown name (may be Urdu script)
  String? romanName; // optional Roman-Urdu spelling
  String relationshipId; // key into kRelationships, from the ELDER's POV
  String? photoPath;
  String? greetingAudioPath; // "Assalam-o-alaikum Abba, main aapki beti Fatima"
  String? phone; // for the "if found" card + safe-zone alerts
  bool isDeceased; // gates gentle handling; never auto-corrects the elder
  List<MemoryStory> stories;

  FamilyMember({
    required this.id,
    required this.name,
    this.romanName,
    required this.relationshipId,
    this.photoPath,
    this.greetingAudioPath,
    this.phone,
    this.isDeceased = false,
    List<MemoryStory>? stories,
  }) : stories = stories ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'romanName': romanName,
        'relationshipId': relationshipId,
        'photoPath': photoPath,
        'greetingAudioPath': greetingAudioPath,
        'phone': phone,
        'isDeceased': isDeceased,
        'stories': stories.map((s) => s.toJson()).toList(),
      };

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        romanName: j['romanName'] as String?,
        relationshipId: (j['relationshipId'] ?? 'rishtedaar') as String,
        photoPath: j['photoPath'] as String?,
        greetingAudioPath: j['greetingAudioPath'] as String?,
        phone: j['phone'] as String?,
        isDeceased: (j['isDeceased'] ?? false) as bool,
        stories: ((j['stories'] ?? []) as List)
            .map((e) => MemoryStory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
