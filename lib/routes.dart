import 'package:flutter/material.dart';

import 'screens/elder/elder_home_screen.dart';
import 'screens/elder/family_tree_screen.dart';
import 'screens/elder/member_detail_screen.dart';
import 'screens/elder/night_anchor_screen.dart';
import 'screens/elder/poochhein_screen.dart';
import 'screens/elder/routine_prompt_screen.dart';
import 'screens/elder/sukoon_screen.dart';
import 'screens/elder/voices_screen.dart';
import 'screens/elder/who_is_this_screen.dart';
import 'screens/family/add_relative_screen.dart';
import 'screens/family/answers_editor_screen.dart';
import 'screens/family/care_circle_screen.dart';
import 'screens/family/caregiver_home_screen.dart';
import 'screens/family/family_home_screen.dart';
import 'screens/family/record_hello_screen.dart';
import 'screens/family/routine_screen.dart';
import 'screens/family/weekly_report_screen.dart';
import 'screens/onboarding/consent_record_screen.dart';
import 'screens/onboarding/elder_phone_setup_screen.dart';
import 'screens/onboarding/join_family_screen.dart';
import 'screens/onboarding/khayal_screen.dart';
import 'screens/onboarding/permissions_screen.dart';
import 'screens/onboarding/role_selection_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/safety/alert_detail_screen.dart';
import 'screens/safety/find_abu_screen.dart';
import 'screens/safety/if_found_screen.dart';
import 'screens/safety/im_safe_screen.dart';
import 'screens/safety/madad_screen.dart';
import 'screens/safety/safe_zones_screen.dart';
import 'screens/safety/where_is_abu_screen.dart';
import 'settings/locked_settings.dart';

/// Every route name in the app.
class Routes {
  Routes._();
  static const boot = '/';

  // onboarding
  static const splash = '/splash';
  static const role = '/role';
  static const join = '/join';
  static const elderPhoneSetup = '/setup/elder-phone';
  static const permissions = '/setup/permissions';
  static const khayal = '/setup/khayal';
  static const consent = '/setup/consent';

  // elder (Urdu)
  static const elderHome = '/elder';
  static const elderNight = '/elder/night';
  static const routinePrompt = '/elder/routine-prompt';
  static const sukoon = '/elder/sukoon';
  static const familyTree = '/elder/family';
  static const whoIsThis = '/elder/who';
  static const memberDetail = '/elder/member';
  static const poochhein = '/elder/ask';
  static const voices = '/elder/voices';
  static const madad = '/elder/madad';
  static const imSafe = '/elder/safe';
  static const ifFound = '/elder/if-found';

  // caregiver / family (English)
  static const care = '/care';
  static const careWhere = '/care/where';
  static const careAlert = '/care/alert';
  static const careZones = '/care/zones';
  static const careFind = '/care/find';
  static const careCircle = '/care/circle';
  static const careReport = '/care/report';
  static const careAddRelative = '/care/add-relative';
  static const careAnswers = '/care/answers';
  static const careRoutine = '/care/routine';
  static const family = '/family';
  static const familyRecord = '/family/record';

  // foundation
  static const lockedSettings = '/settings';

  /// Routes that rest on the elder phone's root (time-mode watcher may swap).
  static const elderRoots = {elderHome, elderNight};
}

// ── Argument classes ────────────────────────────────────────────────────────

/// `/elder/member`
class MemberDetailArgs {
  final String memberId;
  const MemberDetailArgs(this.memberId);
}

/// `/elder/safe` (reaction pushes it when a visit arrives; null args = generic).
class ImSafeArgs {
  final String? byName; // English name of the visitor ("Bilal"); screen maps to Urdu via memberId
  final String? memberId;
  final int? etaMin;
  const ImSafeArgs({this.byName, this.memberId, this.etaMin});
}

/// `/elder/routine-prompt`
class RoutinePromptArgs {
  final String itemId;
  const RoutinePromptArgs(this.itemId);
}

/// `/elder/if-found` (also `/care/find` may open it)
class IfFoundArgs {
  final bool english; // initial language; false = Urdu
  const IfFoundArgs({this.english = false});
}

/// `/care/add-relative` (memberId == null -> add; set -> edit)
class AddRelativeArgs {
  final String? memberId;
  const AddRelativeArgs({this.memberId});
}

/// `/care/answers` (optional question to open first: day|where|bilal|food|medicine|ruqayya)
class AnswersEditorArgs {
  final String? questionId;
  const AnswersEditorArgs({this.questionId});
}

/// `/join` (prefill from a scanned / deep-linked code)
class JoinFamilyArgs {
  final String? code;
  const JoinFamilyArgs({this.code});
}

/// `/family/record` (record a hello as [memberId]; default = this device's member)
class RecordHelloArgs {
  final String? memberId;
  const RecordHelloArgs({this.memberId});
}

// ── Navigation plumbing ─────────────────────────────────────────────────────

/// The root navigator. Use for navigation from non-widget code (demo
/// controls, elder reaction).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Tracks the route currently on top so reactions can avoid double-pushes.
class RouteTracker extends NavigatorObserver {
  RouteTracker._();
  static final RouteTracker instance = RouteTracker._();

  final ValueNotifier<String?> current = ValueNotifier<String?>(null);
  final List<Route<dynamic>> _stack = [];

  String? get name => _stack.isEmpty ? null : _stack.last.settings.name;

  void _set() {
    final n = name;
    if (current.value != n) {
      // Defer: observer callbacks fire during navigation/build.
      WidgetsBinding.instance.addPostFrameCallback((_) => current.value = n);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _set();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _set();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _set();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute != null) {
      if (i >= 0) {
        _stack[i] = newRoute;
      } else {
        _stack.add(newRoute);
      }
    } else if (i >= 0) {
      _stack.removeAt(i);
    }
    _set();
  }
}

/// Resets the stack to [route] (used for role roots and view switches).
void goRoot(String route, {Object? arguments}) {
  appNavigatorKey.currentState?.pushNamedAndRemoveUntil(route, (r) => false, arguments: arguments);
}

bool _isTab(String? n) => n == Routes.care || n == Routes.family || n == Routes.careWhere || n == Routes.careCircle;

T? _args<T>(RouteSettings s) {
  final a = s.arguments;
  return a is T ? a : null;
}

/// MaterialApp.onGenerateRoute. Unknown names fall back to the role root.
Route<dynamic> onGenerateRoute(RouteSettings s) {
  final Widget page;
  switch (s.name) {
    case Routes.splash:
      page = const SplashScreen();
      break;
    case Routes.role:
      page = const RoleSelectionScreen();
      break;
    case Routes.join:
      page = JoinFamilyScreen(code: _args<JoinFamilyArgs>(s)?.code);
      break;
    case Routes.elderPhoneSetup:
      page = const ElderPhoneSetupScreen();
      break;
    case Routes.permissions:
      page = const PermissionsScreen();
      break;
    case Routes.khayal:
      page = const KhayalScreen();
      break;
    case Routes.consent:
      page = const ConsentRecordScreen();
      break;
    case Routes.elderHome:
      page = const ElderHomeScreen();
      break;
    case Routes.elderNight:
      page = const NightAnchorScreen();
      break;
    case Routes.routinePrompt:
      page = RoutinePromptScreen(itemId: _args<RoutinePromptArgs>(s)?.itemId);
      break;
    case Routes.sukoon:
      page = const SukoonScreen();
      break;
    case Routes.familyTree:
      page = const FamilyTreeScreen();
      break;
    case Routes.whoIsThis:
      page = const WhoIsThisScreen();
      break;
    case Routes.memberDetail:
      page = MemberDetailScreen(memberId: _args<MemberDetailArgs>(s)?.memberId ?? (s.arguments is String ? s.arguments as String : ''));
      break;
    case Routes.poochhein:
      page = const PoochheinScreen();
      break;
    case Routes.voices:
      page = const VoicesScreen();
      break;
    case Routes.madad:
      page = const MadadScreen();
      break;
    case Routes.imSafe:
      final a = _args<ImSafeArgs>(s);
      page = ImSafeScreen(byName: a?.byName, memberId: a?.memberId, etaMin: a?.etaMin);
      break;
    case Routes.ifFound:
      page = IfFoundScreen(english: _args<IfFoundArgs>(s)?.english ?? false);
      break;
    case Routes.care:
      page = const CaregiverHomeScreen();
      break;
    case Routes.family:
      page = const FamilyHomeScreen();
      break;
    case Routes.careWhere:
      page = const WhereIsAbuScreen();
      break;
    case Routes.careAlert:
      page = const AlertDetailScreen();
      break;
    case Routes.careZones:
      page = const SafeZonesScreen();
      break;
    case Routes.careFind:
      page = const FindAbuScreen();
      break;
    case Routes.careCircle:
      page = const CareCircleScreen();
      break;
    case Routes.careReport:
      page = const WeeklyReportScreen();
      break;
    case Routes.careAddRelative:
      page = AddRelativeScreen(memberId: _args<AddRelativeArgs>(s)?.memberId);
      break;
    case Routes.careAnswers:
      page = AnswersEditorScreen(questionId: _args<AnswersEditorArgs>(s)?.questionId);
      break;
    case Routes.careRoutine:
      page = const RoutineScreen();
      break;
    case Routes.familyRecord:
      page = RecordHelloScreen(memberId: _args<RecordHelloArgs>(s)?.memberId);
      break;
    case Routes.lockedSettings:
      page = const LockedSettingsScreen();
      break;
    default:
      page = const SplashScreen();
  }
  // Tabs swap without an animation; everything else uses the platform route.
  if (_isTab(s.name) || s.name == Routes.elderHome || s.name == Routes.elderNight) {
    return PageRouteBuilder<dynamic>(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
  return MaterialPageRoute<dynamic>(settings: s, builder: (_) => page);
}
