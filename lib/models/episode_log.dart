/// A logged confusion/distress episode, for the caregiver's private pattern
/// report. Deliberately minimal — a category, severity, and time — never a
/// recording or transcript of the elder, so it can't feel like surveillance.
class Episode {
  final String category; // recognition | place | time | distress | safe_zone
  final int severity;
  final DateTime at;

  Episode({required this.category, required this.severity, required this.at});

  Map<String, dynamic> toJson() => {
        'category': category,
        'severity': severity,
        'at': at.toIso8601String(),
      };

  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
        category: (j['category'] ?? 'unknown') as String,
        severity: (j['severity'] ?? 1) as int,
        at: DateTime.tryParse((j['at'] ?? '') as String) ?? DateTime.now(),
      );
}
