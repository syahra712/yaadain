/// Build-time switches. Nothing here touches Firebase configuration.
library;

/// Where "where is he?" data comes from.
///  - demo: a scripted local simulation (default; the whole story runs offline
///    on one phone).
///  - firestore: merge-sets small fields on the existing `families/{CODE}` doc.
///    Compiled and wired, but OFF until flipped (see FIREBASE_SYNC.md).
enum TrackingBackend { demo, firestore }

const String _kTrackingDefine = String.fromEnvironment('YAADAIN_TRACKING', defaultValue: 'demo');

/// The one line to flip: change `demo` to `firestore`, or build with
/// `--dart-define=YAADAIN_TRACKING=firestore`.
const TrackingBackend kTrackingBackend =
    _kTrackingDefine == 'firestore' ? TrackingBackend.firestore : TrackingBackend.demo;

/// True when family screens should show the small "Demo" chip (English only).
const bool kTrackingIsDemo = kTrackingBackend == TrackingBackend.demo;

/// Locked-settings PIN on the elder phone (long-press the logo 3 s).
const String kSettingsPin = '1947';

/// The family-code prefix shown to people ("YD-7F3K"); stored without it.
const String kFamilyCodePrefix = 'YD-';
