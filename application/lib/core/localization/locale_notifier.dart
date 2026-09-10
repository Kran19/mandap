import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  final String code;
  final String englishName;
  final String nativeName;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.flag,
  });

  Locale get locale => Locale(code);
}

const List<AppLanguage> kApprovedLanguages = [
  AppLanguage(code: 'en', englishName: 'English', nativeName: 'English', flag: '🇬🇧'),
  AppLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
  AppLanguage(code: 'gu', englishName: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳'),
  AppLanguage(code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳'),
  AppLanguage(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳'),
  AppLanguage(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳'),
  AppLanguage(code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা', flag: '🇮🇳'),
];

class LocaleNotifier extends ChangeNotifier {
  static const String _localeKey = 'mandap_locale';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  List<AppLanguage> get supportedLanguages => kApprovedLanguages;

  AppLanguage get currentLanguage {
    return kApprovedLanguages.firstWhere(
      (lang) => lang.code == _locale.languageCode,
      orElse: () => kApprovedLanguages.first,
    );
  }

  LocaleNotifier() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_localeKey);

    if (savedCode != null && kApprovedLanguages.any((l) => l.code == savedCode)) {
      _locale = Locale(savedCode);
    } else {
      final deviceCode = PlatformDispatcher.instance.locale.languageCode;
      if (kApprovedLanguages.any((l) => l.code == deviceCode)) {
        _locale = Locale(deviceCode);
      } else {
        _locale = const Locale('en');
      }
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
  }

  Future<void> setLanguageByCode(String code) async {
    await setLocale(Locale(code));
  }
}
