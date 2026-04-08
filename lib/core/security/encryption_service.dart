import 'package:encrypt/encrypt.dart';

import 'package:pointycastle/asymmetric/api.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';
import 'secure_logger.dart';

/// EncryptionService
///
/// Uses RSA-OAEP-SHA256 with the server's public key fetched from
/// `crypto/public-key` endpoint. No static/hardcoded keys.
///
/// The interceptor calls [loadPublicKey] at startup so that RSA is ready
/// before the first sensitive request is sent.
class EncryptionService {
  // ── RSA State ───────────────────────────────────────────────────────────
  static RSAPublicKey? _rsaPublicKey;
  static bool _rsaReady = false;

  // ── Initialisation ───────────────────────────────────────────────────────
  /// Call once at startup (from ApiSecurityInterceptor or main).
  /// Loads the cached RSA public key from secure storage.
  static Future<void> loadPublicKey() async {
    try {
      final pem = await SecureStorageService.getServerPublicKey();
      if (pem != null && pem.isNotEmpty) {
        _initRsaFromPem(pem);
        SecureLogger.d('ENCRYPTION: RSA public key loaded from cache.');
      } else {
        SecureLogger.d(
            'ENCRYPTION: No RSA key cached yet. Will fetch from server before encrypting.');
      }
    } catch (e) {
      SecureLogger.e('ENCRYPTION: Failed to load RSA key from cache: $e');
    }
  }

  /// Call this after fetching the key from the `crypto/public-key` endpoint.
  static Future<void> setPublicKeyFromServer({
    required String pemKey,
  }) async {
    try {
      _initRsaFromPem(pemKey);
      await SecureStorageService.saveServerPublicKey(pemKey);
      SecureLogger.d('ENCRYPTION: RSA public key received and cached.');
    } catch (e) {
      SecureLogger.e('ENCRYPTION: Failed to parse server RSA key: $e');
    }
  }

  static void _initRsaFromPem(String pem) {
    final parser = RSAKeyParser();
    _rsaPublicKey = parser.parse(pem) as RSAPublicKey;
    _rsaReady = true;
  }

  static bool get isRsaReady => _rsaReady;

  /// Clears the cached key (e.g. on logout) to force a fresh fetch.
  static void clearKey() {
    _rsaPublicKey = null;
    _rsaReady = false;
    SecureLogger.d('ENCRYPTION: RSA key cleared.');
  }

  // ── Encrypt ──────────────────────────────────────────────────────────────
  /// Encrypts a plain-text string using RSA-OAEP-SHA256.
  /// Throws [StateError] if the public key has not been loaded yet.
  static String encrypt(String plainText) {
    if (plainText.isEmpty) return plainText;

    if (!_rsaReady || _rsaPublicKey == null) {
      SecureLogger.e(
          'ENCRYPTION: RSA key not available. Cannot encrypt sensitive data.');
      throw StateError(
          'RSA public key not loaded. Call fetchAndCachePublicKey() first.');
    }

    return _rsaEncrypt(plainText);
  }

  static String _rsaEncrypt(String plainText) {
    try {
      final encrypter = Encrypter(RSA(
        publicKey: _rsaPublicKey,
        encoding: RSAEncoding.OAEP,
        digest: RSADigest.SHA256,
      ));
      final encrypted = encrypter.encrypt(plainText);
      return encrypted.base64;
    } catch (e) {
      SecureLogger.e('ENCRYPTION: RSA encrypt failed: $e');
      rethrow;
    }
  }

  // ── Decrypt ──────────────────────────────────────────────────────────────
  /// Client-side RSA decryption is not possible (we don't have the private key).
  /// Server responses with encrypted fields should be handled server-side.
  /// This method is kept for any future symmetric decryption needs.
  static String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    // Server responses are not encrypted in the current architecture.
    return encryptedText;
  }

  // ── JSON helpers ─────────────────────────────────────────────────────────
  /// Encrypts sensitive fields in a Map recursively.
  static Map<String, dynamic> encryptJson(Map<String, dynamic> json) {
    final Map<String, dynamic> result = Map.from(json);
    for (var key in result.keys) {
      if (AppConfig.sensitiveFields.contains(key)) {
        if (result[key] != null) {
          result[key] = encrypt(result[key].toString());
        }
      } else if (result[key] is Map<String, dynamic>) {
        result[key] = encryptJson(result[key]);
      } else if (result[key] is List) {
        result[key] = result[key].map((item) {
          if (item is Map<String, dynamic>) return encryptJson(item);
          return item;
        }).toList();
      }
    }
    return result;
  }

  /// Decrypts sensitive fields in a Map recursively.
  static Map<String, dynamic> decryptJson(Map<String, dynamic> json) {
    final Map<String, dynamic> result = Map.from(json);
    for (var key in result.keys) {
      if (AppConfig.sensitiveFields.contains(key)) {
        if (result[key] != null && result[key] is String) {
          result[key] = decrypt(result[key]);
        }
      } else if (result[key] is Map<String, dynamic>) {
        result[key] = decryptJson(result[key]);
      } else if (result[key] is List) {
        result[key] = result[key].map((item) {
          if (item is Map<String, dynamic>) return decryptJson(item);
          return item;
        }).toList();
      }
    }
    return result;
  }
}
