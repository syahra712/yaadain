import 'package:flutter_test/flutter_test.dart';

import 'package:yaadain/data/confusion_phrases.dart';
import 'package:yaadain/models/family_member.dart';
import 'package:yaadain/models/memory_story.dart';
import 'package:yaadain/models/relationship.dart';
import 'package:yaadain/nlp/flashback_engine.dart';
import 'package:yaadain/nlp/urdu_match.dart';

/// Best matching confusion phrase for a heard utterance (mirrors the detector).
ConfusionPhrase? bestConfusion(String heard, {double threshold = 0.80}) {
  ConfusionPhrase? best;
  double bestSim = 0;
  for (final p in kConfusionPhrases) {
    final s = UrduMatch.similarity(heard, p.text);
    if (s > bestSim) {
      bestSim = s;
      best = p;
    }
  }
  return (best != null && bestSim >= threshold) ? best : null;
}

void main() {
  group('Generation banding (from the elder POV)', () {
    test('children are +1, grandchildren +2, elders -1, peers 0', () {
      expect(generationOfRelationship('beta'), 1);
      expect(generationOfRelationship('beti'), 1);
      expect(generationOfRelationship('pota'), 2);
      expect(generationOfRelationship('nawasi'), 2);
      expect(generationOfRelationship('walid'), -1);
      expect(generationOfRelationship('khala'), -1);
      expect(generationOfRelationship('biwi'), 0);
      expect(generationOfRelationship('bhai'), 0);
      expect(generationOfRelationship(null), 0); // unknown -> peers
    });
  });

  group('Confusion detection matching', () {
    test('a spoken confusion phrase matches its category', () {
      expect(bestConfusion('yeh kaun hai')?.category, 'recognition');
      expect(bestConfusion('main kahan hoon')?.category, 'place');
      expect(bestConfusion('mujhe dar lag raha hai')?.severity, 2);
    });

    test('a regional (Punjabi) variant still matches', () {
      expect(bestConfusion('tusi kaun ho'), isNotNull);
    });

    test('a calm, unrelated sentence does NOT trigger', () {
      expect(bestConfusion('khana taiyar hai'), isNull);
      expect(bestConfusion('mausam accha hai'), isNull);
    });
  });

  group('Flashback retrieval', () {
    FamilyMember withStory(List<String> triggers) => FamilyMember(
          id: 'm1',
          name: 'Fatima',
          relationshipId: 'beti',
          stories: [
            MemoryStory(id: 's1', title: 'Eid', audioPath: '/tmp/fake.m4a', triggers: triggers),
          ],
        );

    test('finds a memory by an Urdu-script query against a Roman trigger', () {
      final hits = FlashbackEngine.search('شادی', [withStory(['shaadi'])]);
      expect(hits, isNotEmpty);
      expect(hits.first.story.title, 'Eid');
    });

    test('finds a memory by the memory title itself', () {
      final hits = FlashbackEngine.search('Eid', [withStory(['gaon'])]);
      expect(hits, isNotEmpty);
    });

    test('unrelated query returns nothing', () {
      final hits = FlashbackEngine.search('cricket', [withStory(['shaadi', 'gaon'])]);
      expect(hits, isEmpty);
    });

    test('a story with no audio is not surfaced', () {
      final m = FamilyMember(
        id: 'm2',
        name: 'Ali',
        relationshipId: 'beta',
        stories: [MemoryStory(id: 's2', title: 'Trip', triggers: ['safar'])],
      );
      expect(FlashbackEngine.search('safar', [m]), isEmpty);
    });
  });
}
