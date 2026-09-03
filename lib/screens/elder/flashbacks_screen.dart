import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/relationship.dart';
import '../../nlp/flashback_engine.dart';
import '../../services/audio_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/elder_scaffold.dart';
import '../../widgets/ui.dart';

/// Flashbacks: say or type a word — a name, a place, "Eid", "shaadi" — and
/// Yaadain surfaces the matching recorded memory and plays it. Retrieval
/// only, script-tolerant (Urdu ↔ Roman-Urdu).
class FlashbacksScreen extends StatefulWidget {
  const FlashbacksScreen({super.key});

  @override
  State<FlashbacksScreen> createState() => _FlashbacksScreenState();
}

class _FlashbacksScreenState extends State<FlashbacksScreen> {
  final _audio = AudioService.instance;
  final _controller = TextEditingController();
  List<FlashbackHit> _hits = [];
  String? _playing;

  @override
  void dispose() {
    _audio.stop();
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    final members = context.read<AppState>().members;
    setState(() => _hits = FlashbackEngine.search(q, members));
  }

  Future<void> _toggle(String path) async {
    if (_playing == path) {
      await _audio.stop();
      setState(() => _playing = null);
    } else {
      await _audio.play(path);
      setState(() => _playing = path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roman = app.roman;

    // Suggest a few triggers that actually exist in the bank.
    final suggestions = <String>{
      for (final m in app.members)
        for (final st in m.stories) ...st.triggers,
    }.take(8).toList();

    return ElderScaffold(
      title: roman ? 'Yaadein' : 'یادیں',
      roman: roman,
      accent: YaadainTheme.accent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              style: const TextStyle(fontSize: 19),
              decoration: InputDecoration(
                hintText: roman ? 'Koi naam ya jagah likhiye…' : 'کوئی نام یا جگہ لکھیے…',
                hintStyle: const TextStyle(fontStyle: FontStyle.italic, color: YaadainTheme.foxed),
                prefixIcon: const Icon(Icons.search, size: 24, color: YaadainTheme.foxed),
                filled: true,
                fillColor: YaadainTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: YaadainTheme.leafRule.withOpacity(0.4)),
                ),
              ),
            ),
          ),
          if (_controller.text.isEmpty && suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions
                    .map((s) => InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _controller.text = s;
                            _search(s);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: YaadainTheme.leafRule.withOpacity(0.45)),
                            ),
                            child: Text(s,
                                style: const TextStyle(
                                    fontSize: 14.5, fontStyle: FontStyle.italic, color: YaadainTheme.foxed)),
                          ),
                        ))
                    .toList(),
              ),
            ),
          Expanded(
            child: _controller.text.isEmpty
                ? EmptyState(
                    emoji: '🕰️',
                    title: roman ? 'Koi yaad dhoondiye' : 'کوئی یاد ڈھونڈیے',
                    subtitle: roman
                        ? 'Koi naam ya jagah likhiye — jaise “Eid”, “shaadi”, “gaon”.'
                        : 'کوئی نام یا جگہ لکھیے — جیسے عید، شادی، گاؤں۔',
                  )
                : _hits.isEmpty
                    ? EmptyState(
                        emoji: '🔍',
                        title: roman ? 'Koi yaad nahi mili' : 'کوئی یاد نہیں ملی',
                        subtitle: roman ? 'Koi aur lafz aazmaiye.' : 'کوئی اور لفظ آزمائیے۔',
                      )
                    : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    itemCount: _hits.length,
                    separatorBuilder: (_, __) => Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: YaadainTheme.leafRule.withOpacity(0.22),
                    ),
                    itemBuilder: (_, i) {
                      final h = _hits[i];
                      final rel = relationshipById(h.member.relationshipId);
                      final relLabel = rel == null ? '' : (roman ? rel.roman : rel.urdu);
                      final name = roman ? (h.member.romanName ?? h.member.name) : h.member.name;
                      final playing = _playing == h.story.audioPath;
                      final hasPhoto = h.story.photoPath != null && File(h.story.photoPath!).existsSync();
                      return InkWell(
                        onTap: h.story.audioPath == null ? null : () => _toggle(h.story.audioPath!),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: YaadainTheme.leafRule.withOpacity(0.5), width: 2),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: hasPhoto
                                    ? Image.file(File(h.story.photoPath!), fit: BoxFit.cover)
                                    : Icon(playing ? Icons.stop : Icons.play_arrow,
                                        color: YaadainTheme.primaryDark, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(h.story.title, style: YaadainTheme.serif(18, w: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      roman ? '$name — aap ke/ki $relLabel' : '$name — آپ کے/کی $relLabel',
                                      style: const TextStyle(
                                          fontSize: 13.5, fontStyle: FontStyle.italic, color: YaadainTheme.foxed),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(playing ? Icons.stop_circle : Icons.volume_up_outlined,
                                  color: YaadainTheme.primaryDark, size: 26),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
