import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataService {
  LocalDataService._();

  static const _accountPhotoPrefix = 'account_photo_cache_v1_';
  static const _legacyAccountPhotoPrefix = 'avatar_';
  static const _legacyPasswordResetPrefixes = <String>[
    'password_reset_initial_',
    'password_reset_resend_',
  ];

  static String accountPhotoCacheKey(String url) {
    return '$_accountPhotoPrefix${sha256.convert(utf8.encode(url))}';
  }

  static String privateKey(String prefix, String value) {
    return '${prefix}_v2_${sha256.convert(utf8.encode(value))}';
  }

  static Future<void> clearAccountPhotoCache(
    SharedPreferences preferences,
  ) async {
    final keys = preferences
        .getKeys()
        .where(
          (key) =>
              key.startsWith(_accountPhotoPrefix) ||
              key.startsWith(_legacyAccountPhotoPrefix),
        )
        .toList(growable: false);
    await Future.wait(keys.map(preferences.remove));
  }

  static Future<void> clearLegacyPrivateData(
    SharedPreferences preferences,
  ) async {
    final keys = preferences
        .getKeys()
        .where((key) {
          if (key.startsWith(_legacyAccountPhotoPrefix)) return true;
          return _legacyPasswordResetPrefixes.any(
            (prefix) =>
                key.startsWith(prefix) && !key.startsWith('${prefix}v2_'),
          );
        })
        .toList(growable: false);
    await Future.wait(keys.map(preferences.remove));
  }
}
