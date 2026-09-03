import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';

/// Family device: the elder's safe zone (home point + radius) is set HERE,
/// by a family member — not by the elder, who has dementia and shouldn't be
/// the one configuring their own boundary. Whoever is physically at the
/// elder's home taps "set the pin here" once; it then applies to the
/// elder's phone automatically. Event-based only — Yaadain never stores a
/// location trail, only this one circle.
class SafeZoneSetupScreen extends StatefulWidget {
  const SafeZoneSetupScreen({super.key});

  @override
  State<SafeZoneSetupScreen> createState() => _SafeZoneSetupScreenState();
}

class _SafeZoneSetupScreenState extends State<SafeZoneSetupScreen> {
  final _address = TextEditingController();
  double _radius = 300;
  double? _lat;
  double? _lng;
  bool _loading = true;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cfg = await context.read<AppState>().sync.fetchSafeZoneConfig();
    if (!mounted) return;
    setState(() {
      if (cfg != null) {
        _lat = (cfg['lat'] as num?)?.toDouble();
        _lng = (cfg['lng'] as num?)?.toDouble();
        _radius = (cfg['radiusMeters'] as num?)?.toDouble() ?? 300;
        _address.text = (cfg['address'] as String?) ?? '';
      }
      _loading = false;
    });
  }

  Future<void> _usePinHere() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      setState(() {
        _busy = false;
        _status = 'Location permission is needed to set the pin.';
      });
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() {
        _busy = false;
        _status = 'Please turn on location services.';
      });
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _busy = false;
      _status = 'Pin set from your current location.';
    });
  }

  Future<void> _save() async {
    if (_lat == null || _lng == null) {
      setState(() => _status = 'Tip: you need to be at their home to tap "Set the pin here" first.');
      return;
    }
    setState(() => _busy = true);
    await context.read<AppState>().sync.pushSafeZoneConfig(
          lat: _lat!,
          lng: _lng!,
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          radiusMeters: _radius,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = 'Saved — this applies on their phone automatically.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe zone')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Set this once, from their home — Yaadain will let you know if they '
                  'wander outside this circle. Only a circle is stored, never a trail of '
                  'where they go.',
                  style: TextStyle(color: YaadainTheme.muted),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _lat != null
                              ? 'Pin: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                              : 'No pin set yet',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _busy ? null : _usePinHere,
                          style: FilledButton.styleFrom(backgroundColor: YaadainTheme.primary),
                          icon: const Icon(Icons.my_location),
                          label: const Text('Set the pin here (you must be at their home)'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Home address',
                    helperText: 'Shown to anyone who scans their QR card',
                    hintText: 'House 12, Street 4, DHA Phase 2, Karachi',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Safe radius: ${_radius.toStringAsFixed(0)} m',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Slider(
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  label: '${_radius.toStringAsFixed(0)} m',
                  value: _radius.clamp(50, 1000),
                  onChanged: (v) => setState(() => _radius = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: YaadainTheme.accentDark),
                    child: _busy
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_status!, style: const TextStyle(fontSize: 15)),
                  ),
                ],
              ],
            ),
    );
  }
}
