/// Relationships are always expressed FROM THE ELDER'S POINT OF VIEW.
///
/// This is the heart of Yaadain: a Western family tree says
/// "Fatima, daughter of Ahmed". Yaadain says "Fatima — YOUR daughter",
/// in the dense relationship vocabulary of a South Asian joint family.
///
/// Each relationship carries the Urdu-script term, a Roman-Urdu term, and
/// an English gloss, so the same person can be shown in whichever script
/// the elder still reads most comfortably.
library;

enum Gender { male, female }

class Relationship {
  final String id; // stable key, e.g. "beti"
  final String urdu; // اردو
  final String roman; // Roman-Urdu
  final String english; // gloss
  final Gender gender;

  /// Legacy, never rendered (the UI bans emoji). Kept for data compatibility.
  final String emoji;

  const Relationship({
    required this.id,
    required this.urdu,
    required this.roman,
    required this.english,
    required this.gender,
    this.emoji = '',
  });
}

/// A curated set covering the joint-family web. Ordered roughly by closeness
/// to the elder so the picker reads naturally.
const List<Relationship> kRelationships = [
  // Spouse
  Relationship(
      id: 'shohar',
      urdu: 'شوہر',
      roman: 'Shohar',
      english: 'Husband',
      gender: Gender.male),
  Relationship(
      id: 'biwi',
      urdu: 'بیوی',
      roman: 'Biwi',
      english: 'Wife',
      gender: Gender.female),

  // Children
  Relationship(
      id: 'beta',
      urdu: 'بیٹا',
      roman: 'Beta',
      english: 'Son',
      gender: Gender.male),
  Relationship(
      id: 'beti',
      urdu: 'بیٹی',
      roman: 'Beti',
      english: 'Daughter',
      gender: Gender.female),

  // Children-in-law
  Relationship(
      id: 'bahu',
      urdu: 'بہو',
      roman: 'Bahu',
      english: 'Daughter-in-law',
      gender: Gender.female),
  Relationship(
      id: 'damaad',
      urdu: 'داماد',
      roman: 'Damaad',
      english: 'Son-in-law',
      gender: Gender.male),

  // Grandchildren — Urdu distinguishes the son's vs daughter's line
  Relationship(
      id: 'pota',
      urdu: 'پوتا',
      roman: 'Pota',
      english: "Grandson (son's side)",
      gender: Gender.male),
  Relationship(
      id: 'poti',
      urdu: 'پوتی',
      roman: 'Poti',
      english: "Granddaughter (son's side)",
      gender: Gender.female),
  Relationship(
      id: 'nawasa',
      urdu: 'نواسہ',
      roman: 'Nawasa',
      english: "Grandson (daughter's side)",
      gender: Gender.male),
  Relationship(
      id: 'nawasi',
      urdu: 'نواسی',
      roman: 'Nawasi',
      english: "Granddaughter (daughter's side)",
      gender: Gender.female),

  // Siblings
  Relationship(
      id: 'bhai',
      urdu: 'بھائی',
      roman: 'Bhai',
      english: 'Brother',
      gender: Gender.male),
  Relationship(
      id: 'behn',
      urdu: 'بہن',
      roman: 'Behn',
      english: 'Sister',
      gender: Gender.female),

  // Parents (for a younger elder)
  Relationship(
      id: 'walid',
      urdu: 'والد',
      roman: 'Walid',
      english: 'Father',
      gender: Gender.male),
  Relationship(
      id: 'walida',
      urdu: 'والدہ',
      roman: 'Walida',
      english: 'Mother',
      gender: Gender.female),

  // Paternal aunts/uncles
  Relationship(
      id: 'chacha',
      urdu: 'چچا',
      roman: 'Chacha',
      english: "Uncle (father's brother)",
      gender: Gender.male),
  Relationship(
      id: 'phupho',
      urdu: 'پھوپھو',
      roman: 'Phupho',
      english: "Aunt (father's sister)",
      gender: Gender.female),

  // Maternal aunts/uncles
  Relationship(
      id: 'mamu',
      urdu: 'ماموں',
      roman: 'Mamu',
      english: "Uncle (mother's brother)",
      gender: Gender.male),
  Relationship(
      id: 'khala',
      urdu: 'خالہ',
      roman: 'Khala',
      english: "Aunt (mother's sister)",
      gender: Gender.female),

  // In-law siblings + spouses' relations commonly in the home
  Relationship(
      id: 'bhabhi',
      urdu: 'بھابھی',
      roman: 'Bhabhi',
      english: "Sister-in-law (brother's wife)",
      gender: Gender.female),
  Relationship(
      id: 'devar',
      urdu: 'دیور',
      roman: 'Devar',
      english: "Brother-in-law (husband's brother)",
      gender: Gender.male),

  // Carers / others
  Relationship(
      id: 'rishtedaar',
      urdu: 'رشتہ دار',
      roman: 'Rishtedaar',
      english: 'Relative',
      gender: Gender.male),
  Relationship(
      id: 'dekhbhaal',
      urdu: 'دیکھ بھال کرنے والا',
      roman: 'Care-taker',
      english: 'Caregiver',
      gender: Gender.female),
  // More kinship terms (urdu-rules §7)
  Relationship(
      id: 'taya',
      urdu: 'تایا',
      roman: 'Taya',
      english: "Uncle (father's elder brother)",
      gender: Gender.male),
  Relationship(
      id: 'chachi',
      urdu: 'چچی',
      roman: 'Chachi',
      english: "Aunt (uncle's wife)",
      gender: Gender.female),
  Relationship(
      id: 'tai',
      urdu: 'تائی',
      roman: 'Tai',
      english: "Aunt (elder uncle's wife)",
      gender: Gender.female),
  Relationship(
      id: 'mumani',
      urdu: 'ممانی',
      roman: 'Mumani',
      english: "Aunt (maternal uncle's wife)",
      gender: Gender.female),
  Relationship(
      id: 'khalu',
      urdu: 'خالو',
      roman: 'Khalu',
      english: "Uncle (maternal aunt's husband)",
      gender: Gender.male),
  Relationship(
      id: 'phupha',
      urdu: 'پھوپھا',
      roman: 'Phupha',
      english: "Uncle (paternal aunt's husband)",
      gender: Gender.male),
  Relationship(
      id: 'bhateeja',
      urdu: 'بھتیجا',
      roman: 'Bhateeja',
      english: "Nephew (brother's son)",
      gender: Gender.male),
  Relationship(
      id: 'bhateeji',
      urdu: 'بھتیجی',
      roman: 'Bhateeji',
      english: "Niece (brother's daughter)",
      gender: Gender.female),
  Relationship(
      id: 'bhanja',
      urdu: 'بھانجا',
      roman: 'Bhanja',
      english: "Nephew (sister's son)",
      gender: Gender.male),
  Relationship(
      id: 'bhanji',
      urdu: 'بھانجی',
      roman: 'Bhanji',
      english: "Niece (sister's daughter)",
      gender: Gender.female),
  Relationship(
      id: 'behnoi',
      urdu: 'بہنوئی',
      roman: 'Behnoi',
      english: "Brother-in-law (sister's husband)",
      gender: Gender.male),
  Relationship(
      id: 'saala',
      urdu: 'سالا',
      roman: 'Saala',
      english: "Brother-in-law (wife's brother)",
      gender: Gender.male),
  Relationship(
      id: 'saali',
      urdu: 'سالی',
      roman: 'Saali',
      english: "Sister-in-law (wife's sister)",
      gender: Gender.female),
  Relationship(
      id: 'nand',
      urdu: 'نند',
      roman: 'Nand',
      english: "Sister-in-law (husband's sister)",
      gender: Gender.female),
  Relationship(
      id: 'jeth',
      urdu: 'جیٹھ',
      roman: 'Jeth',
      english: "Brother-in-law (husband's elder brother)",
      gender: Gender.male),
  Relationship(
      id: 'samdhi',
      urdu: 'سمدھی',
      roman: 'Samdhi',
      english: "Co-father-in-law",
      gender: Gender.male),
  Relationship(
      id: 'samdhan',
      urdu: 'سمدھن',
      roman: 'Samdhan',
      english: "Co-mother-in-law",
      gender: Gender.female),
  Relationship(
      id: 'dada',
      urdu: 'دادا',
      roman: 'Dada',
      english: 'Grandfather (paternal)',
      gender: Gender.male),
  Relationship(
      id: 'dadi',
      urdu: 'دادی',
      roman: 'Dadi',
      english: 'Grandmother (paternal)',
      gender: Gender.female),
  Relationship(
      id: 'nana',
      urdu: 'نانا',
      roman: 'Nana',
      english: 'Grandfather (maternal)',
      gender: Gender.male),
  Relationship(
      id: 'nani',
      urdu: 'نانی',
      roman: 'Nani',
      english: 'Grandmother (maternal)',
      gender: Gender.female),
  Relationship(
      id: 'dost',
      urdu: 'دوست',
      roman: 'Dost',
      english: 'Friend',
      gender: Gender.male),
  Relationship(
      id: 'parosi',
      urdu: 'پڑوسی',
      roman: 'Parosi',
      english: 'Neighbour',
      gender: Gender.male),
  Relationship(
      id: 'doctor',
      urdu: 'ڈاکٹر',
      roman: 'Doctor',
      english: 'Doctor',
      gender: Gender.male),
];

Relationship? relationshipById(String? id) {
  if (id == null) return null;
  for (final r in kRelationships) {
    if (r.id == id) return r;
  }
  return null;
}

/// Generation of a relationship RELATIVE TO THE ELDER (elder == 0):
///   -1 = elders (parents, aunts, uncles)
///    0 = the elder's own generation (spouse, siblings, in-law siblings)
///   +1 = children (and their spouses)
///   +2 = grandchildren
/// We only know each person's tie to the elder, so this generational banding
/// is the honest structure — no invented parent-child edges between relatives.
int generationOfRelationship(String? relId) {
  const elders = {
    'walid',
    'walida',
    'chacha',
    'phupho',
    'mamu',
    'khala',
    'taya',
    'chachi',
    'tai',
    'mumani',
    'khalu',
    'phupha',
    'dada',
    'dadi',
    'nana',
    'nani',
  };
  const children = {'beta', 'beti', 'bahu', 'damaad'};
  const grandchildren = {'pota', 'poti', 'nawasa', 'nawasi'};
  if (elders.contains(relId)) return -1;
  if (children.contains(relId)) return 1;
  if (grandchildren.contains(relId)) return 2;
  return 0; // spouse, siblings, in-laws, caregivers, generic relatives
}

/// The four generation bands, oldest → youngest, with bilingual titles.
class TreeGeneration {
  final int level;
  final String urdu;
  final String roman;
  const TreeGeneration(this.level, this.urdu, this.roman);
}

const List<TreeGeneration> kGenerations = [
  TreeGeneration(-1, 'آپ کے بزرگ', 'Aap ke buzurg'),
  TreeGeneration(0, 'آپ کے ہم عمر', 'Aap ke ham-umar'),
  TreeGeneration(1, 'آپ کی اولاد', 'Aap ki aulad'),
  TreeGeneration(2, 'آپ کے پوتے پوتیاں اور نواسے نواسیاں',
      'Aap ke pote poti aur nawase nawasi'),
];
