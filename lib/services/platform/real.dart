import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../audio_service.dart';
import '../notification_service.dart';
import 'ports.dart';

/// All real implementations construct their plugin objects lazily, so merely
/// importing them in a test never touches a platform channel.

class RealAudio implements AudioPort {
  StreamSubscription<PlayerState>? _sub;
  final StreamController<bool> _ctl = StreamController<bool>.broadcast();
  bool _wired = false;

  void _wire() {
    if (_wired) return;
    _wired = true;
    try {
      _sub = AudioService.instance.playerState.listen((s) => _ctl.add(s == PlayerState.playing));
    } catch (_) {}
  }

  @override
  Future<bool> hasMicPermission() async {
    try {
      return await AudioService.instance.hasMicPermission();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> startRecording() async {
    try {
      return await AudioService.instance.startRecording();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> stopRecording() async {
    try {
      return await AudioService.instance.stopRecording();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> play(String path) async {
    try {
      _wire();
      await AudioService.instance.play(path);
    } catch (_) {/* missing file: stay calm, no error UI */}
  }

  @override
  Future<void> stop() async {
    try {
      await AudioService.instance.stop();
    } catch (_) {}
  }

  @override
  Stream<bool> get playing {
    _wire();
    return _ctl.stream;
  }

  @override
  String? get currentlyPlaying => AudioService.instance.currentlyPlaying;

  void dispose() => _sub?.cancel();
}

class RealLocation implements LocationPort {
  @override
  Future<bool> hasPermission() async {
    try {
      final p = await Geolocator.checkPermission();
      return p == LocationPermission.always || p == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> ensurePermission() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return false;
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<GeoFix?> current() async {
    try {
      if (!await hasPermission()) return null;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      return GeoFix(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  double distanceBetween(double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);

  @override
  double bearingBetween(double lat1, double lng1, double lat2, double lng2) => bearingDeg(lat1, lng1, lat2, lng2);
}

/// Great-circle initial bearing in degrees, 0 = north, clockwise.
double bearingDeg(double lat1, double lng1, double lat2, double lng2) {
  final p1 = lat1 * math.pi / 180, p2 = lat2 * math.pi / 180;
  final dl = (lng2 - lng1) * math.pi / 180;
  final y = math.sin(dl) * math.cos(p2);
  final x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Haversine distance in metres (used by the demo source and the fakes).
double haversineM(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(a)));
}

class RealNotify implements NotifyPort {
  @override
  Future<void> init() async {
    try {
      await NotificationService.instance.init();
    } catch (_) {}
  }

  @override
  Future<bool> requestPermission() => NotificationService.instance.requestPermission();

  @override
  Future<void> show(String title, String body) async {
    try {
      await NotificationService.instance.showSafeZoneAlert(title, body);
    } catch (_) {}
  }
}

class RealLauncher implements LauncherPort {
  Future<bool> _go(Uri u) async {
    try {
      return await launchUrl(u, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> call(String phone) => _go(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));

  @override
  Future<bool> sms(String phone, {String? body}) =>
      _go(Uri(scheme: 'sms', path: phone.replaceAll(' ', ''), queryParameters: body == null ? null : {'body': body}));

  @override
  Future<bool> openUrl(String url) async {
    final u = Uri.tryParse(url);
    return u == null ? false : _go(u);
  }
}
