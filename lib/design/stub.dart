import 'package:flutter/material.dart';

import '../theme.dart';
import 'text.dart';

/// Placeholder body for screens that are not built yet (foundation stubs).
/// Replace the whole screen; do not keep this.
class StubBody extends StatelessWidget {
  final String text;
  final bool urdu;
  const StubBody.elder({super.key, this.text = 'یہ صفحہ تیار ہو رہا ہے۔'}) : urdu = true;
  const StubBody.family(this.text, {super.key}) : urdu = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: urdu
            ? UrduText(text, size: 28, color: YaadainTheme.muted, align: TextAlign.center)
            : EnText(text, size: 16, color: YaadainTheme.muted, weight: FontWeight.w700, align: TextAlign.center),
      ),
    );
  }
}
