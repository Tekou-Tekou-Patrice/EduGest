import 'package:flutter/material.dart';

class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr'));

  void setLocale(Locale locale) {
    if (locale == value) return;
    value = locale;
  }
}

final appLocale = LocaleNotifier();
