import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import 'join_family_screen.dart';

/// First-run choice: is this the elder's own device, or a family member's
/// phone contributing from afar? Sets the role for everything that follows.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YaadainTheme.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 28),
              const Text('🌿', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 14),
              Text('یادیں', style: YaadainTheme.serif(48, w: FontWeight.w600, h: 1.4)),
              const SizedBox(height: 6),
              const Text(
                'آپ کا خاندان، ہمیشہ آپ کے ساتھ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: YaadainTheme.foxed, height: 1.8),
              ),
              const SizedBox(height: 10),
              const _GoldRule(),
              const SizedBox(height: 22),
              Text(
                'WHO IS USING THIS PHONE?',
                style: YaadainTheme.eyebrow(size: 12),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoleCard(
                      icon: Icons.elderly_outlined,
                      color: YaadainTheme.primaryDark,
                      title: 'This is my elder’s phone',
                      subtitle: 'یہ میرے بزرگ کا فون ہے\nThe patient uses this device.',
                      onTap: () => _becomeElder(context),
                    ),
                    const SizedBox(height: 18),
                    _RoleCard(
                      icon: Icons.family_restroom_outlined,
                      color: YaadainTheme.accentDark,
                      title: 'I’m a family member',
                      subtitle: 'میں خاندان کا فرد ہوں\nContribute voices & photos from afar.',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const JoinFamilyScreen()),
                      ),
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

  Future<void> _becomeElder(BuildContext context) async {
    final app = context.read<AppState>();
    await app.becomeElderDevice();
    // Boot will now route to the elder home.
  }
}

class _GoldRule extends StatelessWidget {
  const _GoldRule();
  @override
  Widget build(BuildContext context) =>
      Container(width: 70, height: 1.4, color: YaadainTheme.leafRule.withOpacity(0.55));
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YaadainTheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.55)),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: YaadainTheme.serif(19, w: FontWeight.w600, h: 1.3)),
                    const SizedBox(height: 5),
                    Text(subtitle,
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: color, height: 1.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
