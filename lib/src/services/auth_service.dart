// =============================================================================
// AUTH SERVICE — The single source of truth for authentication.
//
// WHY A SERVICE?
// Instead of scattering Firebase.auth calls all over your screens,
// you centralize them in ONE class. This gives you:
//   1. Clean screens — the UI only calls authService.signIn(), doesn't know about Firebase
//   2. Easy swapping — if you ever switch from Firebase to another auth provider, 
//      you only change THIS file, not 20 screens
//   3. Testability — you can mock this service in unit tests
//
// PATTERN: This is called a "Service Layer" or "Repository Pattern"
// =============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // ── The single FirebaseAuth instance ──
  // We use a private field + constructor injection so tests can pass a mock.
  // In production, you call: AuthService() which uses the real FirebaseAuth.
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // ── GETTERS ──
  
  /// Returns the currently signed-in user, or null if signed out.
  /// This is how your UI checks "is someone logged in?"
  User? get currentUser => _auth.currentUser;

  /// A STREAM that fires every time auth state changes (login/logout).
  /// Your app can listen to this to automatically switch between
  /// the login screen and the dashboard.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── SIGN UP WITH EMAIL + PASSWORD ──
  /// Creates a new user account. Returns the User on success.
  /// Throws FirebaseAuthException on failure (weak password, email in use, etc.)
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    // createUserWithEmailAndPassword does 3 things:
    //   1. Creates the account in Firebase Auth
    //   2. Automatically signs the user in
    //   3. Returns a UserCredential containing the User object
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // If a display name was provided, update the user's profile
    // This is often "First Last" from your sign-up form
    if (displayName != null && credential.user != null) {
      await credential.user!.updateDisplayName(displayName);
      // Reload the user to get the updated profile
      await credential.user!.reload();
    }

    return _auth.currentUser; // Return the updated user
  }

  // ── SIGN IN WITH EMAIL + PASSWORD ──
  /// Signs in an existing user. Returns the User on success.
  /// Throws FirebaseAuthException if email/password is wrong.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  // ── GOOGLE SIGN-IN ──
  /// Opens the Google sign-in flow (popup on web, native dialog on mobile).
  /// Returns the User on success, null if the user cancelled.
  Future<User?> signInWithGoogle() async {
    // Step 1: Trigger the Google Sign-In flow
    // This shows the Google account picker
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    // User cancelled the sign-in
    if (googleUser == null) return null;

    // Step 2: Get the auth tokens from Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Step 3: Create a Firebase credential from the Google tokens
    // This is the "bridge" between Google's auth and Firebase's auth
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Step 4: Sign in to Firebase with the Google credential
    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  // ── SIGN OUT ──
  /// Signs the user out of both Firebase and Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
