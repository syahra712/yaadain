import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/demo_seed.dart';
import '../../design/design.dart';
import '../../models/care.dart';
import '../../routes.dart';
import '../../services/platform/platform.dart';
import '../../state/app_state.dart';
import '../../util/en_format.dart';
import 'widgets/safety_family_common.dart';

/// Safe zones: the Home ring his phone watches, and the other places that
/// explain an exit ("left home for Masjid Noor, usual time").
class SafeZonesScreen extends StatefulWidget {
  const SafeZonesScreen({super.key});

  @override
  State<SafeZonesScreen> createState() => _SafeZonesScreenState();
}

class _SafeZonesScreenState extends State<SafeZonesScreen> {
  String? _id; // zone being edited
  double _radius = 150;
  bool _always = true;
  final _ruleCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  SafeZone? _draft; // a zone not yet saved
  bool _loadedFor = false;

  @override
  void dispose() {
    _ruleCtl.dispose();
    _nameCtl.dispose();
    super.dispose();
  }

  SafeZone? _current(AppState app) {
    if (_draft != null && _draft!.id == _id) return _draft;
    for (final z in app.zones) {
      if (z.id == _id) return z;
    }
    return null;
  }

  void _select(SafeZone z) {
    _id = z.id;
    _radius = z.radiusM.clamp(50, 1000).toDouble();
    _always =
        z.ruleEn.trim().isEmpty || z.ruleEn.trim().toLowerCase() == 'always';
    _ruleCtl.text = _always ? '' : z.ruleEn;
    _nameCtl.text = z.name;
  }

  Future<void> _add(AppState app) async {
    final fix = await Svc.location.current();
    final home = app.homePoint;
    final z = SafeZone(
      id: 'zone-${app.newId()}',
      name: 'New place',
      lat: fix?.lat ?? home.lat,
      lng: fix?.lng ?? home.lng,
      radiusM: 100,
      ruleEn: 'Always',
    );
    if (!mounted) return;
    setState(() {
      _draft = z;
      _select(z);
    });
  }

  Future<void> _save(AppState app, SafeZone z) async {
    final isHome = z.id == DemoIds.zoneHome || z.name.toLowerCase() == 'home';
    final name = isHome
        ? z.name
        : (_nameCtl.text.trim().isEmpty ? z.name : _nameCtl.text.trim());
    final rule = _always
        ? 'Always'
        : (_ruleCtl.text.trim().isEmpty ? 'Set hours' : _ruleCtl.text.trim());
    z
      ..name = name
      ..radiusM = _radius
      ..ruleEn = rule;
    await app.saveZone(z);
    if (!mounted) return;
    setState(() => _draft = null);
    safetyToast(context, '$name saved.');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final canEdit = app.isCaregiver;
    final zones = <SafeZone>[...app.zones, if (_draft != null) _draft!];
    if (!_loadedFor && zones.isNotEmpty) {
      _loadedFor = true;
      _select(app.homeZone ?? zones.first);
    }
    final cur = _current(app) ?? (zones.isEmpty ? null : zones.first);
    final home = app.homeZone;

    return FamilyScaffold(
      title: 'Safe zones',
      actions: [
        if (canEdit)
          Semantics(
            button: true,
            label: 'Add a zone',
            child: InkWell(
              borderRadius: YaadainTheme.radius20,
              onTap: () => _add(app),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                    color: YaadainTheme.surface,
                    borderRadius: YaadainTheme.radius20,
                    border: Border.all(color: YaadainTheme.line)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const YIcon(YI.plus,
                      size: 18,
                      color: YaadainTheme.primaryDark,
                      strokeWidth: 2.6),
                  const SizedBox(width: 8),
                  EnText('Add',
                      size: 15,
                      weight: FontWeight.w800,
                      color: YaadainTheme.primaryDark,
                      height: 1.0),
                ]),
              ),
            ),
          ),
      ],
      bottom: (canEdit && cur != null)
          ? SafetyButton.primary('Save',
              icon: YI.check,
              height: 56,
              fontSize: 17,
              onTap: () => _save(app, cur))
          : null,
      body: zones.isEmpty
          ? _Empty(canEdit: canEdit, onAdd: () => _add(app))
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 4),
              _ZoneList(
                  zones: zones,
                  selectedId: cur?.id,
                  canEdit: canEdit,
                  onSelect: (z) => setState(() => _select(z))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: YIcon(YI.shieldCheck,
                            size: 16,
                            color: YaadainTheme.muted,
                            strokeWidth: 2.2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: EnText(
                            'His phone watches the Home zone; other zones explain alerts, like “left home for Masjid Noor, usual time”.',
                            size: 13,
                            weight: FontWeight.w600,
                            color: YaadainTheme.muted,
                            height: 1.35),
                      ),
                    ]),
              ),
              const SizedBox(height: 16),
              if (cur != null)
                _Editor(
                  app: app,
                  zone: cur,
                  canEdit: canEdit,
                  radius: _radius,
                  always: _always,
                  ruleCtl: _ruleCtl,
                  nameCtl: _nameCtl,
                  onRadius: (v) => setState(() => _radius = v),
                  onAlways: (v) => setState(() => _always = v),
                  onRemove: cur.id == home?.id || _draft?.id == cur.id
                      ? null
                      : () async {
                          await app.removeZone(cur.id);
                          if (!mounted) return;
                          setState(() => _select(app.homeZone ??
                              (app.zones.isEmpty
                                  ? SafeZone(id: '', name: '', lat: 0, lng: 0)
                                  : app.zones.first)));
                        },
                ),
              const SizedBox(height: 12),
              _EscalationCard(app: app, zoneName: home?.name ?? 'Home'),
              const SizedBox(height: 16),
            ]),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool canEdit;
  final VoidCallback onAdd;
  const _Empty({required this.canEdit, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: YCard(
        radius: 24,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: YaadainTheme.primarySoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const YIcon(YI.home,
                  size: 24, color: YaadainTheme.primaryDark),
            ),
            const SizedBox(height: 14),
            EnText('No safe zones yet',
                size: 22, weight: FontWeight.w700, display: true),
            const SizedBox(height: 8),
            EnText(
                canEdit
                    ? 'Start with Home. His phone will tell you when he leaves it.'
                    : 'The person who looks after him has not set a safe zone yet.',
                size: 15,
                weight: FontWeight.w600,
                color: YaadainTheme.muted,
                height: 1.4),
            if (canEdit) ...[
              const SizedBox(height: 16),
              SafetyButton.primary('Add Home zone',
                  icon: YI.plus, onTap: onAdd),
            ],
          ]),
        ),
      ),
    );
  }
}

String _rule(String r) {
  if (r.isEmpty) return 'always';
  return (r.startsWith('Always') || r.startsWith('Around'))
      ? r[0].toLowerCase() + r.substring(1)
      : r;
}

class _ZoneList extends StatelessWidget {
  final List<SafeZone> zones;
  final String? selectedId;
  final bool canEdit;
  final ValueChanged<SafeZone> onSelect;
  const _ZoneList(
      {required this.zones,
      required this.selectedId,
      required this.canEdit,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final tints = [
      YaadainTheme.tintTeal,
      YaadainTheme.tintSage,
      YaadainTheme.tintGold,
      YaadainTheme.tintClay,
      YaadainTheme.tintPlum
    ];
    final kids = <Widget>[];
    for (var i = 0; i < zones.length; i++) {
      final z = zones[i];
      final on = z.id == selectedId;
      final isHome = z.id == DemoIds.zoneHome || z.name.toLowerCase() == 'home';
      final t = tints[i % tints.length];
      final icon = isHome
          ? YI.home
          : (z.name.toLowerCase().contains('house') ? YI.user : YI.mapPin);
      if (i > 0) kids.add(const Divider(height: 1, color: YaadainTheme.line));
      kids.add(Material(
        color: on ? YaadainTheme.primarySoft : YaadainTheme.surface,
        child: InkWell(
          onTap: () => onSelect(z),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: on ? Colors.transparent : t.bg,
                    shape: BoxShape.circle),
                alignment: Alignment.center,
                child: YIcon(icon,
                    size: 22,
                    color: on ? YaadainTheme.primaryDark : t.fg,
                    strokeWidth: 2.2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EnText(z.name,
                          size: 16, weight: FontWeight.w800, height: 1.25),
                      EnText(
                          '${EnFmt.distance(z.radiusM)} · ${_rule(z.ruleEn)}',
                          size: 13,
                          weight: FontWeight.w700,
                          color: YaadainTheme.muted,
                          height: 1.3),
                    ]),
              ),
              if (on && canEdit)
                SafetyPill('Editing',
                    icon: YI.pencil,
                    bg: Colors.white,
                    fg: YaadainTheme.primaryDark,
                    height: 36)
              else if (!on)
                const YIcon(YI.chevronRight,
                    size: 20, color: YaadainTheme.muted),
            ]),
          ),
        ),
      ));
    }
    return Container(
      decoration: BoxDecoration(
          color: YaadainTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: YaadainTheme.line)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: kids),
    );
  }
}

class _RingThumb extends SliderComponentShape {
  const _RingThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(30, 30);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final c = context.canvas;
    c.drawCircle(
        center + const Offset(0, 2),
        15,
        Paint()
          ..color = const Color(0x33124C3E)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    c.drawCircle(center, 15, Paint()..color = Colors.white);
    c.drawCircle(
        center,
        15,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = YaadainTheme.primary);
  }
}

class _Editor extends StatelessWidget {
  final AppState app;
  final SafeZone zone;
  final bool canEdit;
  final double radius;
  final bool always;
  final TextEditingController ruleCtl;
  final TextEditingController nameCtl;
  final ValueChanged<double> onRadius;
  final ValueChanged<bool> onAlways;
  final VoidCallback? onRemove;
  const _Editor(
      {required this.app,
      required this.zone,
      required this.canEdit,
      required this.radius,
      required this.always,
      required this.ruleCtl,
      required this.nameCtl,
      required this.onRadius,
      required this.onAlways,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isHome =
        zone.id == DemoIds.zoneHome || zone.name.toLowerCase() == 'home';
    final address = isHome ? app.elder.homeAddress : null;
    final hr = isHome
        ? 'He lives here, so being home is never an alert. Leaving is.'
        : 'Used to explain exits, not to raise them.';
    return YCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                  color: YaadainTheme.primarySoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: YIcon(isHome ? YI.home : YI.mapPin,
                  size: 26, color: YaadainTheme.primaryDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isHome && canEdit)
                      TextField(
                        controller: nameCtl,
                        style: YaadainTheme.display(22)
                            .copyWith(fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Name this place'),
                      )
                    else
                      EnText(zone.name,
                          size: 22,
                          weight: FontWeight.w700,
                          display: true,
                          height: 1.2),
                    if (address != null && address.isNotEmpty)
                      EnText(address,
                          size: 14,
                          weight: FontWeight.w700,
                          color: YaadainTheme.muted,
                          height: 1.35),
                  ]),
            ),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1, color: YaadainTheme.line),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            EnText('Radius', size: 16, weight: FontWeight.w800),
            EnText('${radius.round()} m',
                size: 22, weight: FontWeight.w700, display: true),
          ]),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 8,
              activeTrackColor: YaadainTheme.primary,
              inactiveTrackColor: YaadainTheme.line,
              disabledActiveTrackColor: YaadainTheme.primary,
              disabledInactiveTrackColor: YaadainTheme.line,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const _RingThumb(),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              min: 50,
              max: 1000,
              divisions: 38,
              value: radius.clamp(50, 1000).toDouble(),
              onChanged: canEdit ? onRadius : null,
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            EnText('50 m',
                size: 12, weight: FontWeight.w800, color: YaadainTheme.muted),
            EnText('1000 m',
                size: 12, weight: FontWeight.w800, color: YaadainTheme.muted),
          ]),
          const SizedBox(height: 10),
          EnText(
              'Set it just beyond his usual walks. A smaller radius means more false alerts.',
              size: 14,
              weight: FontWeight.w600,
              color: YaadainTheme.bodyDim,
              height: 1.4),
          const SizedBox(height: 16),
          const Divider(height: 1, color: YaadainTheme.line),
          const SizedBox(height: 16),
          EnText('Expected hours', size: 16, weight: FontWeight.w800),
          const SizedBox(height: 10),
          _Segmented(always: always, enabled: canEdit, onChanged: onAlways),
          if (!always) ...[
            const SizedBox(height: 10),
            TextField(
              controller: ruleCtl,
              enabled: canEdit,
              style: YaadainTheme.en(15, weight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'e.g. Sundays, or around prayer times',
                filled: true,
                fillColor: YaadainTheme.paper,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
          const SizedBox(height: 10),
          EnText(hr,
              size: 14,
              weight: FontWeight.w600,
              color: YaadainTheme.bodyDim,
              height: 1.4),
          if (isHome) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: YaadainTheme.line),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EnText('Night rule', size: 16, weight: FontWeight.w800),
                      const SizedBox(height: 2),
                      EnText('Any exit between Isha and Fajr is an emergency',
                          size: 14,
                          weight: FontWeight.w600,
                          color: YaadainTheme.bodyDim,
                          height: 1.35),
                    ]),
              ),
              const SizedBox(width: 12),
              Switch(
                value: app.care.nightRule,
                onChanged: canEdit ? (v) => app.setNightRule(v) : null,
                activeColor: Colors.white,
                activeTrackColor: YaadainTheme.primary,
                inactiveTrackColor: YaadainTheme.line,
                inactiveThumbColor: Colors.white,
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ]),
          ],
          if (onRemove != null && canEdit) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRemove,
                icon: const YIcon(YI.trash,
                    size: 18, color: YaadainTheme.accentDark),
                label: EnText('Remove this zone',
                    size: 14,
                    weight: FontWeight.w800,
                    color: YaadainTheme.accentDark),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final bool always;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _Segmented(
      {required this.always, required this.enabled, required this.onChanged});

  Widget _seg(String label, bool on, VoidCallback tap) => Expanded(
        child: GestureDetector(
          onTap: enabled ? tap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: on ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: on
                  ? const [
                      BoxShadow(
                          color: Color(0x1A2C2620),
                          blurRadius: 6,
                          offset: Offset(0, 2))
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: EnText(label,
                size: 15,
                weight: FontWeight.w800,
                color: on ? YaadainTheme.primaryDark : YaadainTheme.muted,
                height: 1.0),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: YaadainTheme.line.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        _seg('Always', always, () => onChanged(true)),
        _seg('Set hours', !always, () => onChanged(false)),
      ]),
    );
  }
}

class _EscalationCard extends StatelessWidget {
  final AppState app;
  final String zoneName;
  const _EscalationCard({required this.app, required this.zoneName});

  @override
  Widget build(BuildContext context) {
    final entries = app.circle.where((c) => c.escalationOrder < 99).toList()
      ..sort((a, b) => a.escalationOrder.compareTo(b.escalationOrder));
    final me = app.settings.contributorMemberId;
    final parts = <String>[];
    for (final c in entries) {
      final m = app.memberById(c.memberId);
      if (m == null || m.isDeceased) continue;
      final who = c.memberId == me ? 'You' : m.firstNameEn;
      parts.add(c.escalationOrder == 0 || parts.isEmpty
          ? '$who first'
          : '$who after ${c.escalateAfterMin} min');
    }
    return YCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).pushNamed(Routes.careCircle),
      child: SizedBox(
        width: double.infinity,
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                color: YaadainTheme.attentionSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const YIcon(YI.bell,
                size: 22, color: YaadainTheme.accentDark, strokeWidth: 2.2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EnText('When he leaves $zoneName',
                  size: 16, weight: FontWeight.w800),
              EnText(
                  parts.isEmpty
                      ? 'No one is set to be called yet.'
                      : parts.join(' · '),
                  size: 13,
                  weight: FontWeight.w700,
                  color: YaadainTheme.muted,
                  height: 1.35),
            ]),
          ),
          const YIcon(YI.chevronRight, size: 20, color: YaadainTheme.muted),
        ]),
      ),
    );
  }
}
