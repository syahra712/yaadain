import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In for family devices — a real account instead of a typed
/// name, so an elder/caregiver can restrict who's allowed to join a family
/// (see AppSettings.authorizedEmails) to specific Google accounts.
///
/// Requires one-time setup in the Firebase console (enable the Google
/// provider under Authentication → Sign-in method, and register the app's
/// SHA-1/SHA-256 fingerprints under Project settings → your Android app) —
/// this class only fails gracefully (returns null) until that's done.
class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: const ['email']);

  /// Signs in with Google and upgrades the app's anonymous Firebase session
  /// to that account. Returns the signed-in email, or null if the user
  /// cancelled or sign-in isn't configured yet.
  static Future<GoogleSignInResult?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // user cancelled
      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final current = FirebaseAuth.instance.currentUser;
      try {
        if (current != null && current.isAnonymous) {
          await current.linkWithCredential(credential);
        } else {
          await FirebaseAuth.instance.signInWithCredential(credential);
        }
      } on FirebaseAuthException {
        // Already linked to a different account elsewhere — sign in fresh.
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      return GoogleSignInResult(
        email: account.email.trim().toLowerCase(),
        displayName: account.displayName,
      );
    } catch (_) {
      return null; // not configured / no network / user cancelled mid-flow
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {/* best-effort */}
  }
}

class GoogleSignInResult {
  final String email;
  final String? displayName;
  const GoogleSignInResult({required this.email, this.displayName});
}
