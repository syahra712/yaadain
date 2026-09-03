import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/elder_scaffold.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/ui.dart';

/// Elder-initiated reassurance. Shows a familiar face and calm words, and a
/// big "call my family" button. Nothing here tracks the elder; it simply
/// helps them reach a person. (The geofence safety layer is caregiver-side.)
class ImSafeScreen extends StatelessWidget {
  const ImSafeScreen({super.key});

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = S(app.roman);
    final roman = app.roman;
    final contacts = app.repo.emergencyContacts();
    final first = contacts.isNotEmpty ? contacts.first : null;

    return ElderScaffold(
      title: s.imSafe,
      roman: roman,
      accent: YaadainTheme.accentDark,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: YaadainTheme.leafRule.withOpacity(0.5), width: 1.4),
              ),
              child: const Icon(Icons.spa_outlined, size: 30, color: YaadainTheme.primaryDark),
            ),
            const SizedBox(height: 20),
            Text(
              roman
                  ? 'Aap mehfooz hain.\nAap ka khandan aap se pyar karta hai.'
                  : 'آپ محفوظ ہیں۔\nآپ کا خاندان آپ سے پیار کرتا ہے۔',
              textAlign: TextAlign.center,
              style: YaadainTheme.serif(24, w: FontWeight.w600, h: 1.5),
            ),
            const SizedBox(height: 40),
            if (first != null) ...[
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: YaadainTheme.leafRule, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 5)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: MemberAvatar(member: first, size: 122, showRing: false),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: () => _call(first.phone!),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: YaadainTheme.accentDark.withOpacity(0.6)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 21),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.call, color: YaadainTheme.accentDark, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            roman
                                ? '${first.romanName ?? first.name} ko call kijiye'
                                : '${first.name} کو کال کریں',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: YaadainTheme.accentDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              EmptyState(
                emoji: '📞',
                title: roman ? 'Koi rabta number nahi' : 'کوئی رابطہ نمبر نہیں',
                subtitle: roman
                    ? 'Ghar wale kisi ka phone number add karein.'
                    : 'گھر والے کسی کا فون نمبر شامل کریں۔',
              ),
          ],
        ),
      ),
    );
  }
}
