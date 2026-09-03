import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/app_settings.dart';
import 'screens/elder/elder_home.dart';
import 'screens/elder/family_tree_screen.dart';
import 'screens/family/family_home.dart';
import 'screens/role/role_selection_screen.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'theme.dart';

/// Preview-only: when true, the app opens straight onto the family tree so it
/// can be inspected without tap-navigation. MUST be false for real use.
const bool kPreviewTree = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connect Firebase (for remote family contribution). If it fails — no config,
  // no network — the app still runs fully offline via the local sync stub.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.signInAnonymously();
  } catch (_) {
    // Offline / unconfigured: continue with the local-only experience.
  }
  try {
    await NotificationService.instance.init();
  } catch (_) {
    // No notification channel available (e.g. unsupported platform/test) —
    // safe-zone alerts still work in-app, just without a system banner.
  }
  runApp(const YaadainApp());
}

class YaadainApp extends StatelessWidget {
  const YaadainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        title: 'Yaadain',
        debugShowCheckedModeBanner: false,
        theme: YaadainTheme.light(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ur'), Locale('en')],
        home: const _Boot(),
      ),
    );
  }
}

class _Boot extends StatelessWidget {
  const _Boot();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (!app.ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Preview shortcut for inspecting the tree during development.
    if (kPreviewTree) {
      return Directionality(
        textDirection: app.roman ? TextDirection.ltr : TextDirection.rtl,
        child: const FamilyTreeScreen(),
      );
    }

    switch (app.role) {
      case DeviceRole.unset:
        // Setup screens are bilingual and left-to-right.
        return const RoleSelectionScreen();
      case DeviceRole.family:
        return const FamilyHome();
      case DeviceRole.elder:
        // The elder experience honours their script direction.
        return Directionality(
          textDirection: app.roman ? TextDirection.ltr : TextDirection.rtl,
          child: const ElderHome(),
        );
    }
  }
}
