import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);

class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;

  const AppSettings({
    required this.locale,
    required this.themeMode,
  });
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);

    final savedLanguage = prefs.getString('app_language') ?? 'en';
    final language = const ['en', 'fr', 'ar'].contains(savedLanguage)
        ? savedLanguage
        : 'en';
    final savedTheme = prefs.getString('app_theme') ?? 'system';

    final themeMode = switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return AppSettings(
      locale: Locale(language),
      themeMode: themeMode,
    );
  }

  Future<void> setLanguage(String language) async {
    if (!['en', 'fr', 'ar'].contains(language)) return;

    if (state.locale.languageCode == language) return;

    // Persist first, then publish one atomic settings state. This prevents
    // rapid language taps from leaving the UI and stored preference out of sync.
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString('app_language', language);
    state = AppSettings(
      locale: Locale(language),
      themeMode: state.themeMode,
    );
  }

  Future<void> setTheme(ThemeMode theme) async {
    final value = switch (theme) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString('app_theme', value);
    state = AppSettings(
      locale: state.locale,
      themeMode: theme,
    );
  }
}
