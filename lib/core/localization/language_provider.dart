import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'language_service.dart';

class LanguageState {
  final String currentLocale;
  final Map<String, Map<String, String>> translations;
  final bool isLoading;

  LanguageState({
    this.currentLocale = 'en',
    this.translations = const {},
    this.isLoading = false,
  });

  LanguageState copyWith({
    String? currentLocale,
    Map<String, Map<String, String>>? translations,
    bool? isLoading,
  }) {
    return LanguageState(
      currentLocale: currentLocale ?? this.currentLocale,
      translations: translations ?? this.translations,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LanguageNotifier extends StateNotifier<LanguageState> {
  final LanguageService _service = LanguageService();
  static const String _keyLocale = 'selected_locale';
  static const String _keyTranslations = 'app_translations';

  LanguageNotifier() : super(LanguageState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLocale = prefs.getString(_keyLocale) ?? 'en';

    // Load local cache immediately
    final cachedData = prefs.getString(_keyTranslations);
    Map<String, Map<String, String>> localTranslations = {};
    if (cachedData != null) {
      try {
        final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
        localTranslations =
            decoded.map((k, v) => MapEntry(k, Map<String, String>.from(v)));
      } catch (_) {}
    }

    state = state.copyWith(
      currentLocale: cachedLocale,
      translations: localTranslations,
    );

    // Call API once in background
    _fetchAndCacheTranslations(prefs);
  }

  Future<void> _fetchAndCacheTranslations(SharedPreferences prefs) async {
    try {
      final remoteTranslations = await _service.fetchMegaTranslations();
      if (remoteTranslations != null) {
        state = state.copyWith(translations: remoteTranslations);
        await prefs.setString(_keyTranslations, jsonEncode(remoteTranslations));
      }
    } catch (e) {
      // Background call, fail silently
    }
  }

  Future<void> setLanguage(String localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, localeCode);
    state = state.copyWith(currentLocale: localeCode);
  }

  String translate(String key, [Map<String, String>? args]) {
    final Map<String, String>? keyTranslations = state.translations[key];
    String value = key;

    if (keyTranslations != null) {
      // Fallback logic: Try selected -> Try EN -> Fallback to key
      if (keyTranslations.containsKey(state.currentLocale) &&
          keyTranslations[state.currentLocale]!.isNotEmpty) {
        value = keyTranslations[state.currentLocale]!;
      } else if (keyTranslations.containsKey('en') &&
          keyTranslations['en']!.isNotEmpty) {
        value = keyTranslations['en']!;
      }
    }

    if (args != null) {
      args.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }
    return value;
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});

extension LocalizationHelper on WidgetRef {
  // We keep optional default parameters to avoid breaking existing ref.tr calls before they are refactored
  String tr(String key, {String? fallback, Map<String, String>? args}) {
    final trValue = watch(languageProvider.notifier).translate(key, args);
    // If we couldn't find a translation and have an explicit fallback, use the fallback
    if (trValue == key && fallback != null) {
      return fallback;
    }
    return trValue;
  }
}
