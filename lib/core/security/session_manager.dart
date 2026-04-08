import 'secure_storage_service.dart';

class SessionManager {
  static Future<bool> isAuthenticated() async {
    String? token = await SecureStorageService.getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    await SecureStorageService.logout();
  }

  static Future<bool> hasSeenOnboarding() async {
    final value = await SecureStorageService.getOnboardingSeen();
    return value == true;
  }

  static Future<void> setOnboardingSeen() async {
    await SecureStorageService.setOnboardingSeen(true);
  }
}

