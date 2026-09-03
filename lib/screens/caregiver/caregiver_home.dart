import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/family_member.dart';
import '../../models/relationship.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/ui.dart';
import 'edit_member_screen.dart';
import 'elder_profile_screen.dart';
import 'if_found_card_screen.dart';
import 'invite_family_screen.dart';
import 'pattern_report_screen.dart';
import 'reactive_setup_screen.dart';
import 'safe_zone_screen.dart';

/// Setup surface, used by the family — plain English, dense, efficient.
class CaregiverHome extends StatelessWidget {
  const CaregiverHome({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final members = app.members;

    return Scaffold(
      backgroundColor: YaadainTheme.warmBg,
      appBar: AppBar(
        backgroundColor: YaadainTheme.warmBg,
        titleTextStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: YaadainTheme.ink,
        ),
        title: const Text('Family setup'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: YaadainTheme.ink,
        foregroundColor: YaadainTheme.warmBg,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EditMemberScreen()),
        ),
        icon: const Icon(Icons.person_add_alt, size: 20, color: YaadainTheme.warmBg),
        label: const Text('Add relative',
            style: TextStyle(fontWeight: FontWeight.w700, color: YaadainTheme.warmBg)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 96),
        children: [
          _StatusBar(app: app),
          const SizedBox(height: 26),
          const _GroupLabel('SETUP'),
          const SizedBox(height: 4),
          _SectionCard(
            icon: Icons.elderly_outlined,
            title: 'The elder',
            subtitle: app.elder.name.isEmpty ? 'Set name, photo & safe zone' : app.elder.name,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ElderProfileScreen()),
            ),
          ),
          _SectionCard(
            icon: Icons.hearing,
            title: 'Reactive companion',
            subtitle: app.elder.listeningEnabled
                ? 'Listening on — responds to confusion'
                : 'Off — tap to record a calming clip & enable',
            statusOn: app.elder.listeningEnabled,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReactiveSetupScreen()),
            ),
          ),
          _SectionCard(
            icon: Icons.insights_outlined,
            title: 'Weekly pattern report',
            subtitle: app.episodes.isEmpty
                ? 'Private summary of confusion moments'
                : '${app.episodes.length} moments logged',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PatternReportScreen()),
            ),
          ),
          _SectionCard(
            icon: Icons.location_on_outlined,
            title: 'Safe zone',
            subtitle: app.elder.hasSafeZone ? 'Set — alerts on leaving the area' : 'Not set',
            statusOn: app.elder.hasSafeZone,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SafeZoneScreen()),
            ),
          ),
          _SectionCard(
            icon: Icons.badge_outlined,
            title: '“If found” card',
            subtitle: 'Printable card for a stranger who finds the elder',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IfFoundCardScreen()),
            ),
          ),
          _SectionCard(
            icon: Icons.group_add_outlined,
            title: 'Invite family',
            subtitle: app.settings.familyCode == null
                ? 'Let relatives contribute from their phones'
                : 'Family code: ${app.settings.familyCode}',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InviteFamilyScreen()),
            ),
          ),
          _SectionCard(
            icon: Icons.swap_horiz,
            title: 'Switch device role',
            subtitle: 'Back to “elder / family member” selection',
            onTap: () => _switchRole(context),
          ),
          const SizedBox(height: 26),
          _GroupLabel('FAMILY · ${members.length}'),
          const SizedBox(height: 4),
          if (members.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: EmptyState(
                emoji: '👪',
                title: 'No relatives yet',
                subtitle: 'Tap “Add relative” to record their face and voice.',
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: YaadainTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: YaadainTheme.line),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < members.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: YaadainTheme.line),
                    _MemberRow(member: members[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final AppState app;
  const _StatusBar({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YaadainTheme.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(label: 'RELATIVES', value: '${app.members.length}'),
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.15)),
          Expanded(
            child: _Stat(
              label: 'COMPANION',
              value: app.elder.listeningEnabled ? 'ON' : 'OFF',
              accent: app.elder.listeningEnabled ? YaadainTheme.primary : Colors.white38,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.15)),
          Expanded(
            child: _Stat(
              label: 'SAFE ZONE',
              value: app.elder.hasSafeZone ? 'SET' : 'NONE',
              accent: app.elder.hasSafeZone ? YaadainTheme.primary : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _Stat({required this.label, required this.value, this.accent = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: accent)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: Colors.white54)),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: YaadainTheme.muted)),
      );
}

Future<void> _switchRole(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Switch device role?'),
      content: const Text(
        'This returns to the “Who is using this phone?” screen. Your family data '
        'stays safe and re-syncs from the cloud.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Switch')),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await context.read<AppState>().resetRole();
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }
}

class _MemberRow extends StatelessWidget {
  final FamilyMember member;
  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final rel = relationshipById(member.relationshipId);
    final bits = <String>[
      if (rel != null) rel.english,
      if (member.greetingAudioPath != null) '🎙 voice',
      if (member.stories.isNotEmpty) '${member.stories.length} stories',
      if (member.isDeceased) 'in memoriam',
    ];
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditMemberScreen(memberId: member.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            MemberAvatar(member: member, size: 44, showRing: false),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: YaadainTheme.ink)),
                  if (bits.isNotEmpty)
                    Text(bits.join(' · '),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: YaadainTheme.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: YaadainTheme.muted),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool? statusOn;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.statusOn,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YaadainTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: YaadainTheme.line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: YaadainTheme.ink.withOpacity(0.18)),
                ),
                child: Icon(icon, size: 21, color: YaadainTheme.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: YaadainTheme.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: YaadainTheme.muted)),
                  ],
                ),
              ),
              if (statusOn != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusOn! ? YaadainTheme.primary : YaadainTheme.line,
                  ),
                ),
              ],
              const Icon(Icons.chevron_right, size: 20, color: YaadainTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}
