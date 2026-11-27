import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/settings/app_settings.dart';
import 'package:app/main.dart';
import 'package:app/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('language preference is persisted and applied', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appSettingsProvider).locale.languageCode, 'en');

    await container.read(appSettingsProvider.notifier).setLanguage('ar');

    expect(container.read(appSettingsProvider).locale.languageCode, 'ar');
    expect(preferences.getString('app_language'), 'ar');
  });

  test('unsupported saved language falls back to English', () async {
    SharedPreferences.setMockInitialValues({'app_language': 'de'});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appSettingsProvider).locale.languageCode, 'en');
  });


  test('all supported locales resolve page-specific assistant copy', () {
    final english = lookupAppLocalizations(const Locale('en'));
    final french = lookupAppLocalizations(const Locale('fr'));
    final arabic = lookupAppLocalizations(const Locale('ar'));

    expect(english.voiceTitle, 'Agricultural assistant');
    expect(french.voiceTitle, 'Assistant agricole');
    expect(arabic.voiceTitle, 'المساعد الفلاحي');
    expect(english.fieldTagline, isNot(french.fieldTagline));
    expect(french.fieldTagline, isNot(arabic.fieldTagline));
    expect(english.irrigationTitle, 'Smart Irrigation');
    expect(french.irrigationTitle, 'Irrigation intelligente');
    expect(arabic.irrigationTitle, 'الري الذكي');
    expect(english.dashboardDevices, 'Registered devices');
    expect(french.dashboardDevices, 'Appareils enregistrés');
    expect(arabic.dashboardDevices, 'الأجهزة المسجلة');
    expect(english.dashboardReadingTime('09:30'), 'Recorded 09:30');
    expect(french.dashboardReadingTime('09:30'), 'Enregistré à 09:30');
    expect(arabic.dashboardReadingTime('09:30'), 'سُجل في 09:30');
  });

  testWidgets('AETHERA app loads successfully', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const AetheraApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
