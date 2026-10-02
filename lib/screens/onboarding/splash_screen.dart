import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../demo/demo_controls.dart';
import '../../design/design.dart';
import '../../models/app_settings.dart';
import '../../routes.dart';
import '../../state/app_state.dart';

/// First screen. Shows the mark for a moment, then hands over to the role
/// picker (new install) or the right home for this phone.
/// Long-press the mark for the presenter's demo controls.
class SplashScreen extends StatefulWidget {
  /// Tests pass false so no timer is left pending.
  final bool autoAdvance;
  const SplashScreen({super.key, this.autoAdvance = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoAdvance) {
      _timer = Timer(const Duration(milliseconds: 2200), _advance);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _advance() {
    if (!mounted) return;
    final app = context.read<AppState>();
    if (!app.ready) {
      _timer = Timer(const Duration(milliseconds: 300), _advance);
      return;
    }
    goRoot(app.role == DeviceRole.unset ? Routes.role : app.initialRoute);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: FamilyTheme(
        child: Scaffold(
          backgroundColor: YaadainTheme.primaryDark,
          body: Stack(
            children: [
              const Positioned.fill(
                  child: JaaliPattern(opacity: .07, fadeBottom: false)),
              Positioned.fill(
                child: Column(
                  children: [
                    const Spacer(flex: 248),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: () => DemoControls.open(context),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(.22)),
                              ),
                            ),
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(.09)),
                            ),
                            const LogoMark(size: 120),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    const EnText('Yaadain',
                        size: 40,
                        weight: FontWeight.w700,
                        display: true,
                        color: Colors.white,
                        height: 1.2),
                    const SizedBox(height: 18),
                    Container(
                        width: 40, height: 1.5, color: YaadainTheme.accent),
                    const SizedBox(height: 20),
                    EnText('Your family, always with you',
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white.withOpacity(.88)),
                    const Spacer(flex: 196),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: _Progress(animate: widget.autoAdvance),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final bool animate;
  const _Progress({required this.animate});

  @override
  Widget build(BuildContext context) {
    Widget bar(double f) => Container(
          width: 56,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              borderRadius: BorderRadius.circular(2)),
          alignment: Alignment.centerLeft,
          child: Container(
            width: 56 * f,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(.9),
                borderRadius: BorderRadius.circular(2)),
          ),
        );
    if (!animate) return bar(.62);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .1, end: 1),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (_, v, __) => bar(v),
    );
  }
}
