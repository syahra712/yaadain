import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'design/patterns.dart';
import 'firebase_options.dart';
import 'models/app_settings.dart';
import 'routes.dart';
import 'services/firebase_gate.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'tracking/elder_reaction.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connect Firebase (for remote family contribution). If it fails, there is no
  // config, or the config is the local-build placeholder, the app runs fully
  // offline and never waits on the network.
  try {
    final opts = DefaultFirebaseOptions.currentPlatform;
    if (!FirebaseGate.isPlaceholder(opts.apiKey, opts.projectId)) {
      await Firebase.initializeApp(options: opts).timeout(const Duration(seconds: 4));
      FirebaseGate.available = true;
      // Anonymous sign-in is best effort and never blocks the first frame.
      unawaited(FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(seconds: 8))
          .then<void>((_) {}, onError: (_) {}));
    }
  } catch (_) {
    FirebaseGate.available = false;
  }
  try {
    await NotificationService.instance.init().timeout(const Duration(seconds: 3));
  } catch (_) {
    // No notification channel available (e.g. unsupported platform/test);
    // alerts still work in-app, just without a system banner.
  }
  runApp(const YaadainApp());
}

class YaadainApp extends StatefulWidget {
  /// Tests / harness can pass a ready state and skip disk + reaction timers.
  final AppState? state;
  const YaadainApp({super.key, this.state});

  @override
  State<YaadainApp> createState() => _YaadainAppState();
}

class _YaadainAppState extends State<YaadainApp> {
  late final AppState _app;
  late final ElderReaction _reaction;
  late final bool _owns;

  static final ThemeData _elder = YaadainTheme.elder();
  static final ThemeData _family = YaadainTheme.family();

  @override
  void initState() {
    super.initState();
    _owns = widget.state == null;
    _app = widget.state ?? (AppState()..init());
    _reaction = ElderReaction(_app)..start();
  }

  @override
  void dispose() {
    _reaction.dispose();
    if (_owns) _app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: _app,
      child: Selector<AppState, bool>(
        selector: (_, app) => app.ready && app.role == DeviceRole.elder,
        builder: (context, elder, _) {
          return MaterialApp(
            title: 'Yaadain',
            debugShowCheckedModeBanner: false,
            navigatorKey: appNavigatorKey,
            navigatorObservers: [RouteTracker.instance],
            theme: elder ? _elder : _family,
            // System surfaces (dialogs, keyboards, snackbars) follow the role.
            locale: elder ? const Locale('ur') : const Locale('en'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ur'), Locale('en')],
            initialRoute: Routes.boot,
            onGenerateRoute: (s) => s.name == Routes.boot
                ? MaterialPageRoute<void>(settings: s, builder: (_) => const _Boot())
                : onGenerateRoute(s),
          );
        },
      ),
    );
  }
}

/// Waits for the store, then replaces itself with the role's root route:
/// unset -> /splash, elder -> /elder (or /elder/night), caregiver -> /care,
/// family -> /family.
class _Boot extends StatefulWidget {
  const _Boot();
  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  bool _went = false;

  void _go(AppState app) {
    if (_went || !app.ready) return;
    _went = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(app.initialRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    _go(app);
    return const Scaffold(
      backgroundColor: YaadainTheme.primaryDark,
      body: Center(child: LogoMark(size: 72)),
    );
  }
}
