import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

class AppLogger {
  static void d(String message) {
    if (kDebugMode) {
      dev.log('DEBUG: $message', name: 'APP_LOG');
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    // In production, you might send this to Sentry or Firebase Crashlytics
    dev.log(
      'ERROR: $message',
      name: 'APP_LOG',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void i(String message) {
    dev.log('INFO: $message', name: 'APP_LOG');
  }

  // Prevents sensitive logs in release mode
  static void sensitive(String message) {
    if (kDebugMode) {
      dev.log('SENSITIVE: $message', name: 'APP_LOG');
    }
  }
}
