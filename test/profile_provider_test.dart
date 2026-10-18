import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/core/providers/connectivity_provider.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/profile/data/profile_repository.dart';
import 'package:task_track/features/profile/domain/profile.dart';
import 'package:task_track/features/profile/providers/profile_provider.dart';

const _initialProfile = Profile(
  displayName: 'Student',
  email: 'student@example.com',
  institution: 'Old institution',
  major: 'Old major',
);

class _FakeUser extends Fake implements User {
  _FakeUser([this.id = 'user-id']);

  final String id;

  @override
  String get uid => id;

  @override
  bool get emailVerified => true;
}

class _ControlledProfileRepository implements ProfileRepository {
  final profileCompleter = Completer<Profile>();
  final institutionCompleter = Completer<void>();
  final setupCompleter = Completer<void>();
  Profile? persistedProfile;
  String? institutionWrite;
  String? setupDisplayName;
  String? setupExpectedUid;
  String? setupInstitution;
  String? setupMajor;
  String? setupAvatarId;
  String? identityDisplayName;
  String? identityExpectedUid;
  String? identityAvatarId;
  int gateReads = 0;
  String? currentUid = 'user-id';

  @override
  String? get currentVerifiedUid => currentUid;

  @override
  Profile profileFromAuth() => _initialProfile;

  @override
  Future<Profile> getProfileForSetupGate() {
    gateReads++;
    final persisted = persistedProfile;
    return persisted == null
        ? profileCompleter.future
        : Future.value(persisted);
  }

  @override
  Future<void> completeSetup({
    required String expectedUid,
    required String displayName,
    required String institution,
    required String major,
    required String avatarId,
  }) async {
    setupExpectedUid = expectedUid;
    setupDisplayName = displayName;
    setupInstitution = institution;
    setupMajor = major;
    setupAvatarId = avatarId;
    await setupCompleter.future;
    persistedProfile = Profile(
      displayName: displayName,
      email: _initialProfile.email,
      institution: institution,
      major: major,
      avatarId: avatarId,
      setupComplete: true,
    );
  }

  @override
  Future<void> updateInstitution({
    required String expectedUid,
    required String value,
  }) {
    institutionWrite = value;
    return institutionCompleter.future;
  }

  @override
  Future<void> updateIdentity({
    required String expectedUid,
    required String displayName,
    required String avatarId,
  }) async {
    identityExpectedUid = expectedUid;
    identityDisplayName = displayName;
    identityAvatarId = avatarId;
    persistedProfile = (persistedProfile ?? _initialProfile).copyWith(
      displayName: displayName,
      avatarId: avatarId,
    );
  }

  @override
  Future<void> updateMajor({
    required String expectedUid,
    required String value,
  }) => throw UnimplementedError();
}

void main() {
  test(
    'profile update awaits failure, rolls back, and returns false',
    () async {
      final repository = _ControlledProfileRepository();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      repository.profileCompleter.complete(_initialProfile);
      container.invalidate(profileProvider);
      await container.read(profileProvider.future);

      final mutation = container
          .read(profileProvider.notifier)
          .updateInstitution(' New institution ');

      expect(repository.institutionWrite, 'New institution');
      expect(
        container.read(profileProvider).requireValue.institution,
        'New institution',
      );

      repository.institutionCompleter.completeError(Exception('write failed'));
      expect(await mutation, isFalse);
      expect(
        container.read(profileProvider).requireValue.institution,
        'Old institution',
      );
    },
  );

  test(
    'profile setup persists all required fields and selected avatar',
    () async {
      final repository = _ControlledProfileRepository();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      repository.profileCompleter.complete(_initialProfile);
      container.invalidate(profileProvider);
      await container.read(profileProvider.future);

      final mutation = container
          .read(profileProvider.notifier)
          .completeSetup(
            displayName: ' Budi ',
            institution: ' Example University ',
            major: ' Informatika ',
            avatarId: 'avatar_04',
          );
      await Future<void>.delayed(Duration.zero);

      expect(repository.setupDisplayName, 'Budi');
      expect(repository.setupInstitution, 'Example University');
      expect(repository.setupMajor, 'Informatika');
      expect(repository.setupAvatarId, 'avatar_04');
      expect(
        container.read(profileProvider).requireValue.setupComplete,
        isTrue,
      );
      expect(
        container.read(profileProvider).requireValue.avatarId,
        'avatar_04',
      );

      repository.setupCompleter.complete();
      expect(await mutation, isTrue);
    },
  );

  test(
    'setup does not wait for provider initialization and keeps submitted data',
    () async {
      final repository = _ControlledProfileRepository();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final mutation = container
          .read(profileProvider.notifier)
          .completeSetup(
            displayName: 'Ayu',
            institution: '',
            major: '',
            avatarId: 'avatar_07',
          );

      await Future<void>.delayed(Duration.zero);
      expect(repository.setupDisplayName, 'Ayu');
      expect(repository.setupExpectedUid, 'user-id');
      expect(repository.setupInstitution, '');
      expect(repository.setupMajor, '');

      repository.setupCompleter.complete();
      expect(await mutation, isTrue);

      repository.profileCompleter.complete(_initialProfile);
      final profile = container.read(profileProvider).requireValue;
      expect(profile.displayName, 'Ayu');
      expect(profile.institution, '');
      expect(profile.major, '');
      expect(profile.avatarId, 'avatar_07');
      expect(profile.setupComplete, isTrue);
    },
  );

  test(
    'identity update changes name and avatar in shared profile state',
    () async {
      final repository = _ControlledProfileRepository();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      repository.profileCompleter.complete(_initialProfile);
      await container.read(profileProvider.future);

      final saved = await container
          .read(profileProvider.notifier)
          .updateIdentity(displayName: ' Sinta ', avatarId: 'avatar_09');

      expect(saved, isTrue);
      expect(repository.identityDisplayName, 'Sinta');
      expect(repository.identityAvatarId, 'avatar_09');
      expect(container.read(profileProvider).requireValue.displayName, 'Sinta');
      expect(
        container.read(profileProvider).requireValue.avatarId,
        'avatar_09',
      );
    },
  );

  test('newly registered user skips the remote profile gate lookup', () async {
    final repository = _ControlledProfileRepository();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);
    container.read(newlyRegisteredUidProvider.notifier).state = 'user-id';

    final profile = await container.read(profileGateProvider.future);

    expect(profile, same(_initialProfile));
    expect(repository.gateReads, 0);
  });

  test(
    'profile setup aborts when the authenticated account changes while loading',
    () async {
      final repository = _ControlledProfileRepository();
      final authController = StreamController<User?>();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => authController.stream),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await authController.close();
      });

      repository.currentUid = 'user-a';
      authController.add(_FakeUser('user-a'));
      await container.read(authStateProvider.future);

      final mutation = container
          .read(profileProvider.notifier)
          .completeSetup(
            displayName: 'User A',
            institution: '',
            major: '',
            avatarId: 'avatar_01',
          );
      await Future<void>.delayed(Duration.zero);
      expect(repository.setupDisplayName, 'User A');
      expect(repository.setupExpectedUid, 'user-a');

      repository.currentUid = 'user-b';
      authController.add(_FakeUser('user-b'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authStateProvider).requireValue!.uid, 'user-b');

      repository.setupCompleter.complete();
      expect(await mutation, isFalse);

      repository.profileCompleter.complete(_initialProfile);
      await container.read(profileProvider.future);
    },
  );
}
