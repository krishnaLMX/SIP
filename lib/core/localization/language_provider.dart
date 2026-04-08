import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _keyLocale = 'selected_locale';

  LanguageNotifier() : super(LanguageState()) {
    _init();
  }

  Future<void> _init() async {
    // Current locale is English by default as per user request
    state = state.copyWith(
      currentLocale: 'en',
      translations: {},
    );
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

