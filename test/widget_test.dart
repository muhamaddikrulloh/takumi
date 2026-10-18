import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_track/app.dart';
import 'package:task_track/core/providers/core_providers.dart';
import 'package:task_track/features/auth/data/auth_repository.dart';
import 'package:task_track/features/auth/data/password_reset_rate_limiter.dart';
import 'package:task_track/features/auth/presentation/login_screen.dart';
import 'package:task_track/features/auth/presentation/register_screen.dart';
import 'package:task_track/features/auth/presentation/reset_password_screen.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/profile/domain/profile.dart';
import 'package:task_track/features/profile/presentation/profile_setup_screen.dart';
import 'package:task_track/features/profile/providers/profile_provider.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

class _FakeFirebasePlatform extends FirebasePlatform {
  final Map<String, FirebaseAppPlatform> _apps = {};

  _FakeFirebasePlatform() {
    _apps.putIfAbsent(
      defaultFirebaseAppName,
      () => FirebaseAppPlatform(
        defaultFirebaseAppName,
        FirebaseOptions(
          apiKey: '',
          appId: 'test',
          messagingSenderId: '',
          projectId: 'test',
        ),
      ),
    );
  }

  @override
  List<FirebaseAppPlatform> get apps => _apps.values.toList();

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) =>
      _apps[name]!;

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    final appName = name ?? defaultFirebaseAppName;
    return _apps.putIfAbsent(
      appName,
      () => FirebaseAppPlatform(
        appName,
        options ??
            FirebaseOptions(
              apiKey: '',
              appId: 'test',
              messagingSenderId: '',
              projectId: 'test',
            ),
      ),
    );
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.user});

  final User? user;
  int passwordResetRequests = 0;
  String? passwordResetEmail;
  Object? passwordResetError;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(user);

  @override
  User? get currentUser => user;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    passwordResetRequests++;
    passwordResetEmail = email;
    final error = passwordResetError;
    if (error != null) throw error;
  }
}

class _FakeVerifiedUser extends Fake implements User {
  @override
  String get uid => 'verified-user';

  @override
  bool get emailVerified => true;
}

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Widget _app(
  SharedPreferences prefs, {
  _FakeAuthRepository? authRepository,
  Profile? gateProfile,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(
        authRepository ?? _FakeAuthRepository(),
      ),
      if (gateProfile != null)
        profileGateProvider.overrideWith((ref) async => gateProfile),
    ],
    child: const App(),
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = _FakeFirebasePlatform();

  setUp(() {
    binding.platformDispatcher.localeTestValue = const Locale('id');
  });

  tearDown(binding.platformDispatcher.clearLocaleTestValue);

  testWidgets('App renders login screen for unauthenticated user', (
    WidgetTester tester,
  ) async {
    final prefs = await _prefs({});
    await tester.pumpWidget(_app(prefs));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('App always uses the dark theme', (WidgetTester tester) async {
    final prefs = await _prefs({});
    await tester.pumpWidget(_app(prefs));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.brightness, Brightness.dark);
    expect(materialApp.darkTheme, isNull);
    expect(
      Theme.of(tester.element(find.byType(LoginScreen))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('Persisted English locale is applied', (
    WidgetTester tester,
  ) async {
    final prefs = await _prefs({'locale': 'en'});
    await tester.pumpWidget(_app(prefs));
    await tester.pumpAndSettle();

    expect(find.textContaining('Manage your tasks easily'), findsOneWidget);
    expect(find.textContaining('Kelola seluruh tugasmu'), findsNothing);
  });

  testWidgets('Device locale is used when no locale is stored', (
    WidgetTester tester,
  ) async {
    binding.platformDispatcher.localeTestValue = const Locale('en');
    final prefs = await _prefs({});
    await tester.pumpWidget(_app(prefs));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale, const Locale('en'));
    expect(find.textContaining('Manage your tasks easily'), findsOneWidget);
  });

  testWidgets('Registration only asks for email and passwords', (
    WidgetTester tester,
  ) async {
    final prefs = await _prefs({});
    await tester.pumpWidget(_app(prefs));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Daftar di sini'));
    await tester.tap(find.text('Daftar di sini'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Nama Lengkap'), findsNothing);
  });

  testWidgets('Verified user with incomplete profile opens setup screen', (
    WidgetTester tester,
  ) async {
    final prefs = await _prefs({});
    const profile = Profile(
      displayName: '',
      email: 'student@example.com',
      institution: '',
      major: '',
    );
    await tester.pumpWidget(
      _app(
        prefs,
        authRepository: _FakeAuthRepository(user: _FakeVerifiedUser()),
        gateProfile: profile,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
  });

  testWidgets('Password reset shows resend link then starts cooldown', (
    WidgetTester tester,
  ) async {
    final prefs = await _prefs({});
    final authRepository = _FakeAuthRepository();
    await tester.pumpWidget(_app(prefs, authRepository: authRepository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'student@example.com',
    );
    await tester.ensureVisible(find.text('Lupa password?'));
    await tester.tap(find.text('Lupa password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('student@example.com'), findsOneWidget);
    expect(find.text('Tidak menerima tautan? Kirim ulang'), findsNothing);

    await tester.tap(find.widgetWithText(NeonButton, 'Reset Password'));
    await tester.pumpAndSettle();

    expect(authRepository.passwordResetRequests, 1);
    expect(authRepository.passwordResetEmail, 'student@example.com');
    expect(find.text('Tidak menerima tautan? Kirim ulang'), findsOneWidget);
    expect(find.textContaining('Kirim ulang (dalam'), findsNothing);
    expect(
      tester.widget<NeonButton>(find.byType(NeonButton).first).onPressed,
      isNull,
    );

    await tester.tap(find.text('Tidak menerima tautan? Kirim ulang'));
    await tester.pumpAndSettle();

    expect(authRepository.passwordResetRequests, 2);
    expect(find.text('Kirim ulang (dalam 01:00)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NeonButton, 'Kembali ke Login'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ResetPasswordScreen), findsNothing);
  });

  testWidgets('Password reset keeps unregistered email response neutral', (
    WidgetTester tester,
  ) async {
    final prefs = await _prefs({});
    final authRepository = _FakeAuthRepository()
      ..passwordResetError = FirebaseAuthException(code: 'user-not-found');
    await tester.pumpWidget(_app(prefs, authRepository: authRepository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Lupa password?'));
    await tester.tap(find.text('Lupa password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'unknown@example.com');
    await tester.tap(find.widgetWithText(NeonButton, 'Reset Password'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text('Jika email terdaftar, tautan reset password akan dikirim.'),
      findsOneWidget,
    );
    expect(find.text('Tidak menerima tautan? Kirim ulang'), findsOneWidget);
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
  });

  testWidgets('Initial reset limit persists when reset screen is reopened', (
    WidgetTester tester,
  ) async {
    final prefs = await _prefs({});
    final limiter = PasswordResetRateLimiter(prefs);
    for (var attempt = 0; attempt < 5; attempt++) {
      final result = await limiter.tryAcquireInitial('student@example.com');
      expect(result.allowed, isTrue);
    }

    final authRepository = _FakeAuthRepository();
    await tester.pumpWidget(_app(prefs, authRepository: authRepository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'student@example.com',
    );
    await tester.ensureVisible(find.text('Lupa password?'));
    await tester.tap(find.text('Lupa password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NeonButton, 'Reset Password'));
    await tester.pumpAndSettle();

    expect(authRepository.passwordResetRequests, 0);
    expect(
      find.textContaining(
        'Maksimal 5 permintaan reset untuk email yang sama dalam 1 jam.',
      ),
      findsOneWidget,
    );
  });
}
