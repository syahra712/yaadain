import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// A private, gentle weekly summary for the caregiver: how often the elder
/// seemed confused, what kind, and when. Never a transcript — just patterns,
/// so it informs care without feeling like surveillance.
class PatternReportScreen extends StatelessWidget {
  const PatternReportScreen({super.key});

  static const _catLabel = {
    'recognition': 'Didn’t recognise someone',
    'place': 'Unsure where they were',
    'time': 'Unsure of the time',
    'distress': 'Sounded distressed',
    'safe_zone': 'Left the safe zone',
  };
  static const _catEmoji = {
    'recognition': '🙂',
    'place': '🏠',
    'time': '🕰️',
    'distress': '💛',
    'safe_zone': '📍',
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final now = DateTime.now();
    final week = app.episodes.where((e) => now.difference(e.at).inDays < 7).toList();

    // Counts by category.
    final byCat = <String, int>{};
    for (final e in week) {
      byCat[e.category] = (byCat[e.category] ?? 0) + 1;
    }
    final cats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Counts by time-of-day.
    final byPart = {'Morning': 0, 'Afternoon': 0, 'Evening': 0, 'Night': 0};
    for (final e in week) {
      byPart[_partOfDay(e.at.hour)] = byPart[_partOfDay(e.at.hour)]! + 1;
    }
    final peak = week.isEmpty
        ? null
        : (byPart.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
    final maxCat = cats.isEmpty ? 1 : cats.first.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly pattern report')),
      body: week.isEmpty
          ? const EmptyState(
              emoji: '📋',
              title: 'Nothing to report yet',
              subtitle: 'When the reactive companion notices confusion, a private, '
                  'gentle summary builds up here — how often, what kind, and when.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: YaadainTheme.primarySoft,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${week.length} gentle moments this week',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: YaadainTheme.primaryDark)),
                        const SizedBox(height: 6),
                        Text(
                          peak != null && peak.value > 0
                              ? 'Most often in the ${peak.key.toLowerCase()}. This is information to help you care — not a cause for alarm.'
                              : 'A calm week.',
                          style: const TextStyle(fontSize: 15, color: YaadainTheme.ink, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const SectionLabel('What came up', icon: Icons.insights),
                ...cats.map((c) => _Bar(
                      emoji: _catEmoji[c.key] ?? '•',
                      label: _catLabel[c.key] ?? c.key,
                      count: c.value,
                      fraction: c.value / maxCat,
                    )),
                const SizedBox(height: 16),
                const SectionLabel('When it happened', icon: Icons.schedule),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: byPart.entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    SizedBox(width: 96, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700))),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: week.isEmpty ? 0 : e.value / week.length,
                                          minHeight: 12,
                                          backgroundColor: YaadainTheme.surfaceAlt,
                                          valueColor: const AlwaysStoppedAnimation(YaadainTheme.accent),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Private to this device. Yaadain records only that a moment happened '
                  'and its kind — never what was said.',
                  style: TextStyle(color: YaadainTheme.muted, height: 1.5),
                ),
              ],
            ),
    );
  }

  String _partOfDay(int h) {
    if (h >= 5 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    if (h >= 17 && h < 21) return 'Evening';
    return 'Night';
  }
}

class _Bar extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final double fraction;
  const _Bar({required this.emoji, required this.label, required this.count, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.05, 1.0),
                    minHeight: 12,
                    backgroundColor: YaadainTheme.surfaceAlt,
                    valueColor: const AlwaysStoppedAnimation(YaadainTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
