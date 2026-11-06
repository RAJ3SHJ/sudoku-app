import 'package:firebase_auth/firebase_auth.dart';

/// Optional Google sign-in through Firebase Authentication.
///
/// The app never sees or stores a password: Google confirms who the player
/// is and Firebase hands the app a signed token.
///
/// [available] is false when Firebase is not set up yet (for example while
/// developing before running `flutterfire configure`). The game still works,
/// only sign-in is hidden.
class AuthService {
  AuthService({required this.available});

  final bool available;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => available ? _auth.currentUser : null;

  Stream<User?> userChanges() =>
      available ? _auth.authStateChanges() : Stream<User?>.value(null);

  GoogleAuthProvider _googleProvider() => GoogleAuthProvider()
    ..addScope('email')
    ..setCustomParameters({'prompt': 'select_account'});

  /// Opens Google's account picker. Returns null if the player cancels.
  Future<User?> signInWithGoogle() async {
    if (!available) return null;
    try {
      final cred = await _auth.signInWithProvider(_googleProvider());
      return cred.user;
    } on FirebaseAuthException catch (e) {
      // Closing the picker is not an error worth showing.
      if (e.code == 'web-context-canceled' || e.code == 'canceled') return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (available) await _auth.signOut();
  }

  /// Permanently deletes the Firebase account (required by Google Play for
  /// apps that let people create an account).
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      await user.reauthenticateWithProvider(_googleProvider());
      await user.delete();
    }
  }
}
