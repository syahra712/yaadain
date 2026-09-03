import 'package:flutter_test/flutter_test.dart';

import 'package:yaadain/nlp/urdu_match.dart';

void main() {
  group('UrduMatch script-tolerant skeletons', () {
    test('Roman spelling variants collapse to the same skeleton', () {
      expect(UrduMatch.romanSkeleton('shaadi'), UrduMatch.romanSkeleton('shadi'));
    });

    test('Urdu script and Roman-Urdu match for "shaadi"', () {
      final sim = UrduMatch.similarity('شادی', 'shaadi');
      expect(sim, greaterThan(0.7));
    });

    test('"gaon" matches گاؤں (village)', () {
      expect(UrduMatch.similarity('gaon', 'گاؤں'), greaterThan(0.7));
    });

    test('Unrelated words score low', () {
      expect(UrduMatch.similarity('shaadi', 'karachi'), lessThan(0.7));
    });
  });
}
