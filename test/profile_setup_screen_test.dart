import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_theme.dart';
import 'package:task_track/features/profile/domain/avatar_catalog.dart';
import 'package:task_track/features/profile/domain/profile.dart';
import 'package:task_track/features/profile/presentation/profile_identity_modal.dart';
import 'package:task_track/features/profile/presentation/profile_setup_screen.dart';
import 'package:task_track/features/profile/presentation/widgets/generated_avatar.dart';

void main() {
  test(
    'Google avatar choices contain account photo and nine generated avatars',
    () {
      final choices = AvatarCatalog.choices(hasAccountPhoto: true);

      expect(choices, hasLength(10));
      expect(choices.first, AvatarCatalog.accountPhotoId);
      expect(choices.where(AvatarCatalog.isGenerated), hasLength(9));
      expect(AvatarCatalog.choices(hasAccountPhoto: false), AvatarCatalog.ids);
    },
  );

  test(
    'legacy selected generated avatar remains available for Google users',
    () {
      final choices = AvatarCatalog.choices(
        hasAccountPhoto: true,
        selectedId: 'avatar_10',
      );

      expect(choices, contains('avatar_10'));
      expect(choices, hasLength(10));
    },
  );

  testWidgets('profile setup contains three fields and ten avatars', (
    WidgetTester tester,
  ) async {
    const profile = Profile(
      displayName: 'Budi',
      email: 'student@example.com',
      institution: '',
      major: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('id'),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const ProfileSetupScreen(initialProfile: profile),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byType(GeneratedAvatar), findsNWidgets(11));
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[0].validator?.call(''), 'Nama lengkap tidak boleh kosong');
    expect(fields[1].validator?.call(''), isNull);
    expect(fields[2].validator?.call(''), isNull);
    expect(find.text('Universitas / Institusi (Opsional)'), findsOneWidget);
    expect(find.text('Jurusan / Program Studi (Opsional)'), findsOneWidget);

    final logoutButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Keluar dari Akun'),
    );
    expect(
      logoutButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppPalette.dark.destructive,
    );
    for (final avatarId in AvatarCatalog.ids) {
      expect(find.byKey(ValueKey('avatar_$avatarId')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('avatar_avatar_10')));
    await tester.pumpAndSettle();

    final preview = tester.widget<GeneratedAvatar>(
      find.byType(GeneratedAvatar).first,
    );
    expect(preview.avatarId, 'avatar_10');
  });

  testWidgets('profile identity modal edits name and all avatar options', (
    WidgetTester tester,
  ) async {
    const profile = Profile(
      displayName: 'Budi',
      email: 'student@example.com',
      institution: '',
      major: '',
      avatarId: 'avatar_02',
      setupComplete: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('id'),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: ProfileIdentityModal(profile: profile)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.byType(GeneratedAvatar), findsNWidgets(11));
    for (final avatarId in AvatarCatalog.ids) {
      expect(find.byKey(ValueKey('edit_$avatarId')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('edit_avatar_08')));
    await tester.pumpAndSettle();

    final preview = tester.widget<GeneratedAvatar>(
      find.byType(GeneratedAvatar).first,
    );
    expect(preview.avatarId, 'avatar_08');
  });
}
