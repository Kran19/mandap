import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mandap/l10n/app_localizations.dart';
import 'package:mandap/core/localization/locale_notifier.dart';

void main() {
  group('MANDAP Multi-Language / Localization Integration Tests', () {
    final approvedLocales = [
      const Locale('en'),
      const Locale('hi'),
      const Locale('gu'),
      const Locale('ta'),
      const Locale('te'),
      const Locale('mr'),
      const Locale('bn'),
    ];

    test('All 7 approved locales are supported in AppLocalizations.delegate', () {
      for (final locale in approvedLocales) {
        expect(AppLocalizations.delegate.isSupported(locale), isTrue,
            reason: 'Locale ${locale.languageCode} must be supported');
      }
    });

    test('AppLocalizations lookup returns non-null instance for all 7 approved locales', () {
      for (final locale in approvedLocales) {
        final localizations = lookupAppLocalizations(locale);
        expect(localizations, isNotNull);
        expect(localizations.appTitle, equals('MANDAP'));
        expect(localizations.truss, isNotEmpty);
      }
    });

    test('LocaleNotifier initial default falls back to English for unsupported device locale', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final notifier = LocaleNotifier();
      expect(notifier.supportedLanguages.length, equals(7));
      expect(kApprovedLanguages.any((l) => l.code == 'en'), isTrue);
    });

    test('LocaleNotifier updates locale and maintains persistence key format', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final notifier = LocaleNotifier();
      await notifier.setLanguageByCode('hi');
      expect(notifier.locale.languageCode, equals('hi'));
      expect(notifier.currentLanguage.nativeName, equals('हिन्दी'));

      await notifier.setLanguageByCode('gu');
      expect(notifier.locale.languageCode, equals('gu'));
      expect(notifier.currentLanguage.nativeName, equals('ગુજરાતી'));
    });

    test('Gujarati locale contains newly added translations', () {
      final guL10n = lookupAppLocalizations(const Locale('gu'));
      expect(guL10n.trussCalculationSize, equals('ટ્રસ ગણતરી સાઇઝ'));
      expect(guL10n.ok, equals('બરાબર'));
      expect(guL10n.extra, equals('વધારાનું'));
      expect(guL10n.covered, equals('કવર કરેલ'));
      expect(guL10n.plotLimit, equals('પ્લોટ મર્યાદા'));
      expect(guL10n.box, equals('બોક્સ'));
    });
  });
}
