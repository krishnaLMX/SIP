import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides a stable, never-null device identifier.
///
/// Strategy (in order of preference):
///   1. Return cached ID from SecureStorage (fastest, consistent across calls)
///   2. Try to read hardware ID from device_info_plus
///   3. Fall back to a UUID generated once and persisted — guarantees never null
///
/// Why not rely on androidInfo.id alone?
///   - Android 10+ restricts hardware identifiers for non-privileged apps.
///   - androidInfo.id can return null on some OEM devices.
///   - identifierForVendor (iOS) is null when running in some simulators.
///
/// The generated UUID persists across sessions and is only lost on app
/// uninstall + reinstall (acceptable — a new install is effectively a
/// new device registration).
class DeviceIdService {
  DeviceIdService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyDeviceId = 'persistent_device_id';
  static const _keyDeviceType = 'persistent_device_type';

  // In-memory cache so repeated calls within a session are instant.
  static String? _cachedId;
  static String? _cachedType;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a stable, non-null device ID.
  /// Generates and persists a UUID on first call if hardware ID is unavailable.
  static Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    // 1. Check SecureStorage first
    final stored = await _storage.read(key: _keyDeviceId);
    if (stored != null && stored.isNotEmpty) {
      _cachedId = stored;
      return _cachedId!;
    }

    // 2. Try hardware ID
    String? hardwareId;
    try {
      if (!kIsWeb) {
        final plugin = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final info = await plugin.androidInfo;
          // androidInfo.id may be null on Android 10+ restricted devices
          hardwareId = info.id.isNotEmpty ? info.id : null;
        } else if (Platform.isIOS) {
          final info = await plugin.iosInfo;
          hardwareId = info.identifierForVendor;
        }
      }
    } catch (e) {
      debugPrint('[DeviceId] Hardware ID read failed: $e');
    }

    // 3. Generate a UUID if hardware ID is null/empty
    final id = (hardwareId != null && hardwareId.isNotEmpty)
        ? hardwareId
        : _generateUuid();

    // 4. Persist so future calls are always consistent
    await _storage.write(key: _keyDeviceId, value: id);
    _cachedId = id;
    debugPrint('[DeviceId] ID resolved: $id');
    return id;
  }

  /// Returns platform type string: "android" | "ios" | "web" | "other"
  static Future<String> getDeviceType() async {
    if (_cachedType != null) return _cachedType!;

    final stored = await _storage.read(key: _keyDeviceType);
    if (stored != null) {
      _cachedType = stored;
      return _cachedType!;
    }

    String type = 'other';
    if (kIsWeb) {
      type = 'web';
    } else if (Platform.isAndroid) {
      type = 'android';
    } else if (Platform.isIOS) {
      type = 'ios';
    }

    await _storage.write(key: _keyDeviceType, value: type);
    _cachedType = type;
    return type;
  }

  // In-memory cache for device info
  static Map<String, String>? _cachedDeviceInfo;

  /// Returns device metadata: model, name, OS, OS version.
  /// Cached after the first call for performance.
  static Future<Map<String, String>> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) return _cachedDeviceInfo!;

    String deviceModel = 'unknown';
    String deviceName = 'unknown';
    String os = 'unknown';
    String osVersion = 'unknown';

    try {
      if (!kIsWeb) {
        final plugin = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final info = await plugin.androidInfo;
          deviceModel = info.model;           // e.g. "Pixel 7"
          deviceName = info.device;           // e.g. "panther"
          os = 'Android';
          osVersion = info.version.release;   // e.g. "14"
        } else if (Platform.isIOS) {
          final info = await plugin.iosInfo;
          deviceModel = info.utsname.machine; // e.g. "iPhone15,2"
          deviceName = info.name;             // e.g. "John's iPhone"
          os = 'iOS';
          osVersion = info.systemVersion;     // e.g. "17.2"
        }
      }
    } catch (e) {
      debugPrint('[DeviceId] Device info read failed: $e');
    }

    _cachedDeviceInfo = {
      'device_model': deviceModel,
      'device_name': deviceName,
      'os': os,
      'os_version': osVersion,
    };
    return _cachedDeviceInfo!;
  }

  // ── UUID Generator ─────────────────────────────────────────────────────────
  // Simple RFC 4122 v4 UUID without external dependency.
  // Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx

  static String _generateUuid() {
    const chars = '0123456789abcdef';
    final r = _Rng();
    String s = '';
    for (int i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) s += '-';
      if (i == 12) {
        s += '4'; // version 4
      } else if (i == 16) {
        s += chars[(r.next() & 0x3) | 0x8]; // variant bits
      } else {
        s += chars[r.next() & 0xF];
      }
    }
    return s;
  }
}

/// Minimal xorshift RNG — avoids dart:math Random dependency issues.
class _Rng {
  // Seed using DateTime for uniqueness
  int _state = DateTime.now().microsecondsSinceEpoch ^ 0xDEADBEEF;

  int next() {
    _state ^= _state << 13;
    _state ^= _state >> 17;
    _state ^= _state << 5;
    return _state.abs();
  }
}
