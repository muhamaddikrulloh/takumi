import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_track/core/services/local_data_service.dart';

class PasswordResetRateLimitResult {
  const PasswordResetRateLimitResult({
    required this.allowed,
    required this.retryAfter,
    required this.attemptsInWindow,
  });

  final bool allowed;
  final Duration retryAfter;
  final int attemptsInWindow;
}

class PasswordResetRateLimiter {
  PasswordResetRateLimiter(this._preferences, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const hourlyWindow = Duration(hours: 1);
  static const maxRequestsPerHour = 5;
  static const resendCooldowns = <Duration>[
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 3),
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];

  static const _initialPrefix = 'password_reset_initial';
  static const _resendPrefix = 'password_reset_resend';

  final SharedPreferences _preferences;
  final DateTime Function() _now;
  final Set<String> _pendingKeys = {};

  Future<PasswordResetRateLimitResult> tryAcquireInitial(String email) {
    return _tryAcquire(email, _initialPrefix, isResend: false);
  }

  Future<PasswordResetRateLimitResult> tryAcquireResend(String email) {
    return _tryAcquire(email, _resendPrefix, isResend: true);
  }

  PasswordResetRateLimitResult resendStatus(String email) {
    final attempts = _readAttempts(_key(_resendPrefix, email));
    return _resendStatus(attempts);
  }

  Future<PasswordResetRateLimitResult> _tryAcquire(
    String email,
    String prefix, {
    required bool isResend,
  }) async {
    final key = _key(prefix, email);
    final attempts = _readAttempts(key);
    final status = isResend
        ? _resendStatus(attempts)
        : _initialStatus(attempts);
    if (!status.allowed) return status;

    if (!_pendingKeys.add(key)) {
      return PasswordResetRateLimitResult(
        allowed: false,
        retryAfter: const Duration(seconds: 1),
        attemptsInWindow: attempts.length,
      );
    }

    try {
      final timestamp = _now().millisecondsSinceEpoch;
      final updatedAttempts = [...attempts, timestamp];
      final stored = await _preferences.setStringList(
        key,
        updatedAttempts.map((value) => '$value').toList(growable: false),
      );
      if (!stored) {
        throw StateError('Could not persist the password reset rate limit');
      }

      return PasswordResetRateLimitResult(
        allowed: true,
        retryAfter: isResend
            ? resendCooldowns[updatedAttempts.length - 1]
            : Duration.zero,
        attemptsInWindow: updatedAttempts.length,
      );
    } finally {
      _pendingKeys.remove(key);
    }
  }

  PasswordResetRateLimitResult _initialStatus(List<int> attempts) {
    if (attempts.length < maxRequestsPerHour) {
      return PasswordResetRateLimitResult(
        allowed: true,
        retryAfter: Duration.zero,
        attemptsInWindow: attempts.length,
      );
    }

    return PasswordResetRateLimitResult(
      allowed: false,
      retryAfter: _remainingUntil(attempts.first + hourlyWindow.inMilliseconds),
      attemptsInWindow: attempts.length,
    );
  }

  PasswordResetRateLimitResult _resendStatus(List<int> attempts) {
    if (attempts.isEmpty) {
      return const PasswordResetRateLimitResult(
        allowed: true,
        retryAfter: Duration.zero,
        attemptsInWindow: 0,
      );
    }

    final cooldownIndex = attempts.length <= resendCooldowns.length
        ? attempts.length - 1
        : resendCooldowns.length - 1;
    final cooldownRemaining = _remainingUntil(
      attempts.last + resendCooldowns[cooldownIndex].inMilliseconds,
    );
    if (cooldownRemaining > Duration.zero) {
      return PasswordResetRateLimitResult(
        allowed: false,
        retryAfter: cooldownRemaining,
        attemptsInWindow: attempts.length,
      );
    }

    if (attempts.length >= maxRequestsPerHour) {
      return PasswordResetRateLimitResult(
        allowed: false,
        retryAfter: _remainingUntil(
          attempts.first + hourlyWindow.inMilliseconds,
        ),
        attemptsInWindow: attempts.length,
      );
    }

    return PasswordResetRateLimitResult(
      allowed: true,
      retryAfter: Duration.zero,
      attemptsInWindow: attempts.length,
    );
  }

  List<int> _readAttempts(String key) {
    final now = _now().millisecondsSinceEpoch;
    final cutoff = now - hourlyWindow.inMilliseconds;
    final attempts =
        (_preferences.getStringList(key) ?? const <String>[])
            .map(int.tryParse)
            .whereType<int>()
            .where((timestamp) => timestamp > cutoff && timestamp <= now)
            .toList(growable: true)
          ..sort();
    return attempts;
  }

  Duration _remainingUntil(int timestamp) {
    final milliseconds = timestamp - _now().millisecondsSinceEpoch;
    return milliseconds <= 0
        ? Duration.zero
        : Duration(milliseconds: milliseconds);
  }

  String _key(String prefix, String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw ArgumentError.value(email, 'email', 'Email cannot be empty');
    }
    return LocalDataService.privateKey(prefix, normalizedEmail);
  }
}
