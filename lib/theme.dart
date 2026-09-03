import 'package:flutter/material.dart';

/// Yaadain design system.
///
/// Warm, South-Asian, unhurried. Cream grounds, teal-green primary, terracotta
/// accent. Latin text is set in Nunito (friendly, rounded); Urdu glyphs fall
/// back automatically to Noto Nastaliq Urdu (authentic, calligraphic) — which
/// needs generous line-height, applied throughout.
class YaadainTheme {
  // ---- palette -------------------------------------------------------------
  static const Color warmBg = Color(0xFFF7F1E7); // soft cream ground
  static const Color surface = Colors.white; // cards
  static const Color surfaceAlt = Color(0xFFF0E9DC); // subtle fills
  static const Color line = Color(0xFFE6DECF); // hairlines

  static const Color ink = Color(0xFF2C2620); // warm near-black
  static const Color muted = Color(0xFF7A6F62); // secondary text

  static const Color primary = Color(0xFF1F6F5C); // calm teal-green
  static const Color primaryDark = Color(0xFF124C3E);
  static const Color primarySoft = Color(0xFFDCEBE5);

  static const Color accent = Color(0xFFC7743A); // terracotta
  static const Color accentDark = Color(0xFF9E5626);
  static const Color accentSoft = Color(0xFFF6E3D3);

  static const Color gold = Color(0xFFB88A3E); // for "in memoriam" etc.
  static const Color danger = Color(0xFFB3402F);
  static const Color dangerSoft = Color(0xFFF6DDD7);

  // ---- heirloom (editorial keepsake surfaces) ------------------------------
  // A quieter register than the primary palette: aged paper, foxed ink, a
  // single gold leaf rule. Used for the memoir-style pages — the tree and the
  // home's frontispiece — so they read like a printed family record.
  static const Color paper = Color(0xFFF3EBDC); // slightly deeper than warmBg
  static const Color paperShade = Color(0xFFE9DFC9); // recessed panels
  static const Color foxed = Color(0xFF9A8B72); // faded caption ink
  static const Color leafRule = Color(0xFFB88A3E); // thin gold hairline (== gold)
  static const Color sepia = Color(0xFFA9998A); // in-memoriam ring

  // ---- tokens --------------------------------------------------------------
  static const double rSm = 14, rMd = 20, rLg = 28, rXl = 34;
  static const double sXs = 6, sSm = 10, sMd = 16, sLg = 24, sXl = 32;

  static const String display = 'Fraunces'; // editorial serif, headlines only
  static const List<String> _urduFallback = ['NastaliqUrdu'];

  /// A serif display line — the app's one recurring "voice", used sparingly
  /// for the single hero headline on a screen, never for body text.
  static TextStyle serif(double size, {FontWeight w = FontWeight.w600, Color? color, double h = 1.25, bool italic = false}) =>
      TextStyle(
        fontFamily: display,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        fontSize: size,
        fontWeight: w,
        color: color ?? ink,
        height: h,
        fontFamilyFallback: _urduFallback,
      );

  /// A small-caps-style label ("YOUR CHILDREN", "TODAY") — letter-spaced,
  /// muted, sets an editorial section apart without another colored box.
  static TextStyle eyebrow({Color? color, double size = 12.5}) => TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.2,
        color: color ?? foxed,
        fontFamilyFallback: _urduFallback,
      );

  static List<BoxShadow> softShadow = [
    BoxShadow(color: const Color(0xFF2C2620).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> lift(Color c) => [
        BoxShadow(color: c.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 10)),
      ];

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
        error: danger,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: paper,
      fontFamily: 'Nunito',
      fontFamilyFallback: _urduFallback,
    );

    // Urdu (Nastaliq) needs extra vertical room or it clips — generous heights.
    TextStyle t(double size, FontWeight w, {Color? color, double h = 1.55}) => TextStyle(
          fontSize: size,
          fontWeight: w,
          color: color ?? ink,
          height: h,
          fontFamilyFallback: _urduFallback,
        );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: serif(36, w: FontWeight.w600, h: 1.2),
        headlineMedium: serif(28, w: FontWeight.w600, h: 1.25),
        headlineSmall: serif(24, w: FontWeight.w600, h: 1.3),
        titleLarge: t(22, FontWeight.w700),
        titleMedium: t(18, FontWeight.w700),
        bodyLarge: t(18, FontWeight.w500),
        bodyMedium: t(16, FontWeight.w500, color: ink),
        labelLarge: t(16, FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: serif(21, w: FontWeight.w600),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
          side: BorderSide(color: leafRule.withOpacity(0.28)),
        ),
      ),
      dividerTheme: DividerThemeData(color: leafRule.withOpacity(0.3), thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm),
          borderSide: BorderSide(color: leafRule.withOpacity(0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm),
          borderSide: BorderSide(color: leafRule.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: foxed),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDark,
        contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
      ),
    );
  }
}
