import 'relationship.dart';

/// Elder-POV kinship phrases with correct gender agreement (urdu-rules §7).
/// Urdu: "آپ کا بیٹا", "آپ کی بیٹی", "آپ کے بھائی". English: "Son".
class Kinship {
  Kinship._();

  // relationshipId -> [article, term]; article is کا / کی / کے.
  static const Map<String, List<String>> _ur = {
    'shohar': ['کے', 'شوہر'],
    'biwi': ['کی', 'بیوی'],
    'beta': ['کا', 'بیٹا'],
    'beti': ['کی', 'بیٹی'],
    'bahu': ['کی', 'بہو'],
    'damaad': ['کے', 'داماد'],
    'pota': ['کا', 'پوتا'],
    'poti': ['کی', 'پوتی'],
    'nawasa': ['کا', 'نواسا'],
    'nawasi': ['کی', 'نواسی'],
    'bhai': ['کے', 'بھائی'],
    'behn': ['کی', 'بہن'],
    'walid': ['کے', 'والد'],
    'walida': ['کی', 'والدہ'],
    'chacha': ['کے', 'چچا'],
    'taya': ['کے', 'تایا'],
    'chachi': ['کی', 'چچی'],
    'tai': ['کی', 'تائی'],
    'mamu': ['کے', 'ماموں'],
    'mumani': ['کی', 'ممانی'],
    'khala': ['کی', 'خالہ'],
    'khalu': ['کے', 'خالو'],
    'phupho': ['کی', 'پھوپھو'],
    'phupha': ['کے', 'پھوپھا'],
    'bhateeja': ['کا', 'بھتیجا'],
    'bhateeji': ['کی', 'بھتیجی'],
    'bhanja': ['کا', 'بھانجا'],
    'bhanji': ['کی', 'بھانجی'],
    'bhabhi': ['کی', 'بھابھی'],
    'behnoi': ['کے', 'بہنوئی'],
    'saala': ['کے', 'سالے'],
    'saali': ['کی', 'سالی'],
    'devar': ['کے', 'دیور'],
    'jeth': ['کے', 'جیٹھ'],
    'nand': ['کی', 'نند'],
    'samdhi': ['کے', 'سمدھی'],
    'samdhan': ['کی', 'سمدھن'],
    'dada': ['کے', 'دادا'],
    'dadi': ['کی', 'دادی'],
    'nana': ['کے', 'نانا'],
    'nani': ['کی', 'نانی'],
    'dost': ['کے', 'دوست'],
    'parosi': ['کے', 'پڑوسی'],
    'doctor': ['کے', 'ڈاکٹر'],
    'dekhbhaal': ['کے', 'دیکھ بھال کرنے والے'],
    'rishtedaar': ['کے', 'رشتہ دار'],
  };

  /// "آپ کا بیٹا". Deceased adds مرحوم / مرحومہ ("آپ کی مرحومہ بیوی").
  static String urdu(String? relationshipId, {bool deceased = false}) {
    final e = _ur[relationshipId] ?? const ['کے', 'رشتہ دار'];
    final fem = e[0] == 'کی';
    final prefix = deceased ? (fem ? 'مرحومہ ' : 'مرحوم ') : '';
    return 'آپ ${e[0]} $prefix${e[1]}';
  }

  /// Bare term, "بیٹا".
  static String urduTerm(String? relationshipId) =>
      (_ur[relationshipId] ?? const ['کے', 'رشتہ دار'])[1];

  /// "Son", "Late wife". English is the relative's tie to Dada Jaan.
  static String english(String? relationshipId, {bool deceased = false}) {
    final r = relationshipById(relationshipId);
    final base = r?.english ?? 'Relative';
    if (!deceased) return base;
    return 'Late ${base[0].toLowerCase()}${base.substring(1)}';
  }

  /// Relationship ids offered by the Add-relative picker, closest first.
  static const List<String> pickerOrder = [
    'biwi',
    'shohar',
    'beta',
    'beti',
    'bahu',
    'damaad',
    'pota',
    'poti',
    'nawasa',
    'nawasi',
    'bhai',
    'behn',
    'bhabhi',
    'behnoi',
    'walid',
    'walida',
    'chacha',
    'taya',
    'chachi',
    'tai',
    'mamu',
    'mumani',
    'khala',
    'khalu',
    'phupho',
    'phupha',
    'bhateeja',
    'bhateeji',
    'bhanja',
    'bhanji',
    'saala',
    'saali',
    'devar',
    'jeth',
    'nand',
    'samdhi',
    'samdhan',
    'dada',
    'dadi',
    'nana',
    'nani',
    'dost',
    'parosi',
    'doctor',
    'dekhbhaal',
    'rishtedaar',
  ];
}
