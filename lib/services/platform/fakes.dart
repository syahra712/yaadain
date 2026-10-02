import 'dart:async';

import 'ports.dart';
import 'real.dart' show bearingDeg, haversineM;

/// No-op fakes for tests and the golden harness. They record what happened so
/// a test can assert on it.

class FakeAudio implements AudioPort {
  final List<String> played = [];
  bool recording = false;
  final StreamController<bool> _ctl = StreamController<bool>.broadcast();
  String? _current;

  @override
  Future<bool> hasMicPermission() async => true;

  @override
  Future<String?> startRecording() async {
    recording = true;
    return '/tmp/fake_rec.m4a';
  }

  @override
  Future<String?> stopRecording() async {
    recording = false;
    return '/tmp/fake_rec.m4a';
  }

  @override
  Future<void> play(String path) async {
    played.add(path);
    _current = path;
    _ctl.add(true);
  }

  @override
  Future<void> stop() async {
    _current = null;
    _ctl.add(false);
  }

  @override
  Stream<bool> get playing => _ctl.stream;
  @override
  String? get currentlyPlaying => _current;
}

class FakeLocation implements LocationPort {
  GeoFix? fix;
  bool granted;
  FakeLocation({this.fix, this.granted = true});

  @override
  Future<bool> ensurePermission() async => granted;
  @override
  Future<bool> hasPermission() async => granted;
  @override
  Future<GeoFix?> current() async => granted ? fix : null;
  @override
  double distanceBetween(double a, double b, double c, double d) => haversineM(a, b, c, d);
  @override
  double bearingBetween(double a, double b, double c, double d) => bearingDeg(a, b, c, d);
}

class FakeNotify implements NotifyPort {
  final List<(String, String)> shown = [];
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> show(String title, String body) async => shown.add((title, body));
}

class FakeLauncher implements LauncherPort {
  final List<String> calls = [];
  @override
  Future<bool> call(String phone) async {
    calls.add('tel:$phone');
    return true;
  }

  @override
  Future<bool> sms(String phone, {String? body}) async {
    calls.add('sms:$phone');
    return true;
  }

  @override
  Future<bool> openUrl(String url) async {
    calls.add(url);
    return true;
  }
}
