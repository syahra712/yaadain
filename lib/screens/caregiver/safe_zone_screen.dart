import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';

/// Safe zone = a home point + a radius. EVENT-BASED only: we compare the
/// current position to this circle to tell "inside" from "outside". We never
/// store a location history or continuously watch the elder — that deliberate
/// restraint is the difference between a safety aid and surveillance.
class SafeZoneScreen extends StatefulWidget {
  const SafeZoneScreen({super.key});

  @override
  State<SafeZoneScreen> createState() => _SafeZoneScreenState();
}

class _SafeZoneScreenState extends State<SafeZoneScreen> {
  String _status = '';
  bool _busy = false;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(text: context.read<AppState>().elder.homeAddress ?? '');
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _saveAddress() {
    final app = context.read<AppState>();
    app.elder.homeAddress = _address.text.trim().isEmpty ? null : _address.text.trim();
    app.saveElder();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved')));
  }

  Future<Position?> _currentPosition() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      setState(() => _status = 'Location permission is needed to set the safe zone.');
      return null;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _status = 'Please turn on location services.');
      return null;
    }
    return Geolocator.getCurrentPosition();
  }

  Future<void> _setHomeHere() async {
    final app = context.read<AppState>();
    setState(() => _busy = true);
    final pos = await _currentPosition();
    if (pos != null) {
      app.elder.homeLat = pos.latitude;
      app.elder.homeLng = pos.longitude;
      await app.saveElder();
      setState(() => _status = 'Safe zone centred on the current location.');
    }
    setState(() => _busy = false);
  }

  Future<void> _checkNow() async {
    final app = context.read<AppState>();
    if (!app.elder.hasSafeZone) {
      setState(() => _status = 'Set the home location first.');
      return;
    }
    setState(() => _busy = true);
    final pos = await _currentPosition();
    if (pos != null) {
      final d = Geolocator.distanceBetween(
        app.elder.homeLat!, app.elder.homeLng!, pos.latitude, pos.longitude);
      final inside = d <= app.elder.safeRadiusMeters;
      setState(() => _status = inside
          ? 'Inside the safe zone (${d.toStringAsFixed(0)} m from home).'
          : '⚠️ Outside the safe zone (${d.toStringAsFixed(0)} m from home). Family would be alerted.');
    }
    setState(() => _busy = false);
  }

  Future<void> _simulateLeaving() async {
    // Pushes a REAL alert doc — any family device with the app open will
    // get an actual local notification + banner, not just a local snackbar.
    // Useful to test the family-side path without walking outside the zone.
    final app = context.read<AppState>();
    await app.sync.pushSafeZoneAlert(
      outside: true,
      distanceMeters: app.elder.safeRadiusMeters + 150,
    );
    if (!mounted) return;
    setState(() => _status = app.sync.isConnected
        ? '⚠️ (Simulated) Alert sent — check a family device.'
        : '⚠️ (Simulated) Cloud not connected, so this stayed on this device only.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: YaadainTheme.danger,
        content: Text('Alert: elder has left the safe zone'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final elder = app.elder;

    return Scaffold(
      appBar: AppBar(title: const Text('Safe zone')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Normally a family member sets this remotely, from their own phone '
              '(Family home → Set up safe zone) — not the elder. Use the controls '
              'below only for testing on one device, or if no family member has '
              'set it up yet.',
              style: TextStyle(fontSize: 13, color: YaadainTheme.muted),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    elder.hasSafeZone
                        ? 'Home: ${elder.homeLat!.toStringAsFixed(5)}, ${elder.homeLng!.toStringAsFixed(5)}'
                        : 'Home location not set',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _setHomeHere,
                    style: FilledButton.styleFrom(backgroundColor: YaadainTheme.primary),
                    icon: const Icon(Icons.my_location),
                    label: const Text('Set home to current location'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Home address',
              helperText: 'Shown on the "If found" card',
              hintText: 'House 12, Street 4, DHA Phase 2, Karachi',
              alignLabelWithHint: true,
              suffixIcon: IconButton(icon: const Icon(Icons.check), onPressed: _saveAddress),
            ),
            onEditingComplete: _saveAddress,
          ),
          const SizedBox(height: 8),
          Text('Safe radius: ${elder.safeRadiusMeters.toStringAsFixed(0)} m',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            min: 50,
            max: 1000,
            divisions: 19,
            label: '${elder.safeRadiusMeters.toStringAsFixed(0)} m',
            value: elder.safeRadiusMeters.clamp(50, 1000),
            onChanged: (v) {
              elder.safeRadiusMeters = v;
              context.read<AppState>().saveElder();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _checkNow,
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Check now'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _simulateLeaving,
                  icon: const Icon(Icons.warning_amber),
                  label: const Text('Simulate leaving'),
                ),
              ),
            ],
          ),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_status, style: const TextStyle(fontSize: 16)),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Yaadain keeps only a home point and a radius — never a trail of where '
            'the elder has been. Alerts are event-based (on leaving), not live tracking.',
            style: TextStyle(color: YaadainTheme.muted),
          ),
        ],
      ),
    );
  }
}
