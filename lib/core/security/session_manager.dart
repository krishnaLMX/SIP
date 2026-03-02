import 'secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class SessionManager {
  static Future<bool> isAuthenticated() async {
    String? token = await SecureStorageService.getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    await SecureStorageService.clearAll();
    // Keep onboarding status, only clear session data
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConfig.keyHasSeenOnboarding) ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConfig.keyHasSeenOnboarding, true);
  }
}
