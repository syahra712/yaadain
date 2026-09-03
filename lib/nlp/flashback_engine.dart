import '../models/family_member.dart';
import '../models/memory_story.dart';
import 'urdu_match.dart';

/// One flashback hit: a story, who it belongs to, and why it matched.
class FlashbackHit {
  final FamilyMember member;
  final MemoryStory story;
  final double score;
  final String matchedTrigger;

  FlashbackHit({
    required this.member,
    required this.story,
    required this.score,
    required this.matchedTrigger,
  });
}

/// Retrieval over the curated memory bank. NEVER generates — it can only
/// surface a memory the family already recorded, so it cannot say anything
/// the family did not choose to say. Matching is script-tolerant via
/// [UrduMatch] (Urdu ↔ Roman-Urdu ↔ English).
class FlashbackEngine {
  /// Minimum skeleton similarity to count as a match.
  static const double threshold = 0.72;

  static List<FlashbackHit> search(String query, List<FamilyMember> members) {
    final q = query.trim();
    if (q.isEmpty) return [];
    final tokens = q.split(RegExp(r'[\s,،]+')).where((t) => t.isNotEmpty).toList();

    final hits = <FlashbackHit>[];
    for (final m in members) {
      for (final st in m.stories) {
        if (st.audioPath == null) continue; // only playable memories
        double best = 0;
        String bestTrigger = '';
        // Match query tokens against triggers AND the memory title.
        final haystack = <String>[...st.triggers, st.title];
        for (final tok in tokens) {
          for (final trig in haystack) {
            final s = UrduMatch.similarity(tok, trig);
            if (s > best) {
              best = s;
              bestTrigger = trig;
            }
          }
        }
        if (best >= threshold) {
          hits.add(FlashbackHit(member: m, story: st, score: best, matchedTrigger: bestTrigger));
        }
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits;
  }
}
