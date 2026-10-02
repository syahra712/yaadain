import 'package:flutter/material.dart';

/// Yaadain design tokens (BRIEF) + the two ThemeData flavours.
///
///  - [YaadainTheme.elder]  : Urdu, RTL, NastaliqUrdu only.
///  - [YaadainTheme.family] : English, LTR, Nunito body + Fraunces display.
///
/// `fontFamily` is always set explicitly; never rely on a fallback chain for
/// Urdu (a Latin font in front breaks Nastaliq metrics).
class YaadainTheme {
  YaadainTheme._();

  // ── Neutrals ──────────────────────────────────────────────────────────
  static const Color paper = Color(0xFFF3EBDC); // app background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE6DECF);
  static const Color stroke = Color(0xFF857A68);
  static const Color ink = Color(0xFF2C2620);
  static const Color muted = Color(0xFF6B5F4D);
  static const Color bodyDim = Color(0xFF4A4036);

  // ── Brand ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1F6F5C);
  static const Color primaryDark = Color(0xFF124C3E);
  static const Color primarySoft = Color(0xFFDCEBE5);
  /// THE single care / safety action per screen.
  static const Color accentDark = Color(0xFF9E5626);
  /// Decorative clay dot only (never text, never a button).
  static const Color accent = Color(0xFFC7743A);
  static const Color gold = Color(0xFFB88A3E);
  /// Memorial ring colour for deceased relatives.
  static const Color sepia = Color(0xFFA9998A);

  // ── States ────────────────────────────────────────────────────────────
  static const Color attention = Color(0xFF9E5626);
  static const Color attentionSoft = Color(0xFFF6E3D3);
  /// True emergencies only.
  static const Color emergency = Color(0xFFB3261E);
  static const Color emergencySoft = Color(0xFFFBE9E7);
  static const Color success = primary;
  static const Color successSoft = primarySoft;

  // ── Avatar tints (bg / fg) ────────────────────────────────────────────
  static const AvatarTint tintTeal = AvatarTint(Color(0xFFDCEBE5), Color(0xFF124C3E));
  static const AvatarTint tintClay = AvatarTint(Color(0xFFF6E3D3), Color(0xFF7D4219));
  static const AvatarTint tintGold = AvatarTint(Color(0xFFF1E6CC), Color(0xFF6E5420));
  static const AvatarTint tintSage = AvatarTint(Color(0xFFE3E8D6), Color(0xFF475326));
  static const AvatarTint tintPlum = AvatarTint(Color(0xFFE9E1EC), Color(0xFF55406A));
  static const List<AvatarTint> tints = [tintTeal, tintClay, tintGold, tintSage, tintPlum];

  /// Tint by name ("teal", "clay", "gold", "sage", "plum"); unknown -> teal.
  static AvatarTint tintByName(String? name) {
    switch (name) {
      case 'clay':
        return tintClay;
      case 'gold':
        return tintGold;
      case 'sage':
        return tintSage;
      case 'plum':
        return tintPlum;
      default:
        return tintTeal;
    }
  }

  static const List<String> tintNames = ['teal', 'clay', 'gold', 'sage', 'plum'];

  // ── Radii ─────────────────────────────────────────────────────────────
  static const double r12 = 12;
  static const double r20 = 20;
  static const double r28 = 28;
  static const double rPill = 999;
  static const BorderRadius radius12 = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radius20 = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radius28 = BorderRadius.all(Radius.circular(28));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(999));

  // ── Spacing (4/8 grid) ────────────────────────────────────────────────
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;

  /// Gutters.
  static const double elderGutter = 24;
  static const double familyGutter = 16;

  /// Touch targets.
  static const double elderTouch = 56;
  static const double elderPrimaryTouch = 64;
  static const double elderPrimaryTouchLarge = 80;
  static const double familyTouch = 48;

  /// The board mock status bar height; the real app uses SafeArea.
  static const double boardStatusBar = 32;

  // ── Fonts ─────────────────────────────────────────────────────────────
  static const String urduFont = 'NastaliqUrdu';
  static const String bodyFont = 'Nunito';
  static const String displayFont = 'Fraunces';

  // ── Compatibility aliases (kept so older shared code keeps compiling) ──
  static const Color warmBg = paper;
  static const Color surfaceAlt = Color(0xFFFBF7EE);
  static const Color accentSoft = attentionSoft;
  static const Color danger = emergency;
  static const Color dangerSoft = emergencySoft;
  static const double rSm14 = 12;
  static const double rMd20 = 20;
  static const double rLg28 = 28;

  // ── Shadows ───────────────────────────────────────────────────────────
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x142C2620), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ── ThemeData ─────────────────────────────────────────────────────────

  /// Elder phone: Urdu, RTL, Nastaliq at weight 400 only, height >= 1.8.
  static ThemeData elder() {
    TextStyle u(double size, {Color color = ink}) => TextStyle(
          fontFamily: urduFont,
          fontSize: size,
          fontWeight: FontWeight.w400,
          height: 1.9,
          color: color,
        );
    final text = TextTheme(
      displayLarge: u(44),
      displayMedium: u(40),
      displaySmall: u(36),
      headlineLarge: u(36),
      headlineMedium: u(32),
      headlineSmall: u(28),
      titleLarge: u(28),
      titleMedium: u(24),
      titleSmall: u(22),
      bodyLarge: u(24),
      bodyMedium: u(22),
      bodySmall: u(20, color: muted),
      labelLarge: u(24),
      labelMedium: u(20),
      labelSmall: u(20),
    );
    return _base(
      fontFamily: urduFont,
      text: text,
      fontFamilyFallback: const <String>[],
    ).copyWith(
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: u(22))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(textStyle: u(24))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(textStyle: u(24))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(textStyle: u(24))),
    );
  }

  /// Family / caregiver: English, LTR, Nunito body; Fraunces for display
  /// (use [display] for headings).
  static ThemeData family() {
    TextStyle n(double size, FontWeight w, {Color color = ink, double height = 1.4}) =>
        nunito(size, w, color: color, height: height);
    TextStyle f(double size, FontWeight w, {Color color = ink}) =>
        TextStyle(fontFamily: displayFont, fontSize: size, fontWeight: w, height: 1.2, color: color);
    final text = TextTheme(
      displayLarge: f(40, FontWeight.w700),
      displayMedium: f(34, FontWeight.w700),
      displaySmall: f(30, FontWeight.w700),
      headlineLarge: f(28, FontWeight.w700),
      headlineMedium: f(24, FontWeight.w600),
      headlineSmall: f(22, FontWeight.w600),
      titleLarge: n(20, FontWeight.w800),
      titleMedium: n(17, FontWeight.w800),
      titleSmall: n(15, FontWeight.w700),
      bodyLarge: n(17, FontWeight.w500),
      bodyMedium: n(15, FontWeight.w500),
      bodySmall: n(13, FontWeight.w500, color: muted),
      labelLarge: n(16, FontWeight.w800),
      labelMedium: n(14, FontWeight.w700),
      labelSmall: n(12, FontWeight.w800),
    );
    return _base(fontFamily: bodyFont, text: text, fontFamilyFallback: const <String>[]);
  }

  /// Legacy entry point.
  static ThemeData light() => family();

  static ThemeData _base({
    required String fontFamily,
    required TextTheme text,
    required List<String> fontFamilyFallback,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primarySoft,
      onPrimaryContainer: primaryDark,
      secondary: accentDark,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: ink,
      error: emergency,
      onError: Colors.white,
      outline: stroke,
      outlineVariant: line,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback.isEmpty ? null : fontFamilyFallback,
      textTheme: text,
      primaryTextTheme: text,
      scaffoldBackgroundColor: paper,
      canvasColor: paper,
      dividerColor: line,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryDark,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: radius12),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: radius28),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: stroke, width: 1.5),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: stroke, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: muted),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  // ── Text style helpers ────────────────────────────────────────────────

  /// Fraunces display style for English headings.
  static TextStyle display(double size,
          {FontWeight weight = FontWeight.w700, Color color = ink, double height = 1.2}) =>
      TextStyle(fontFamily: displayFont, fontSize: size, fontWeight: weight, height: height, color: color);

  /// Nunito UI style for English text.
  static TextStyle en(double size,
          {FontWeight weight = FontWeight.w500, Color color = ink, double height = 1.4}) =>
      nunito(size, weight, color: color, height: height);

  /// Nunito is bundled as ONE variable font file, so the weight axis has to be
  /// set explicitly or every weight renders as Regular.
  static TextStyle nunito(double size, FontWeight weight,
          {Color color = ink, double height = 1.4}) =>
      TextStyle(
        fontFamily: bodyFont,
        fontSize: size,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
        height: height,
        color: color,
      );

  /// Nastaliq style for Urdu. Weight is ALWAYS 400; height >= 1.8.
  static TextStyle ur(double size, {Color color = ink, double height = 1.9}) => TextStyle(
        fontFamily: urduFont,
        fontSize: size < 20 ? 20 : size,
        fontWeight: FontWeight.w400,
        height: height < 1.8 ? 1.8 : height,
        color: color,
      );

  /// Small uppercase eyebrow (English).
  static TextStyle eyebrow({Color color = muted}) => en(12, weight: FontWeight.w800, color: color)
      .copyWith(letterSpacing: 1.2);
}

/// Background + foreground pair for tinted avatars and chips.
class AvatarTint {
  final Color bg;
  final Color fg;
  const AvatarTint(this.bg, this.fg);
}
