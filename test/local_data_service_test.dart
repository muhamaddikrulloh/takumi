import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_track/core/services/local_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('private local keys do not contain their source value', () {
    const email = 'student@example.com';
    const photoUrl = 'https://example.com/private/avatar.png';

    final emailKey = LocalDataService.privateKey('password_reset', email);
    final photoKey = LocalDataService.accountPhotoCacheKey(photoUrl);

    expect(emailKey, isNot(contains(email)));
    expect(photoKey, isNot(contains(photoUrl)));
    expect(LocalDataService.accountPhotoCacheKey(photoUrl), equals(photoKey));
  });

  test('account photo cleanup preserves unrelated preferences', () async {
    final photoKey = LocalDataService.accountPhotoCacheKey(
      'https://example.com/avatar.png',
    );
    SharedPreferences.setMockInitialValues({
      photoKey: 'encoded-image',
      'avatar_https://legacy.example/avatar.png': 'legacy-image',
      'locale': 'id',
    });
    final preferences = await SharedPreferences.getInstance();

    await LocalDataService.clearAccountPhotoCache(preferences);

    expect(preferences.containsKey(photoKey), isFalse);
    expect(
      preferences.containsKey('avatar_https://legacy.example/avatar.png'),
      isFalse,
    );
    expect(preferences.getString('locale'), 'id');
  });

  test('legacy private data cleanup preserves hashed rate limits', () async {
    final hashedResetKey = LocalDataService.privateKey(
      'password_reset_initial',
      'student@example.com',
    );
    SharedPreferences.setMockInitialValues({
      'avatar_https://legacy.example/avatar.png': 'legacy-image',
      'password_reset_initial_c3R1ZGVudEBleGFtcGxlLmNvbQ': ['1'],
      'password_reset_resend_c3R1ZGVudEBleGFtcGxlLmNvbQ': ['2'],
      hashedResetKey: ['3'],
      'locale': 'id',
    });
    final preferences = await SharedPreferences.getInstance();

    await LocalDataService.clearLegacyPrivateData(preferences);

    expect(
      preferences.containsKey('avatar_https://legacy.example/avatar.png'),
      isFalse,
    );
    expect(
      preferences.containsKey(
        'password_reset_initial_c3R1ZGVudEBleGFtcGxlLmNvbQ',
      ),
      isFalse,
    );
    expect(
      preferences.containsKey(
        'password_reset_resend_c3R1ZGVudEBleGFtcGxlLmNvbQ',
      ),
      isFalse,
    );
    expect(preferences.containsKey(hashedResetKey), isTrue);
    expect(preferences.getString('locale'), 'id');
  });
}
