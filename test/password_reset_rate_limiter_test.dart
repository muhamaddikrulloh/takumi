import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_track/features/auth/data/password_reset_rate_limiter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'initial reset is limited to five requests per email per hour',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      var now = DateTime.utc(2026, 1, 1, 12);
      final limiter = PasswordResetRateLimiter(preferences, now: () => now);

      for (var attempt = 1; attempt <= 5; attempt++) {
        final result = await limiter.tryAcquireInitial('Student@Example.com ');
        expect(result.allowed, isTrue);
        expect(result.attemptsInWindow, attempt);
        expect(result.retryAfter, Duration.zero);
      }

      final blocked = await limiter.tryAcquireInitial('student@example.com');
      expect(blocked.allowed, isFalse);
      expect(blocked.attemptsInWindow, 5);
      expect(blocked.retryAfter, const Duration(hours: 1));

      final restoredLimiter = PasswordResetRateLimiter(
        preferences,
        now: () => now,
      );
      expect(
        (await restoredLimiter.tryAcquireInitial('student@example.com'))
            .allowed,
        isFalse,
      );
      expect(
        (await restoredLimiter.tryAcquireInitial('other@example.com')).allowed,
        isTrue,
      );

      now = now.add(const Duration(hours: 1));
      expect(
        (await restoredLimiter.tryAcquireInitial('student@example.com'))
            .allowed,
        isTrue,
      );
    },
  );

  test('resend cooldown grows and resend is capped at five per hour', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    var now = DateTime.utc(2026, 1, 1, 12);
    final limiter = PasswordResetRateLimiter(preferences, now: () => now);
    const cooldowns = <Duration>[
      Duration(minutes: 1),
      Duration(minutes: 2),
      Duration(minutes: 3),
      Duration(minutes: 5),
      Duration(minutes: 10),
    ];

    for (var index = 0; index < cooldowns.length; index++) {
      final acquired = await limiter.tryAcquireResend('student@example.com');
      expect(acquired.allowed, isTrue);
      expect(acquired.attemptsInWindow, index + 1);
      expect(acquired.retryAfter, cooldowns[index]);

      final blocked = await limiter.tryAcquireResend('student@example.com');
      expect(blocked.allowed, isFalse);
      expect(blocked.retryAfter, cooldowns[index]);

      now = now.add(cooldowns[index]);
    }

    final hourlyBlocked = await limiter.tryAcquireResend('student@example.com');
    expect(hourlyBlocked.allowed, isFalse);
    expect(hourlyBlocked.attemptsInWindow, 5);
    expect(hourlyBlocked.retryAfter, const Duration(minutes: 39));

    final restoredLimiter = PasswordResetRateLimiter(
      preferences,
      now: () => now,
    );
    expect(
      restoredLimiter.resendStatus('student@example.com').retryAfter,
      const Duration(minutes: 39),
    );
    expect(
      (await restoredLimiter.tryAcquireResend('other@example.com')).allowed,
      isTrue,
    );
  });

  test(
    'concurrent requests for the same email acquire only one slot',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final limiter = PasswordResetRateLimiter(
        preferences,
        now: () => DateTime.utc(2026, 1, 1, 12),
      );

      final results = await Future.wait([
        limiter.tryAcquireInitial('student@example.com'),
        limiter.tryAcquireInitial('student@example.com'),
      ]);

      expect(results.where((result) => result.allowed), hasLength(1));
    },
  );
}
