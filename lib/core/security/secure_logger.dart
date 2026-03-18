import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';

class SecureLogger {
  /// Simple debug print that hides sensitive info
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('[SIP SECURE LOG]: $message');
    }
  }

  /// Simple error print that hides sensitive info
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[SIP SECURE ERROR]: $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }

  /// Logs Request while scrubbing sensitive info
  static void logRequest(RequestOptions options) {
    if (kDebugMode) {
      final scrubbedOptions = _scrubSensitiveData(options.data);
      debugPrint('[NETWORK REQUEST]: [${options.method}] ${options.uri}');
      if (scrubbedOptions != null) {
        debugPrint('Payload: $scrubbedOptions');
      }
    }
  }

  /// Logs Response while scrubbing sensitive info
  static void logResponse(Response response) {
    if (kDebugMode) {
      final scrubbedData = _scrubSensitiveData(response.data);
      debugPrint(
          '[NETWORK RESPONSE]: [${response.statusCode}] ${response.requestOptions.uri}');
      if (scrubbedData != null) {
        debugPrint('Data: $scrubbedData');
      }
    }
  }

  /// Logs Error while scrubbing sensitive info
  static void logError(DioException err) {
    if (kDebugMode) {
      debugPrint(
          '[NETWORK ERROR]: [${err.response?.statusCode}] ${err.requestOptions.uri}');
      if (err.response?.data != null) {
        final scrubbedData = _scrubSensitiveData(err.response?.data);
        debugPrint('Error Data: $scrubbedData');
      }
    }
  }

  /// Scrubs sensitive data from any input (Map, List, or Map nested in List)
  static dynamic _scrubSensitiveData(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      final Map<String, dynamic> scrubbed = Map.from(data);
      for (var key in scrubbed.keys) {
        if (AppConfig.sensitiveFields.contains(key)) {
          scrubbed[key] = '[REDACTED]';
        } else if (scrubbed[key] is Map<String, dynamic>) {
          scrubbed[key] = _scrubSensitiveData(scrubbed[key]);
        } else if (scrubbed[key] is List) {
          scrubbed[key] = _scrubSensitiveData(scrubbed[key]);
        }
      }
      return scrubbed;
    } else if (data is List) {
      return data.map((item) => _scrubSensitiveData(item)).toList();
    }

    return data;
  }
}
