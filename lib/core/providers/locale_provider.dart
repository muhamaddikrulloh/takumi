import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_track/core/providers/core_providers.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'locale';

  @override
  Locale build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_key);
    return _parse(stored);
  }

  Locale _parse(String? value) {
    switch (value) {
      case 'en':
        return const Locale('en');
      case 'id':
        return const Locale('id');
      default:
        final systemLanguage =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        return Locale(systemLanguage == 'id' ? 'id' : 'en');
    }
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, locale.languageCode);
    state = locale;
  }
}
