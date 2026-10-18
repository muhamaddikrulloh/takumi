import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:task_track/features/auth/data/auth_repository.dart';

class _FakeUser extends Fake implements User {}

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? user;
  Object? resetError;
  bool keepSessionAfterSignOut = false;
  bool credentialSignInCalled = false;

  @override
  User? get currentUser => user;

  @override
  Future<void> signOut() async {
    if (!keepSessionAfterSignOut) user = null;
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    final error = resetError;
    if (error != null) throw error;
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    credentialSignInCalled = true;
    throw StateError('Unexpected credential sign-in');
  }
}

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  Object? signOutError;
  GoogleSignInAccount? signInResult;
  bool signOutCalled = false;

  @override
  Future<GoogleSignInAccount?> signIn() async => signInResult;

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOutCalled = true;
    final error = signOutError;
    if (error != null) throw error;
    return null;
  }
}

void main() {
  test('login errors do not distinguish unknown email from wrong password', () {
    for (final code in [
      'wrong-password',
      'user-not-found',
      'invalid-credential',
    ]) {
      expect(
        AuthRepository.getAuthErrorMessage(FirebaseAuthException(code: code)),
        'error_invalid_credential',
      );
    }
    expect(
      AuthRepository.getAuthErrorMessage(Exception('unexpected')),
      'error_generic',
    );
  });

  test('password reset keeps a missing account response neutral', () async {
    final auth = _FakeFirebaseAuth()
      ..resetError = FirebaseAuthException(code: 'user-not-found');
    final repository = AuthRepository(
      auth: auth,
      googleSignIn: _FakeGoogleSignIn(),
    );

    await expectLater(
      repository.sendPasswordResetEmail('missing@example.com'),
      completes,
    );
  });

  test('password reset rethrows operational failures', () async {
    final failure = FirebaseAuthException(code: 'network-request-failed');
    final auth = _FakeFirebaseAuth()..resetError = failure;
    final repository = AuthRepository(
      auth: auth,
      googleSignIn: _FakeGoogleSignIn(),
    );

    await expectLater(
      repository.sendPasswordResetEmail('student@example.com'),
      throwsA(same(failure)),
    );
  });

  test(
    'Google cancellation does not attempt Firebase credential sign-in',
    () async {
      final auth = _FakeFirebaseAuth();
      final repository = AuthRepository(
        auth: auth,
        googleSignIn: _FakeGoogleSignIn(),
      );

      expect(await repository.signInWithGoogle(), isNull);
      expect(auth.credentialSignInCalled, isFalse);
    },
  );

  test(
    'logout keeps Firebase sign-out successful if Google cleanup fails',
    () async {
      final auth = _FakeFirebaseAuth()..user = _FakeUser();
      final google = _FakeGoogleSignIn()
        ..signOutError = Exception('no session');
      final repository = AuthRepository(auth: auth, googleSignIn: google);

      await expectLater(repository.signOut(), completes);
      expect(auth.currentUser, isNull);
      expect(google.signOutCalled, isTrue);
    },
  );

  test('logout reports a Firebase session that remains active', () async {
    final auth = _FakeFirebaseAuth()
      ..user = _FakeUser()
      ..keepSessionAfterSignOut = true;
    final google = _FakeGoogleSignIn();
    final repository = AuthRepository(auth: auth, googleSignIn: google);

    await expectLater(repository.signOut(), throwsStateError);
    expect(google.signOutCalled, isFalse);
  });
}
