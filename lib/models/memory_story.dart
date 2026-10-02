/// A single reminiscence item tied to a family member: a short recorded
/// story or voice note, optionally with its own photo. This is the
/// reminiscence-therapy pillar — real recorded audio, never synthesised.
class MemoryStory {
  final String id;
  String title; // e.g. "Eid at the village, 1985"
  String? audioPath; // path to a real recording in the app's media dir
  String? photoPath; // optional photo that anchors this memory

  /// Flashback triggers: words/names/places that should surface this memory.
  /// Entered by family in any script (Urdu or Roman-Urdu); matching is done
  /// script- and spelling-tolerant. Retrieval only — never generative.
  List<String> triggers;

  MemoryStory({
    required this.id,
    required this.title,
    this.audioPath,
    this.photoPath,
    List<String>? triggers,
  }) : triggers = triggers ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'audioPath': audioPath,
        'photoPath': photoPath,
        'triggers': triggers,
      };

  factory MemoryStory.fromJson(Map<String, dynamic> j) => MemoryStory(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        audioPath: j['audioPath'] as String?,
        photoPath: j['photoPath'] as String?,
        triggers:
            ((j['triggers'] ?? []) as List).map((e) => e.toString()).toList(),
      );
}
