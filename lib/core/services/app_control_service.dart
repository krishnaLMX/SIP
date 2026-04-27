import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';

/// Fetches app runtime control data from the backend.
/// Endpoint: POST app/control
/// No auth required — called before user is logged in.
///
/// Sends `platform` ("android" | "ios" | "web") in the request body
/// so the server can return platform-specific configs.
class AppControlService {
  final Dio _dio;

  AppControlService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
          receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  /// Detect the current platform safely (handles web, android, ios).
  String get _platform {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'android'; // fallback
  }

  /// Fetches version + alert + maintenance from backend.
  /// Sends `{ "platform": "android" }` so server can return
  /// platform-specific version info, alerts, and maintenance status.
  ///
  /// Returns raw [Map] or null if network fails (handled gracefully).
  Future<Map<String, dynamic>?> fetchAppControl() async {
    try {
      final response = await _dio.post(
        'app/control',
        data: {'platform': _platform},
      );
      if (response.statusCode == 200 && response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      // Silent fail — app should continue working even if this endpoint is down
      debugLog('AppControlService: fetch failed (${e.type.name})');
      return null;
    } catch (e) {
      debugLog('AppControlService: unexpected error $e');
      return null;
    }
  }

  void debugLog(String msg) {
    // ignore: avoid_print
    assert(() {
      // ignore: avoid_print
      print('[AppControl] $msg');
      return true;
    }());
  }
}
