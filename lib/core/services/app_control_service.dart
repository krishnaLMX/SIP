import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Fetches app runtime control data from the backend.
/// Endpoint: GET app/control
/// No auth required — called before user is logged in.
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

  /// Fetches version + alert from backend.
  /// Returns raw [Map] or null if network fails (handled gracefully).
  Future<Map<String, dynamic>?> fetchAppControl() async {
    try {
      final response = await _dio.get('app/control');
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
