import 'fakes.dart';
import 'ports.dart';
import 'real.dart';

export 'fakes.dart';
export 'ports.dart';
export 'real.dart' show bearingDeg, haversineM;

/// Service locator for plugin wrappers.
///
///   Svc.audio.play(path);   Svc.location.ensurePermission();
///   Svc.notify.show(t, b);  Svc.launcher.call('0300 1234567');
///
/// Tests: call [Svc.useFakes] first (the golden harness does it).
class Svc {
  Svc._();

  static AudioPort audio = RealAudio();
  static LocationPort location = RealLocation();
  static NotifyPort notify = RealNotify();
  static LauncherPort launcher = RealLauncher();

  static void useFakes() {
    audio = FakeAudio();
    location = FakeLocation();
    notify = FakeNotify();
    launcher = FakeLauncher();
  }
}
