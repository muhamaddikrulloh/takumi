import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_track/core/providers/core_providers.dart';
import 'package:task_track/features/auth/data/auth_repository.dart';
import 'package:task_track/features/auth/data/password_reset_rate_limiter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final newlyRegisteredUidProvider = StateProvider<String?>((ref) => null);

final passwordResetRateLimiterProvider = Provider<PasswordResetRateLimiter>((
  ref,
) {
  return PasswordResetRateLimiter(ref.watch(sharedPreferencesProvider));
});
