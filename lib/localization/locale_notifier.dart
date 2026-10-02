import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr'));

  Future<void> loadSavedLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString('edugest_language');
    if (savedLanguage == 'fr' || savedLanguage == 'en') {
      value = Locale(savedLanguage!);
    }
  }

  Future<void> loadForUser(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString('edugest_language_$userId');
    value = savedLanguage == 'fr' || savedLanguage == 'en'
        ? Locale(savedLanguage!)
        : const Locale('fr');
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'fr' && locale.languageCode != 'en') return;
    if (locale == value) return;
    value = locale;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('edugest_language', locale.languageCode);
  }

  Future<void> setLocaleForUser(String userId, Locale locale) async {
    if (locale.languageCode != 'fr' && locale.languageCode != 'en') return;
    value = locale;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'edugest_language_$userId',
      locale.languageCode,
    );
  }
}

final appLocale = LocaleNotifier();
