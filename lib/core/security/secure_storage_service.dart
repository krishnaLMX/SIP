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

  static Future<bool> isMpinEnabled() async {
    final value = await _storage.read(key: AppConfig.keyIsMpinEnabled);
    return value == 'true';
  }

  static Future<void> setMpinEnabled(bool enabled) async {
    await _storage.write(
        key: AppConfig.keyIsMpinEnabled, value: enabled.toString());
  }

  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: AppConfig.keyIsBiometricEnabled);
    return value == 'true';
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
        key: AppConfig.keyIsBiometricEnabled, value: enabled.toString());
  }

  static Future<bool> getOnboardingSeen() async {
    final value = await _storage.read(key: AppConfig.keyHasSeenOnboarding);
    return value == 'true';
  }

  static Future<void> setOnboardingSeen(bool seen) async {
    await _storage.write(
        key: AppConfig.keyHasSeenOnboarding, value: seen.toString());
  }

  static Future<void> saveCustomerId(String id) async {
    await _storage.write(key: AppConfig.keyCustomerId, value: id);
  }

  static Future<String?> getCustomerId() async {
    return await _storage.read(key: AppConfig.keyCustomerId);
  }

  static Future<void> saveCustomerName(String name) async {
    await _storage.write(key: AppConfig.keyCustomerName, value: name);
  }

  static Future<String?> getCustomerName() async {
    return await _storage.read(key: AppConfig.keyCustomerName);
  }

  static Future<void> saveCustomerPhoto(String url) async {
    await _storage.write(key: AppConfig.keyCustomerPhoto, value: url);
  }

  static Future<String?> getCustomerPhoto() async {
    return await _storage.read(key: AppConfig.keyCustomerPhoto);
  }

  // ── RSA Public Key Cache ──────────────────────────────────────────────────
  static Future<void> saveServerPublicKey(String pem) async {
    await _storage.write(key: AppConfig.keyServerPublicKey, value: pem);
  }

  static Future<String?> getServerPublicKey() async {
    return await _storage.read(key: AppConfig.keyServerPublicKey);
  }
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> saveMobile(String mobile) async {
    await _storage.write(key: AppConfig.keyMobileNumber, value: mobile);
  }

  static Future<String?> getMobile() async {
    return await _storage.read(key: AppConfig.keyMobileNumber);
  }

  // ── FCM Token Cache ───────────────────────────────────────────────────────
  static Future<void> saveFcmToken(String token) async {
    await _storage.write(key: AppConfig.keyFcmToken, value: token);
  }

  static Future<String?> getFcmToken() async {
    return await _storage.read(key: AppConfig.keyFcmToken);
  }
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    await _storage.deleteAll();
  }
}

