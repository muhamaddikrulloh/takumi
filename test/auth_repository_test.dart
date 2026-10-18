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

class _FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  _FakeGoogleSignInAccount({this.idToken = 'test-id-token'});

  final String? idToken;

  @override
  GoogleSignInAuthentication get authentication =>
      GoogleSignInAuthentication(idToken: idToken);
}

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  Object? signOutError;
  Object? authenticateError;
  GoogleSignInAccount? authenticateResult;
  bool signOutCalled = false;
  bool initializeCalled = false;

  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {
    initializeCalled = true;
  }

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const <String>[],
  }) async {
    final error = authenticateError;
    if (error != null) throw error;
    final result = authenticateResult;
    if (result != null) return result;
    throw const GoogleSignInException(
      code: GoogleSignInExceptionCode.canceled,
      description: 'User canceled sign-in',
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    final error = signOutError;
    if (error != null) throw error;
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

  test('Google sign-in passes ID token to Firebase credential', () async {
    final auth = _FakeFirebaseAuth();
    final google = _FakeGoogleSignIn()
      ..authenticateResult = _FakeGoogleSignInAccount(idToken: 'valid-token');
    final repository = AuthRepository(auth: auth, googleSignIn: google);

    await expectLater(
      repository.signInWithGoogle(),
      throwsA(isA<StateError>()),
    );
    expect(auth.credentialSignInCalled, isTrue);
  });

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
