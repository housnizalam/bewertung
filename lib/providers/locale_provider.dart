import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/hive_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    final saved = HiveService.loadSelectedLocaleCode();
    state = Locale(saved);
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'ar' ? 'ar' : 'en';
    if (state.languageCode == code) return;

    state = Locale(code);
    await HiveService.saveSelectedLocaleCode(code);
  }
}
