import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_track/core/providers/connectivity_provider.dart';
import 'package:task_track/core/utils/app_logger.dart';
import 'package:task_track/core/utils/validators.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/profile/data/profile_repository.dart';
import 'package:task_track/features/profile/domain/avatar_catalog.dart';
import 'package:task_track/features/profile/domain/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile>(
  ProfileNotifier.new,
);

final profileGateProvider = FutureProvider<Profile>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final repository = ref.watch(profileRepositoryProvider);
  if (user == null || !user.emailVerified) {
    return repository.profileFromAuth();
  }
  if (ref.watch(newlyRegisteredUidProvider) == user.uid) {
    return repository.profileFromAuth();
  }
  return repository.getProfileForSetupGate();
});

final profileSyncErrorProvider = StateProvider<Object?>((ref) => null);

class ProfileNotifier extends AsyncNotifier<Profile> {
  int _gen = 0;
  String? _activeUid;
  late ProfileRepository _repository;

  @override
  Future<Profile> build() async {
    final user = ref.watch(authStateProvider).valueOrNull;
    final repo = ref.read(profileRepositoryProvider);
    _repository = repo;
    final nextUid = user != null && user.emailVerified ? user.uid : null;
    if (_activeUid != nextUid) _gen++;
    _activeUid = nextUid;
    if (_activeUid == null) return repo.profileFromAuth();
    return ref.watch(profileGateProvider.future);
  }

  Future<bool> updateInstitution(String value) async {
    final uid = _requireCurrentUid();
    final normalized = value.trim();
    if (Validators.validateInstitution(normalized) != null) {
      return false;
    }
    final rollback = state;
    final current = rollback.valueOrNull;
    final gen = ++_gen;
    if (current != null) {
      state = AsyncData(current.copyWith(institution: normalized));
    }
    final repo = _repository;
    return _persist(
      uid: uid,
      gen: gen,
      rollback: rollback,
      write: () => repo.updateInstitution(expectedUid: uid, value: normalized),
    );
  }

  Future<bool> completeSetup({
    required String displayName,
    required String institution,
    required String major,
    required String avatarId,
  }) async {
    final uid = _requireCurrentUid();
    final normalizedName = displayName.trim();
    final normalizedInstitution = institution.trim();
    final normalizedMajor = major.trim();
    if (Validators.validateFullName(normalizedName) != null ||
        Validators.validateInstitution(normalizedInstitution) != null ||
        Validators.validateMajor(normalizedMajor) != null ||
        !AvatarCatalog.isValid(avatarId)) {
      return false;
    }

    final current = _currentProfile();
    if (!AvatarCatalog.isAvailable(avatarId, photoUrl: current.photoUrl)) {
      return false;
    }
    final rollback = state;
    final gen = ++_gen;
    final updated = current.copyWith(
      displayName: normalizedName,
      institution: normalizedInstitution,
      major: normalizedMajor,
      avatarId: avatarId,
      setupComplete: true,
    );
    state = AsyncData(updated);

    try {
      await _repository
          .completeSetup(
            expectedUid: uid,
            displayName: normalizedName,
            institution: normalizedInstitution,
            major: normalizedMajor,
            avatarId: avatarId,
          )
          .timeout(const Duration(seconds: 12));
      final isCurrent = gen == _gen && _isCurrentUser(uid);
      if (isCurrent) {
        state = AsyncData(updated);
        if (ref.read(newlyRegisteredUidProvider) == uid) {
          ref.read(newlyRegisteredUidProvider.notifier).state = null;
        }
        ref.invalidate(profileGateProvider);
      }
      return isCurrent;
    } catch (error) {
      logDebug('Profile setup failed', error: error);
      if (gen == _gen && _isCurrentUser(uid)) state = rollback;
      return false;
    }
  }

  Future<bool> updateIdentity({
    required String displayName,
    required String avatarId,
  }) async {
    final uid = _requireCurrentUid();
    final normalizedName = displayName.trim();
    if (Validators.validateFullName(normalizedName) != null ||
        !AvatarCatalog.isValid(avatarId)) {
      return false;
    }

    final current = _currentProfile();
    if (!AvatarCatalog.isAvailable(avatarId, photoUrl: current.photoUrl)) {
      return false;
    }
    final rollback = state;
    final gen = ++_gen;
    final updated = current.copyWith(
      displayName: normalizedName,
      avatarId: avatarId,
    );
    state = AsyncData(updated);

    final repo = _repository;
    final saved = await _persist(
      uid: uid,
      gen: gen,
      rollback: rollback,
      write: () => repo.updateIdentity(
        expectedUid: uid,
        displayName: normalizedName,
        avatarId: avatarId,
      ),
    );
    if (saved && gen == _gen && _isCurrentUser(uid)) {
      state = AsyncData(updated);
    }
    return saved;
  }

  Future<bool> updateMajor(String value) async {
    final uid = _requireCurrentUid();
    final normalized = value.trim();
    if (Validators.validateMajor(normalized) != null) return false;
    final rollback = state;
    final current = rollback.valueOrNull;
    final gen = ++_gen;
    if (current != null) {
      state = AsyncData(current.copyWith(major: normalized));
    }
    final repo = _repository;
    return _persist(
      uid: uid,
      gen: gen,
      rollback: rollback,
      write: () => repo.updateMajor(expectedUid: uid, value: normalized),
    );
  }

  Future<bool> _persist({
    required String uid,
    required int gen,
    required AsyncValue<Profile> rollback,
    required Future<void> Function() write,
  }) async {
    final writeFuture = write();
    if (ref.read(connectivityProvider).valueOrNull == false) {
      _monitorQueuedWrite(writeFuture, uid, gen, rollback);
      return true;
    }
    try {
      await writeFuture.timeout(const Duration(seconds: 8));
      return true;
    } on TimeoutException {
      _monitorQueuedWrite(writeFuture, uid, gen, rollback);
      return true;
    } catch (error) {
      logDebug('Profile write failed', error: error);
      if (gen == _gen && _isCurrentUser(uid)) state = rollback;
      return false;
    }
  }

  Profile _currentProfile() {
    final current = state.valueOrNull;
    if (current != null) return current;
    return _repository.profileFromAuth();
  }

  void _monitorQueuedWrite(
    Future<void> write,
    String uid,
    int gen,
    AsyncValue<Profile> rollback,
  ) {
    unawaited(
      write.catchError((Object error, StackTrace stackTrace) {
        logDebug('Queued profile write failed', error: error);
        if (gen == _gen && _isCurrentUser(uid)) {
          state = rollback;
          ref.read(profileSyncErrorProvider.notifier).state = error;
        }
      }),
    );
  }

  String _requireCurrentUid() {
    final uid = _repository.currentVerifiedUid;
    if (uid == null || _activeUid != uid) {
      throw StateError('Verified user required');
    }
    return uid;
  }

  bool _isCurrentUser(String uid) =>
      _activeUid == uid && _repository.currentVerifiedUid == uid;
}
