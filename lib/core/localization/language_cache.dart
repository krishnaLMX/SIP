import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LanguageCache {
  static const String _keyLocale = 'selected_locale';
  static const String _keyTranslationsPrefix = 'cached_translations_';

  Future<void> saveLocale(String localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, localeCode);
  }

  Future<String?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocale);
  }

  Future<void> saveRemoteTranslations(
      String localeCode, Map<String, String> translations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$_keyTranslationsPrefix$localeCode', jsonEncode(translations));
  }

  Future<Map<String, String>?> getRemoteTranslations(String localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_keyTranslationsPrefix$localeCode');
    if (data != null) {
      try {
        return Map<String, String>.from(jsonDecode(data));
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

