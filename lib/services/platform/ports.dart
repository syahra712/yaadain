import 'dart:async';

/// Small interfaces over the plugins, so screens and state never touch a
/// platform channel directly and tests can swap in no-op fakes.

class GeoFix {
  final double lat;
  final double lng;
  const GeoFix(this.lat, this.lng);
}

abstract class AudioPort {
  Future<bool> hasMicPermission();

  /// Starts recording; returns the temp path being written, or null on failure.
  Future<String?> startRecording();

  /// Stops; returns the temp file path (null if nothing was recorded).
  Future<String?> stopRecording();

  Future<void> play(String path);
  Future<void> stop();

  /// Emits true while something plays, false when it ends/stops.
  Stream<bool> get playing;
  String? get currentlyPlaying;
}

abstract class LocationPort {
  /// Asks for location permission if needed (elder phone, during setup).
  /// Returns true when fine/coarse location is granted and services are on.
  Future<bool> ensurePermission();
  Future<bool> hasPermission();
  Future<GeoFix?> current();
  double distanceBetween(double lat1, double lng1, double lat2, double lng2);
  /// Initial bearing in degrees (0 = north, clockwise).
  double bearingBetween(double lat1, double lng1, double lat2, double lng2);
}

abstract class NotifyPort {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> show(String title, String body);
}

abstract class LauncherPort {
  /// Opens the dialer with [phone] pre-filled. Returns false if impossible.
  Future<bool> call(String phone);
  Future<bool> sms(String phone, {String? body});
  Future<bool> openUrl(String url);
}
