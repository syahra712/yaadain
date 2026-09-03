/// Phrases that signal confusion or distress in an elder's speech.
///
/// Matching is skeleton-based (see UrduMatch), so spelling/script/dialect
/// variants collapse together — we list representative forms across standard
/// Urdu, Roman-Urdu, and regional variants (Punjabi-inflected, Saraiki).
///
/// severity 2 = distress → respond on a single utterance;
/// severity 1 = mild disorientation → respond only on repetition, so a calm
/// passing remark never triggers a response (fail toward silence).
class ConfusionPhrase {
  final String text;
  final String category;
  final int severity;
  const ConfusionPhrase(this.text, this.category, this.severity);
}

const List<ConfusionPhrase> kConfusionPhrases = [
  // Not recognising people
  ConfusionPhrase('یہ کون ہے', 'recognition', 1),
  ConfusionPhrase('yeh kaun hai', 'recognition', 1),
  ConfusionPhrase('تم کون ہو', 'recognition', 1),
  ConfusionPhrase('tum kaun ho', 'recognition', 1),
  ConfusionPhrase('آپ کون ہیں', 'recognition', 1),
  ConfusionPhrase('aap kaun hain', 'recognition', 1),
  ConfusionPhrase('tusi kaun ho', 'recognition', 1), // Punjabi
  ConfusionPhrase('main inhe nahi janta', 'recognition', 1),

  // Disoriented in place
  ConfusionPhrase('میں کہاں ہوں', 'place', 1),
  ConfusionPhrase('main kahan hoon', 'place', 1),
  ConfusionPhrase('main kithe haan', 'place', 1), // Punjabi
  ConfusionPhrase('yeh kaunsi jagah hai', 'place', 1),
  ConfusionPhrase('mujhe ghar jana hai', 'place', 1),
  ConfusionPhrase('ghar kab jayenge', 'place', 1),
  ConfusionPhrase('ghar kad jana', 'place', 1), // Punjabi/Saraiki

  // Disoriented in time
  ConfusionPhrase('kya waqt hua', 'time', 1),
  ConfusionPhrase('din hai ya raat', 'time', 1),

  // Distress — respond immediately
  ConfusionPhrase('مجھے ڈر لگ رہا ہے', 'distress', 2),
  ConfusionPhrase('mujhe dar lag raha hai', 'distress', 2),
  ConfusionPhrase('mujhe ghabrahat ho rahi hai', 'distress', 2),
  ConfusionPhrase('mujhe dar', 'distress', 2),
];
