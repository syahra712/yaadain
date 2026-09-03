/// Script-tolerant fuzzy matching for Urdu-script and Roman-Urdu text.
///
/// The problem: family type flashback triggers however they like — "شادی",
/// "shaadi", "shadi", "SHAADI" — and the elder (or caregiver) later asks in
/// yet another spelling. We need all of these to collide.
///
/// Approach: reduce BOTH scripts to a shared **consonant skeleton** (short
/// vowels and script quirks dropped, digraphs folded), then compare skeletons
/// with a normalized edit-distance ratio. Cheap, offline, no model — and a
/// genuinely useful transliteration-normalization primitive for an Urdu NLP
/// track. This is retrieval only; nothing here generates text.
library;

class UrduMatch {
  /// True if [s] contains Arabic-script characters (U+0600–U+06FF, U+0750–U+077F).
  static bool isUrduScript(String s) {
    for (final r in s.runes) {
      if ((r >= 0x0600 && r <= 0x06FF) || (r >= 0x0750 && r <= 0x077F)) return true;
    }
    return false;
  }

  /// Normalize Urdu script: drop diacritics (aeraab), unify letter variants.
  static String normalizeUrdu(String input) {
    final buf = StringBuffer();
    for (final r in input.runes) {
      // Skip harakat / diacritics and tatweel.
      if ((r >= 0x064B && r <= 0x0652) || r == 0x0640 || r == 0x0670) continue;
      buf.writeCharCode(_foldUrduLetter(r));
    }
    return buf.toString();
  }

  static int _foldUrduLetter(int r) {
    switch (r) {
      case 0x0622: // آ
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0671: // ٱ
        return 0x0627; // ا
      case 0x0649: // ﻯ alef maksura
      case 0x06CC: // ی farsi yeh
      case 0x06D2: // ے barree yeh
      case 0x064A: // ي arabic yeh
        return 0x06CC;
      case 0x0629: // ة teh marbuta
      case 0x06C1: // ﮤ heh goal
      case 0x0647: // ه arabic heh
        return 0x06C1;
      case 0x0643: // ك arabic kaf
        return 0x06A9; // ک
      case 0x0624: // ؤ
      case 0x0626: // ئ
        return 0x0621; // ء
      default:
        return r;
    }
  }

  /// Map a normalized Urdu string to a roman consonant skeleton.
  static String urduSkeleton(String input) {
    final n = normalizeUrdu(input);
    final buf = StringBuffer();
    for (final r in n.runes) {
      final c = _urduToConsonant[r];
      if (c != null && c.isNotEmpty) buf.write(c);
    }
    return _collapse(buf.toString());
  }

  /// Map Roman-Urdu (or English) to the same consonant skeleton.
  static String romanSkeleton(String input) {
    var s = input.toLowerCase();
    // Fold common digraphs to a single representative consonant first.
    const digraphs = {
      'sh': 's', 'ch': 'c', 'kh': 'k', 'gh': 'g', 'th': 't',
      'dh': 'd', 'ph': 'f', 'bh': 'b', 'zh': 'z', 'aa': 'a',
      'ee': 'i', 'oo': 'u', 'ai': 'a', 'au': 'o',
    };
    digraphs.forEach((k, v) => s = s.replaceAll(k, v));
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      // Drop short vowels and glides that carry little consonant identity.
      if ('aeiou'.contains(ch)) continue;
      if ('yw'.contains(ch)) continue;
      if ('h'.contains(ch)) continue; // standalone h after digraph folding
      if (RegExp(r'[a-z]').hasMatch(ch)) buf.write(_foldRomanConsonant(ch));
    }
    return _collapse(buf.toString());
  }

  static String _foldRomanConsonant(String c) {
    const fold = {'x': 'k', 'q': 'k', 'v': 'b', 'c': 'c'};
    return fold[c] ?? c;
  }

  /// Skeleton for any string, auto-detecting the script.
  static String skeleton(String input) =>
      isUrduScript(input) ? urduSkeleton(input) : romanSkeleton(input);

  static String _collapse(String s) {
    if (s.isEmpty) return s;
    final buf = StringBuffer();
    String? prev;
    for (final ch in s.split('')) {
      if (ch != prev) buf.write(ch);
      prev = ch;
    }
    return buf.toString();
  }

  /// 0..1 similarity between two words, script-agnostic.
  static double similarity(String a, String b) {
    final sa = skeleton(a);
    final sb = skeleton(b);
    if (sa.isEmpty || sb.isEmpty) return 0;
    if (sa == sb) return 1;
    final d = _levenshtein(sa, sb);
    final maxLen = sa.length > sb.length ? sa.length : sb.length;
    return 1 - d / maxLen;
  }

  static int _levenshtein(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List<int>.generate(n + 1, (i) => i);
    for (var i = 1; i <= m; i++) {
      var prev = dp[0];
      dp[0] = i;
      for (var j = 1; j <= n; j++) {
        final tmp = dp[j];
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[j] = [dp[j] + 1, dp[j - 1] + 1, prev + cost]
            .reduce((x, y) => x < y ? x : y);
        prev = tmp;
      }
    }
    return dp[n];
  }
}

/// Urdu letter -> single roman consonant (short vowels/silent letters -> '').
const Map<int, String> _urduToConsonant = {
  0x0627: '', // ا alif (vowel carrier)
  0x0621: '', // ء hamza
  0x0628: 'b', // ب
  0x067E: 'p', // پ
  0x062A: 't', // ت
  0x0679: 't', // ٹ
  0x062B: 's', // ث
  0x062C: 'j', // ج
  0x0686: 'c', // چ
  0x062D: '', // ح (soft h -> drop)
  0x062E: 'k', // خ (kh)
  0x062F: 'd', // د
  0x0688: 'd', // ڈ
  0x0630: 'z', // ذ
  0x0631: 'r', // ر
  0x0691: 'r', // ڑ
  0x0632: 'z', // ز
  0x0698: 'z', // ژ
  0x0633: 's', // س
  0x0634: 's', // ش (sh)
  0x0635: 's', // ص
  0x0636: 'z', // ض
  0x0637: 't', // ط
  0x0638: 'z', // ظ
  0x0639: '', // ع (drop)
  0x063A: 'g', // غ (gh)
  0x0641: 'f', // ف
  0x0642: 'k', // ق
  0x06A9: 'k', // ک
  0x06AF: 'g', // گ
  0x0644: 'l', // ل
  0x0645: 'm', // م
  0x0646: 'n', // ن
  0x06BA: 'n', // ں noon ghunna
  0x0648: '', // و (vowel/glide -> drop)
  0x06C1: '', // ہ (drop)
  0x06BE: '', // ھ do-chashmi (aspiration -> drop)
  0x06CC: '', // ی (vowel -> drop)
  0x06D2: '', // ے (vowel -> drop)
};
