import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/relationship.dart';
import '../../services/audio_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

/// The reactive response. When confusion is detected, Yaadain gently plays a
/// REAL recorded calming clip (never synthesised) over a soft, familiar face,
/// with warm re-orientation text. The elder does nothing to summon it.
class ReassuranceScreen extends StatefulWidget {
  final String category; // recognition | place | time | distress
  const ReassuranceScreen({super.key, required this.category});

  @override
  State<ReassuranceScreen> createState() => _ReassuranceScreenState();
}

class _ReassuranceScreenState extends State<ReassuranceScreen> {
  final _audio = AudioService.instance;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playAndClose());
    // Never leave a confused elder stranded on this screen — fade back home
    // on its own after a calm pause if they don't tap.
    _autoDismiss = Timer(const Duration(seconds: 22), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  Future<void> _playAndClose() async {
    final app = context.read<AppState>();
    final path = app.elder.reassuranceAudioPath;
    if (path != null && File(path).existsSync()) {
      await _audio.play(path);
    }
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _audio.stop();
    super.dispose();
  }

  String _line(bool roman) {
    switch (widget.category) {
      case 'place':
        return roman ? 'Aap apne ghar par hain.\nAap mehfooz hain.' : 'آپ اپنے گھر پر ہیں۔\nآپ محفوظ ہیں۔';
      case 'time':
        return roman ? 'Sab theek hai.\nAap aaram se rahiye.' : 'سب ٹھیک ہے۔\nآپ آرام سے رہیے۔';
      case 'distress':
        return roman ? 'Aap mehfooz hain.\nMain aap ke saath hoon.' : 'آپ محفوظ ہیں۔\nمیں آپ کے ساتھ ہوں۔';
      default: // recognition
        return roman ? 'Yeh aap ke apne hain.\nAap se pyar karte hain.' : 'یہ آپ کے اپنے ہیں۔\nآپ سے پیار کرتے ہیں۔';
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roman = app.roman;
    final member = app.elder.reassuranceMemberId == null
        ? null
        : app.memberById(app.elder.reassuranceMemberId!);
    final photoPath = member?.photoPath ?? app.elder.photoPath;
    final hasPhoto = photoPath != null && File(photoPath).existsSync();
    final rel = member == null ? null : relationshipById(member.relationshipId);

    return Directionality(
      textDirection: roman ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
      backgroundColor: YaadainTheme.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 196,
                height: 196,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: YaadainTheme.gold, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 12)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPhoto
                    ? Image.file(File(photoPath), fit: BoxFit.cover)
                    : const Icon(Icons.favorite, size: 92, color: YaadainTheme.primary),
              ),
              const SizedBox(height: 26),
              if (member != null)
                Text(
                  roman
                      ? '${member.romanName ?? member.name} · aap ke/ki ${rel?.roman ?? ''}'
                      : '${member.name} · آپ کے/کی ${rel?.urdu ?? ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.6)),
                ),
              const SizedBox(height: 18),
              Text(
                _line(roman),
                textAlign: TextAlign.center,
                style: YaadainTheme.serif(30, w: FontWeight.w600, color: Colors.white, h: 1.5),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: YaadainTheme.gold, width: 1.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 19),
                      child: Text(
                        roman ? 'Main theek hoon' : 'میں ٹھیک ہوں',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: YaadainTheme.gold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
