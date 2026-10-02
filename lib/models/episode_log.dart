/// A logged confusion / calm / safety event for the caregiver's private
/// pattern report. Minimal on purpose: category, severity, time, and (for
/// Poochhein) which question — never a recording or transcript.
///
/// Categories: recognition | place | time | distress | safe_zone | question |
/// calm | night_pickup | zone_exit | zone_return | voice_played
class Episode {
  final String category;
  final int severity;
  final DateTime at;

  /// Poochhein question id (day|where|bilal|food|medicine|ruqayya) when
  /// category == 'question'.
  final String? question;

  /// Optional short English note ("Masjid Noor", member id for voice_played).
  final String? note;

  Episode(
      {required this.category,
      this.severity = 1,
      required this.at,
      this.question,
      this.note});

  Map<String, dynamic> toJson() => {
        'category': category,
        'severity': severity,
        'at': at.toIso8601String(),
        if (question != null) 'question': question,
        if (note != null) 'note': note,
      };

  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
        category: (j['category'] ?? 'unknown') as String,
        severity: ((j['severity'] ?? 1) as num).toInt(),
        at: DateTime.tryParse((j['at'] ?? '') as String) ?? DateTime.now(),
        question: j['question'] as String?,
        note: j['note'] as String?,
      );
}
