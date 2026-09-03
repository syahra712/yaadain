import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/family_member.dart';
import '../../models/relationship.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/ui.dart';
import '../caregiver/edit_member_screen.dart';
import 'safe_zone_setup_screen.dart';

/// What a remote family member sees: the family they're contributing to, and
/// the ability to add their own face + voice + relatives. Everything they add
/// syncs to the elder's device (once Firebase is connected).
class FamilyHome extends StatelessWidget {
  const FamilyHome({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final members = app.members;
    final code = app.settings.familyCode ?? '——————';
    final connected = app.sync.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yaadain — Family'),
        actions: [
          IconButton(
            tooltip: 'Leave / switch role',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLeave(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EditMemberScreen()),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Add / record'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (app.lastSafeZoneAlert != null && app.lastSafeZoneAlert!['outside'] == true) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: YaadainTheme.dangerSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: YaadainTheme.danger.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: YaadainTheme.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${app.elder.romanName ?? app.elder.name} may have left the safe zone '
                      '(${((app.lastSafeZoneAlert!['distanceMeters'] as num?)?.toStringAsFixed(0)) ?? '?'} m from home).',
                      style: const TextStyle(fontSize: 13.5, color: YaadainTheme.danger, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: YaadainTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: YaadainTheme.leafRule.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FAMILY CODE', style: YaadainTheme.eyebrow()),
                const SizedBox(height: 6),
                Text(code, style: YaadainTheme.serif(24, w: FontWeight.w600, h: 1.2)),
                const SizedBox(height: 10),
                Text(
                  app.settings.contributorName == null
                      ? 'Contributing to this family.'
                      : 'Contributing as ${app.settings.contributorName}.',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: YaadainTheme.foxed),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                        size: 17, color: connected ? YaadainTheme.primaryDark : YaadainTheme.foxed),
                    const SizedBox(width: 6),
                    Text(
                      connected ? 'Synced with the family' : 'Offline preview (cloud not connected yet)',
                      style: const TextStyle(fontSize: 13, color: YaadainTheme.foxed),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SafeZoneSetupScreen()),
            ),
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Set up safe zone (home + boundary)'),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('WHAT THE ELDER WILL SEE', style: YaadainTheme.eyebrow()),
          ),
          const SizedBox(height: 8),
          if (members.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: EmptyState(
                emoji: '🎙️',
                title: 'Nothing yet',
                subtitle: 'Tap “Add / record” to add a relative with their photo and voice — '
                    'it appears on the elder’s phone.',
              ),
            ),
          ...members.map((m) => _Row(member: m)),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Switch role?'),
        content: const Text('This returns to the role picker. Your contributions stay in the family.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Switch')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppState>().resetRole();
    }
  }
}

class _Row extends StatelessWidget {
  final FamilyMember member;
  const _Row({required this.member});

  @override
  Widget build(BuildContext context) {
    final rel = relationshipById(member.relationshipId);
    final bits = <String>[
      if (rel != null) rel.english,
      if (member.greetingAudioPath != null) '🎙 voice',
    ];
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditMemberScreen(memberId: member.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: YaadainTheme.leafRule.withOpacity(0.4), width: 1.6),
              ),
              child: MemberAvatar(member: member, size: 50, showRing: false),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: YaadainTheme.serif(17, w: FontWeight.w600)),
                  Text(bits.join(' · '),
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: YaadainTheme.foxed)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: YaadainTheme.foxed),
          ],
        ),
      ),
    );
  }
}
