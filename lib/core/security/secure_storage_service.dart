import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConfig.keyAccessToken, value: token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConfig.keyRefreshToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConfig.keyRefreshToken);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
