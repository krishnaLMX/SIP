import 'package:encrypt/encrypt.dart';
import '../config/app_config.dart';

class EncryptionService {
  static final _key = Key.fromUtf8(AppConfig.encryptionKey);
  static final _iv = IV
      .fromLength(16); // In production, use random IV and send it with payload
  static final _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  /// Encrypts a string using AES-256
  static String encrypt(String plainText) {
    if (plainText.isEmpty) return plainText;
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts a base64 string using AES-256
  static String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    try {
      final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      // If decryption fails, it might not be encrypted or key mismatch
      return encryptedText;
    }
  }

  /// Encrypts specific sensitive fields within a Map
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
          if (item is Map<String, dynamic>) {
            return encryptJson(item);
          }
          return item;
        }).toList();
      }
    }
    return result;
  }

  /// Decrypts specific sensitive fields within a Map
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
          if (item is Map<String, dynamic>) {
            return decryptJson(item);
          }
          return item;
        }).toList();
      }
    }
    return result;
  }
}
