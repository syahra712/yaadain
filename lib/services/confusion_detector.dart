import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import '../data/confusion_phrases.dart';
import '../nlp/urdu_match.dart';

class ConfusionEvent {
  final String category;
  final int severity;
  final String heard;
  final DateTime at;
  ConfusionEvent(this.category, this.severity, this.heard, this.at);
}

/// Always-listening (when enabled) confusion detector.
///
/// Design for a vulnerable user:
///  - Distress phrases respond on a single utterance; mild disorientation only
///    on **repetition** within a window, so a calm passing remark never fires.
///  - A cooldown after each response prevents nagging.
///  - Everything is best-effort: if speech isn't available, it simply stays
///    silent — it never blocks or crashes the elder experience.
class ConfusionDetector {
  final SpeechToText _stt = SpeechToText();
  final _controller = StreamController<ConfusionEvent>.broadcast();
  Stream<ConfusionEvent> get events => _controller.stream;

  bool _available = false;
  bool _enabled = false;
  bool _listening = false;
  String? _localeId;

  DateTime? _lastTrigger;
  final List<DateTime> _recentHits = [];

  static const double _matchThreshold = 0.80;
  static const Duration _cooldown = Duration(seconds: 60);
  static const Duration _repeatWindow = Duration(seconds: 120);

  bool get isAvailable => _available;
  bool get isEnabled => _enabled;

  Future<bool> init() async {
    try {
      _available = await _stt.initialize(
        onError: (_) => _restartSoon(),
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') _restartSoon();
        },
      );
      if (_available) {
        final locales = await _stt.locales();
        final ur = locales.where((l) => l.localeId.toLowerCase().startsWith('ur'));
        _localeId = ur.isNotEmpty ? ur.first.localeId : null;
      }
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  Future<void> start() async {
    _enabled = true;
    if (_available) _listen();
  }

  Future<void> stop() async {
    _enabled = false;
    try {
      await _stt.stop();
    } catch (_) {}
    _listening = false;
  }

  void _listen() async {
    if (!_enabled || _listening || !_available) return;
    _listening = true;
    try {
      await _stt.listen(
        onResult: (r) {
          if (r.finalResult) _evaluate(r.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          partialResults: false,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          localeId: _localeId,
        ),
      );
    } catch (_) {
      _restartSoon();
    }
  }

  void _restartSoon() {
    _listening = false;
    if (_enabled) {
      Future.delayed(const Duration(milliseconds: 500), _listen);
    }
  }

  void _evaluate(String heard) {
    if (heard.trim().isEmpty) return;

    ConfusionPhrase? best;
    double bestSim = 0;
    for (final p in kConfusionPhrases) {
      final s = UrduMatch.similarity(heard, p.text);
      if (s > bestSim) {
        bestSim = s;
        best = p;
      }
    }
    if (best == null || bestSim < _matchThreshold) return;

    final now = DateTime.now();
    if (_lastTrigger != null && now.difference(_lastTrigger!) < _cooldown) return;

    if (best.severity >= 2) {
      _trigger(best, heard, now);
      return;
    }

    // Mild disorientation: only respond if repeated within the window.
    _recentHits.removeWhere((t) => now.difference(t) > _repeatWindow);
    _recentHits.add(now);
    if (_recentHits.length >= 2) _trigger(best, heard, now);
  }

  void _trigger(ConfusionPhrase p, String heard, DateTime now) {
    _lastTrigger = now;
    _recentHits.clear();
    _controller.add(ConfusionEvent(p.category, p.severity, heard, now));
  }

  void dispose() {
    _controller.close();
    _stt.cancel();
  }
}
