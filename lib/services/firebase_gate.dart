/// Single source of truth for "is the cloud usable on this build?".
///
/// Set once by `main()` after Firebase initialises with a real configuration.
/// It stays false when the config is missing, is the local-build placeholder,
/// or initialisation fails, so the app runs fully offline and nothing waits on
/// the network.
class FirebaseGate {
  FirebaseGate._();

  /// True only when Firebase initialised with a non-placeholder config.
  static bool available = false;

  /// True when [apiKey] / [projectId] look like the fake values used for local
  /// builds (see FIREBASE_SYNC.md).
  static bool isPlaceholder(String apiKey, String projectId) {
    final k = apiKey.toLowerCase();
    final p = projectId.toLowerCase();
    return k.isEmpty ||
        k.startsWith('placeholder') ||
        k.startsWith('replace_with') ||
        p.isEmpty ||
        p.startsWith('placeholder') ||
        p == 'your-firebase-project-id';
  }
}
