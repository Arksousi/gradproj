// locale_provider.dart
// Persists and exposes the app locale via Riverpod + SharedPreferences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  static const _key = 'app_locale';

  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = Locale(prefs.getString(_key) ?? 'en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  void toggleLocale() => setLocale(
      state.languageCode == 'en' ? const Locale('ar') : const Locale('en'));
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());
