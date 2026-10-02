import 'dart:io';

import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../models/family_member.dart';
import '../../../services/platform/platform.dart';
import '../../../state/app_state.dart';
import '../../../util/en_format.dart';
import '../../../util/urdu_format.dart';

/// Big action button used by Madad / ImSafe / IfFound (Urdu or English).
/// Matches the boards: coloured fill with a soft shadow, or white outline.
class SafetyButton extends StatelessWidget {
  final String label;
  final String? sub;
  final YI icon;
  final Color bg;
  final Color fg;
  final double minHeight;
  final double fontSize;
  final double iconSize;
  final double gap;
  final bool outline;
  final bool english;
  final VoidCallback? onTap;

  const SafetyButton({
    super.key,
    required this.label,
    required this.icon,
    required this.bg,
    this.fg = Colors.white,
    this.sub,
    this.minHeight = 72,
    this.fontSize = 24,
    this.iconSize = 28,
    this.gap = 14,
    this.outline = false,
    this.english = false,
    this.onTap,
  });

  Color get _shadow => bg == YaadainTheme.accentDark
      ? const Color(0x479E5626)
      : const Color(0x381F6F5C);

  @override
  Widget build(BuildContext context) {
    final Widget text;
    if (english) {
      text = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            sub == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          EnText(label,
              size: fontSize,
              weight: FontWeight.w800,
              color: fg,
              height: 1.15,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (sub != null)
            EnText(sub!,
                size: fontSize - 4,
                weight: FontWeight.w700,
                color: fg.withOpacity(0.92),
                height: 1.15),
        ],
      );
    } else {
      text = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: sub == null ? 8 : 0),
            child: UrduText(label,
                size: fontSize, color: fg, height: sub == null ? 2.0 : 1.8),
          ),
          if (sub != null)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(sub!,
                  style: YaadainTheme.ur(fontSize - 4,
                      color: fg.withOpacity(0.9), height: 1.8)),
            ),
        ],
      );
    }
    return Semantics(
      button: true,
      label: sub == null ? label : '$label $sub',
      excludeSemantics: true,
      enabled: onTap != null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: YaadainTheme.radius20,
          boxShadow: outline
              ? null
              : [
                  BoxShadow(
                      color: _shadow,
                      blurRadius: 24,
                      offset: const Offset(0, 10))
                ],
        ),
        child: Material(
          color: bg,
          borderRadius: YaadainTheme.radius20,
          child: InkWell(
            borderRadius: YaadainTheme.radius20,
            onTap: onTap,
            child: Container(
              constraints: BoxConstraints(
                  minHeight: minHeight, minWidth: double.infinity),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: outline
                  ? BoxDecoration(
                      borderRadius: YaadainTheme.radius20,
                      border:
                          Border.all(color: YaadainTheme.stroke, width: 1.5))
                  : null,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: english ? TextDirection.ltr : TextDirection.rtl,
                children: [
                  YIcon(icon, size: iconSize, color: fg, strokeWidth: 2.1),
                  SizedBox(width: gap),
                  Flexible(child: text),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The elder-screen header with a 28 px title (the boards of the safety
/// screens use 28, not the default 36, so longer titles fit between the
/// two 80 px buttons).
class SafetyHeader extends StatelessWidget {
  final String title;
  const SafetyHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, inset + 8, 16, 0),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          ElderNavButton(
            label: 'واپس',
            icon: YI.arrowRight,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: UrduText(title,
                  size: 28,
                  height: 2.0,
                  align: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
          ElderNavButton(
            label: 'گھر',
            icon: YI.home,
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }
}

/// Face of a relative (photo if it exists, else the Urdu monogram at the
/// board size) with the soft double halo used on ImSafe.
class SafetyFace extends StatelessWidget {
  final FamilyMember? member;
  final double size;
  const SafetyFace({super.key, this.member, this.size = 160});

  bool _hasPhoto(String? p) {
    if (p == null || p.isEmpty) return false;
    try {
      return File(p).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = member;
    Widget face;
    if (m != null && _hasPhoto(m.photoPath)) {
      face = Avatar.member(m, size: size, urdu: true);
    } else {
      final tint = m?.avatarTint ?? YaadainTheme.tintTeal;
      face = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: tint.bg),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: m == null
              ? YIcon(YI.heart, size: 56, color: tint.fg)
              : Text(Avatar.monogramFor(m, urdu: true),
                  textDirection: TextDirection.rtl,
                  style: YaadainTheme.ur(48, color: tint.fg, height: 1.4)),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 5)]),
      child: ClipOval(child: face),
    );
  }
}

/// Number words for ETAs ("دس منٹ"); falls back to Urdu digits.
String urduMinutesWord(int n) {
  const w = {
    1: 'ایک',
    2: 'دو',
    3: 'تین',
    4: 'چار',
    5: 'پانچ',
    6: 'چھ',
    7: 'سات',
    8: 'آٹھ',
    9: 'نو',
    10: 'دس',
    12: 'بارہ',
    15: 'پندرہ',
    20: 'بیس',
    25: 'پچیس',
    30: 'تیس',
  };
  return w[n] ?? UrduFmt.digits(n);
}

/// Urdu rendering of the (English) home address; null when it cannot be
/// written faithfully in Urdu (callers then hide the line rather than mix
/// scripts). Already-Urdu addresses pass through.
String? urduAddress(String? en) {
  if (en == null) return null;
  final s = en.trim();
  if (s.isEmpty) return null;
  if (RegExp(r'[؀-ۿ]').hasMatch(s)) return UrduFmt.digits(s);
  const places = {
    'gulshan-e-iqbal': 'گلشنِ اقبال',
    'gulshan e iqbal': 'گلشنِ اقبال',
    'karachi': 'کراچی',
    'lahore': 'لاہور',
    'islamabad': 'اسلام آباد',
    'rawalpindi': 'راولپنڈی',
    'peshawar': 'پشاور',
    'quetta': 'کوئٹہ',
    'multan': 'ملتان',
    'faisalabad': 'فیصل آباد',
    'dha': 'ڈی ایچ اے',
    'clifton': 'کلفٹن',
    'nazimabad': 'ناظم آباد',
    'north nazimabad': 'نارتھ ناظم آباد',
    'gulberg': 'گلبرگ',
    'johar town': 'جوہر ٹاؤن',
    'model town': 'ماڈل ٹاؤن',
    'defence': 'ڈیفنس',
    'bahadurabad': 'بہادرآباد',
    'pechs': 'پی ای سی ایچ ایس',
  };
  final out = <String>[];
  for (final raw in s.split(',')) {
    final p = raw.trim();
    if (p.isEmpty) continue;
    final low = p.toLowerCase();
    final num = RegExp(
            r'^(house|flat|plot|street|block|phase|sector|apartment)\s*(?:no\.?|#)?\s*([0-9]+[a-z]?)$')
        .firstMatch(low);
    if (num != null) {
      final n = UrduFmt.digits(num.group(2)!);
      if (RegExp(r'[a-z]').hasMatch(num.group(2)!)) return null;
      const kinds = {
        'house': 'مکان نمبر',
        'flat': 'فلیٹ نمبر',
        'plot': 'پلاٹ نمبر',
        'street': 'گلی نمبر',
        'block': 'بلاک',
        'phase': 'فیز',
        'sector': 'سیکٹر',
        'apartment': 'اپارٹمنٹ نمبر',
      };
      out.add('${kinds[num.group(1)]} $n');
      continue;
    }
    final place = places[low];
    if (place == null) return null;
    out.add(place);
  }
  return out.isEmpty ? null : out.join('، ');
}

/// "Call" helper shared by the three screens.
Future<bool> dialMember(FamilyMember m) async {
  final phone = (m.phone ?? '').trim();
  if (phone.isEmpty) return false;
  try {
    return await Svc.launcher.call(EnFmt.telDigits(phone));
  } catch (_) {
    return false;
  }
}

/// Who a stranger / the elder should call, first and second.
class SafetyContacts {
  final FamilyMember? first;
  final FamilyMember? second;
  const SafetyContacts(this.first, this.second);

  factory SafetyContacts.of(AppState app) {
    bool callable(FamilyMember m) =>
        !m.isDeceased && (m.phone ?? '').trim().isNotEmpty;
    FamilyMember? first = app.primaryContact;
    if (first != null && !callable(first)) first = null;
    first ??= app.members.where(callable).firstOrNull;
    FamilyMember? second;
    final others =
        app.members.where((m) => callable(m) && m.id != first?.id).toList();
    for (final rel in const ['beti', 'beta']) {
      second ??= others.where((m) => m.relationshipId == rel).firstOrNull;
    }
    second ??= others.firstOrNull;
    return SafetyContacts(first, second);
  }
}

/// Elder identity for the if-found card. The profile stores only the family
/// nickname; the legal name and age are known for the demo family.
class SafetyIdentity {
  final String nameUr;
  final String nameEn;
  final bool formal; // true -> "صاحب" / "Mr" make sense
  final int? age;
  const SafetyIdentity(this.nameUr, this.nameEn, this.formal, this.age);

  factory SafetyIdentity.of(AppState app) {
    if (app.hasDemoData)
      return const SafetyIdentity('محمد اکرم', 'Muhammad Akram', true, 78);
    final e = app.elder;
    final fu = (e.fullNameUr ?? '').trim();
    final fe = (e.fullNameEn ?? '').trim();
    final known = fu.isNotEmpty || fe.isNotEmpty;
    return SafetyIdentity(fu.isNotEmpty ? fu : app.elderNameUr,
        fe.isNotEmpty ? fe : app.elderNameEn, known, e.ageYears);
  }
}

/// The simple person silhouette used when there is no photo.
class SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    final paint = Paint()..color = const Color(0x8C6E5420);
    canvas.drawCircle(Offset(50 * k, 38 * k), 20 * k, paint);
    final p = Path()
      ..moveTo(14 * k, 100 * k)
      ..cubicTo(16 * k, 78 * k, 30 * k, 64 * k, 50 * k, 64 * k)
      ..cubicTo(70 * k, 64 * k, 84 * k, 78 * k, 86 * k, 100 * k)
      ..close();
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 120 px rounded photo of the elder with the board's white + line ring.
class ElderPhotoTile extends StatelessWidget {
  final String? photoPath;
  const ElderPhotoTile({super.key, this.photoPath});

  @override
  Widget build(BuildContext context) {
    Widget inner =
        CustomPaint(size: const Size(120, 120), painter: SilhouettePainter());
    final p = photoPath;
    if (p != null && p.isNotEmpty) {
      var ok = false;
      try {
        ok = File(p).existsSync();
      } catch (_) {}
      if (ok) {
        inner = Image.file(File(p),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => inner);
      }
    }
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        borderRadius: YaadainTheme.radius28,
        color: Color(0xFFF1E6CC),
        boxShadow: [
          BoxShadow(color: YaadainTheme.line, spreadRadius: 4),
          BoxShadow(color: Colors.white, spreadRadius: 3),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: inner,
    );
  }
}
