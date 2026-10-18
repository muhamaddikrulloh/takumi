import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      // Firebase may hide this result when email enumeration protection is on.
      if (error.code != 'user-not-found') rethrow;
    }
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_auth.currentUser != null) {
      throw StateError('Firebase session is still active after sign-out');
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google sign-out (and its underlying token revocation) can throw,
      // e.g. when the user signed in with email/password and has no active
      // Google session. Treat it as best-effort to avoid surfacing an error.
    }
  }

  static String getAuthErrorMessage(Object error) {
    if (error is! FirebaseAuthException) {
      return 'error_generic';
    }
    switch (error.code) {
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        return 'error_invalid_credential';
      case 'email-already-in-use':
        return 'error_email_in_use';
      case 'invalid-email':
        return 'error_email_invalid';
      case 'weak-password':
        return 'error_weak_password';
      case 'user-disabled':
        return 'error_user_disabled';
      case 'too-many-requests':
        return 'error_too_many_requests';
      case 'network-request-failed':
        return 'error_no_network';
      default:
        return 'error_generic';
    }
  }
}
