import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_track/core/constants/app_theme.dart';
import 'package:task_track/core/providers/connectivity_provider.dart';
import 'package:task_track/core/providers/core_providers.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/home/presentation/home_screen.dart';
import 'package:task_track/features/home/providers/home_provider.dart';
import 'package:task_track/features/navigation/presentation/main_navigation_screen.dart';
import 'package:task_track/features/profile/domain/profile.dart';
import 'package:task_track/features/profile/presentation/profile_screen.dart';
import 'package:task_track/features/profile/presentation/widgets/generated_avatar.dart';
import 'package:task_track/features/profile/providers/profile_provider.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/providers/reminder_provider.dart';
import 'package:task_track/shared/widgets/bottom_nav_bar.dart';
import 'package:task_track/shared/widgets/glass_text_field.dart';

const _profile = Profile(
  displayName: 'Budi Santoso',
  email: 'budi@example.com',
  institution: 'Universitas Muhammadiyah Sukabumi',
  major: 'Teknik Informatika',
  avatarId: 'avatar_06',
  setupComplete: true,
);

class _StaticProfileNotifier extends ProfileNotifier {
  _StaticProfileNotifier(this.profile);

  final Profile profile;
  String? institutionWrite;
  String? majorWrite;

  @override
  Future<Profile> build() async => profile;

  @override
  Future<bool> updateInstitution(String value) async {
    institutionWrite = value;
    final current = state.valueOrNull ?? profile;
    state = AsyncData(current.copyWith(institution: value));
    return true;
  }

  @override
  Future<bool> updateMajor(String value) async {
    majorWrite = value;
    final current = state.valueOrNull ?? profile;
    state = AsyncData(current.copyWith(major: value));
    return true;
  }
}

class _PendingProfileNotifier extends _StaticProfileNotifier {
  _PendingProfileNotifier(super.profile);

  final institutionSave = Completer<bool>();
  final majorSave = Completer<bool>();

  @override
  Future<bool> updateInstitution(String value) {
    institutionWrite = value;
    final current = state.valueOrNull ?? profile;
    state = AsyncData(current.copyWith(institution: value));
    return institutionSave.future;
  }

  @override
  Future<bool> updateMajor(String value) {
    majorWrite = value;
    final current = state.valueOrNull ?? profile;
    state = AsyncData(current.copyWith(major: value));
    return majorSave.future;
  }
}

class _VerifiedUser extends Fake implements User {
  @override
  String get uid => 'user-id';

  @override
  bool get emailVerified => true;

  @override
  List<UserInfo> get providerData => const [];
}

Future<SharedPreferences> _preferences() async {
  SharedPreferences.setMockInitialValues({'locale': 'id'});
  return SharedPreferences.getInstance();
}

Future<_StaticProfileNotifier> _pumpProfileScreen(
  WidgetTester tester, {
  _StaticProfileNotifier? notifier,
}) async {
  final prefs = await _preferences();
  final profileNotifier = notifier ?? _StaticProfileNotifier(_profile);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authStateProvider.overrideWith((ref) => Stream.value(_VerifiedUser())),
        profileProvider.overrideWith(() => profileNotifier),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.darkTheme,
        home: const ProfileScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return profileNotifier;
}

Future<_StaticProfileNotifier> _pumpMainNavigation(WidgetTester tester) async {
  final prefs = await _preferences();
  final notifier = _StaticProfileNotifier(_profile);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authStateProvider.overrideWith((ref) => Stream.value(_VerifiedUser())),
        profileProvider.overrideWith(() => notifier),
        profileGateProvider.overrideWith((ref) async => _profile),
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
        belumTasksProvider.overrideWithValue(const AsyncData(0)),
        progressTasksProvider.overrideWithValue(const AsyncData(0)),
        completedTasksProvider.overrideWithValue(const AsyncData(0)),
        urgentTasksProvider.overrideWithValue(const AsyncData(<Task>[])),
        upcomingTasksProvider.overrideWithValue(const AsyncData(<Task>[])),
        remindersProvider.overrideWithValue(const AsyncData(<Task>[])),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.darkTheme,
        home: const MainNavigationScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

void main() {
  testWidgets('Profile screen displays persisted identity and academic data', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final institutionNotifier = await _pumpProfileScreen(tester);

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Universitas Muhammadiyah Sukabumi'), findsOneWidget);
    expect(find.text('Teknik Informatika'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit_profile_button')), findsNothing);
    final editTarget = find.byKey(const ValueKey('edit_profile_identity'));
    final editVisual = find.byKey(
      const ValueKey('edit_profile_identity_visual'),
    );
    expect(editTarget, findsOneWidget);
    expect(editVisual, findsOneWidget);
    expect(tester.getSize(editTarget), const Size.square(48));
    expect(tester.getSize(editVisual), const Size.square(30));
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: editVisual,
              matching: find.byIcon(PhosphorIconsBold.pencilSimple),
            ),
          )
          .size,
      14,
    );
    expect(find.byIcon(PhosphorIconsRegular.pencil), findsNothing);
    expect(find.byIcon(PhosphorIconsRegular.caretRight), findsNWidgets(2));

    final institutionRow = find.byKey(
      const ValueKey('academic_institution_row'),
    );
    final institutionValue = find.descendant(
      of: institutionRow,
      matching: find.text('Universitas Muhammadiyah Sukabumi'),
    );
    final institutionChevron = find.descendant(
      of: institutionRow,
      matching: find.byIcon(PhosphorIconsRegular.caretRight),
    );
    expect(
      find.descendant(of: institutionRow, matching: find.byType(InkWell)),
      findsOneWidget,
    );
    final institutionText = tester.widget<Text>(institutionValue);
    expect(institutionText.maxLines, 1);
    expect(institutionText.overflow, TextOverflow.ellipsis);
    expect(
      tester.getRect(institutionChevron).left -
          tester.getRect(institutionValue).right,
      greaterThanOrEqualTo(8),
    );
    expect(tester.takeException(), isNull);

    final avatar = tester.widget<GeneratedAvatar>(
      find.byType(GeneratedAvatar).first,
    );
    expect(avatar.avatarId, 'avatar_06');

    await tester.tap(institutionRow);
    await tester.pumpAndSettle();
    final institutionField = tester.widget<GlassTextField>(
      find.byType(GlassTextField),
    );
    expect(
      institutionField.controller?.text,
      'Universitas Muhammadiyah Sukabumi',
    );
    expect(institutionField.autofocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(find.byIcon(PhosphorIconsRegular.check), findsNothing);
    expect(find.byIcon(PhosphorIconsRegular.x), findsNothing);

    await tester.enterText(
      find.byType(TextFormField),
      'Institut Teknologi Bandung',
    );
    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();
    expect(institutionNotifier.institutionWrite, 'Institut Teknologi Bandung');
    expect(find.byType(GlassTextField), findsNothing);
    expect(find.text('Institut Teknologi Bandung'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);

    final majorNotifier = await _pumpProfileScreen(tester);
    final majorRow = find.byKey(const ValueKey('academic_major_row'));
    expect(
      find.descendant(of: majorRow, matching: find.byType(InkWell)),
      findsOneWidget,
    );
    await tester.tap(majorRow);
    await tester.pumpAndSettle();
    final majorField = tester.widget<GlassTextField>(
      find.byType(GlassTextField),
    );
    expect(majorField.controller?.text, 'Teknik Informatika');
    expect(majorField.autofocus, isTrue);
    await tester.enterText(find.byType(TextFormField), 'Ilmu Komputer');
    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();
    expect(majorNotifier.majorWrite, 'Ilmu Komputer');
    expect(find.byType(GlassTextField), findsNothing);
    expect(find.text('Ilmu Komputer'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home displays the shared profile name and motivation', (
    WidgetTester tester,
  ) async {
    final prefs = await _preferences();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          profileProvider.overrideWith(() => _StaticProfileNotifier(_profile)),
          profileGateProvider.overrideWith((ref) async => _profile),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          belumTasksProvider.overrideWithValue(const AsyncData(0)),
          progressTasksProvider.overrideWithValue(const AsyncData(0)),
          completedTasksProvider.overrideWithValue(const AsyncData(0)),
          urgentTasksProvider.overrideWithValue(const AsyncData(<Task>[])),
          upcomingTasksProvider.overrideWithValue(const AsyncData(<Task>[])),
          remindersProvider.overrideWithValue(const AsyncData(<Task>[])),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('id'),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Halo, Budi!'), findsOneWidget);
    expect(find.text('Semangat nugas hari ini!'), findsOneWidget);
    expect(
      find.text('Teknik Informatika | Universitas Muhammadiyah Sukabumi'),
      findsNothing,
    );
    final avatar = tester.widget<GeneratedAvatar>(
      find.byType(GeneratedAvatar).first,
    );
    expect(avatar.avatarId, 'avatar_06');
  });

  testWidgets('academic rows can re-enter edit mode while a save is pending', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 900);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final scenarios = [
      (
        rowKey: const ValueKey('academic_institution_row'),
        firstValue: 'Institut Teknologi Bandung',
        secondValue: 'Universitas Indonesia',
        institution: true,
      ),
      (
        rowKey: const ValueKey('academic_major_row'),
        firstValue: 'Ilmu Komputer',
        secondValue: 'Sistem Informasi',
        institution: false,
      ),
    ];

    for (final scenario in scenarios) {
      final notifier = _PendingProfileNotifier(_profile);
      await _pumpProfileScreen(tester, notifier: notifier);

      final rowFinder = find.byKey(scenario.rowKey);
      await tester.ensureVisible(rowFinder);
      await tester.tap(rowFinder);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), scenario.firstValue);
      await tester.tap(find.text('Budi Santoso'));
      await tester.pump();

      expect(find.byType(GlassTextField), findsNothing);
      await tester.tap(rowFinder);
      await tester.pumpAndSettle();
      expect(find.byType(GlassTextField), findsOneWidget);
      expect(tester.testTextInput.isVisible, isTrue);

      if (scenario.institution) {
        notifier.institutionSave.complete(true);
      } else {
        notifier.majorSave.complete(true);
      }
      await tester.pumpAndSettle();
      expect(find.byType(GlassTextField), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), scenario.secondValue);
      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();
      expect(find.byType(GlassTextField), findsNothing);

      await tester.tap(rowFinder);
      await tester.pumpAndSettle();
      expect(find.byType(GlassTextField), findsOneWidget);
      expect(
        scenario.institution ? notifier.institutionWrite : notifier.majorWrite,
        scenario.secondValue,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('keyboard overlays navbar while academic fields stay usable', (
    WidgetTester tester,
  ) async {
    final scenarios = [
      (
        size: const Size(360, 800),
        keyboardInset: 300.0,
        rowKey: const ValueKey('academic_institution_row'),
        value: 'Institut Teknologi Bandung',
        institution: true,
      ),
      (
        size: const Size(412, 915),
        keyboardInset: 340.0,
        rowKey: const ValueKey('academic_major_row'),
        value: 'Ilmu Komputer',
        institution: false,
      ),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
      tester.view.resetViewInsets();
    });

    for (final scenario in scenarios) {
      tester.view.physicalSize = scenario.size;
      tester.view.viewInsets = FakeViewPadding.zero;
      final notifier = await _pumpMainNavigation(tester);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Initial layout overflowed at ${scenario.size}',
      );

      await tester.tap(find.byKey(const ValueKey('home_profile_avatar')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Profile layout overflowed at ${scenario.size}',
      );

      final navFinder = find.byType(BottomNavBar);
      final closedNavRect = tester.getRect(navFinder);
      final rowFinder = find.byKey(scenario.rowKey);
      await tester.ensureVisible(rowFinder);
      await tester.tap(rowFinder);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Academic editor overflowed at ${scenario.size}',
      );

      tester.view.viewInsets = FakeViewPadding(bottom: scenario.keyboardInset);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Keyboard layout overflowed at ${scenario.size}',
      );

      final openNavRect = tester.getRect(navFinder);
      expect(openNavRect, closedNavRect);
      final keyboardTop = scenario.size.height - scenario.keyboardInset;
      expect(openNavRect.top, greaterThanOrEqualTo(keyboardTop));
      expect(
        tester.getRect(find.byType(TextFormField)).bottom,
        lessThanOrEqualTo(keyboardTop),
      );

      await tester.enterText(find.byType(TextFormField), scenario.value);
      await tester.tapAt(const Offset(8, 8));
      tester.view.viewInsets = FakeViewPadding.zero;
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      expect(tester.getRect(navFinder), closedNavRect);
      expect(find.byType(GlassTextField), findsNothing);
      expect(
        scenario.institution ? notifier.institutionWrite : notifier.majorWrite,
        scenario.value,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
