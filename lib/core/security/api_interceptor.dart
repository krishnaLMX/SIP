import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../security/encryption_service.dart';
import '../security/secure_storage_service.dart';
import '../security/session_manager.dart';
import '../security/secure_logger.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

class ApiSecurityInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;

    // Rule 8: Offline Handling - Strict check for Production
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        SecureLogger.e('OFFLINE BLOCK: skipping request to ${options.path}');
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'No internet connection',
            type: DioExceptionType.connectionError,
          ),
        );
      }
    } catch (e) {
      SecureLogger.d('Connectivity check error: $e');
    }

    // 1. Attach Authorization token (except for auth endpoints)
    if (!path.contains('/auth/')) {
      String? token = await SecureStorageService.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // 2. Encryption for sensitive Request endpoints
    bool shouldEncrypt =
        AppConfig.encryptedEndpoints.any((e) => path.contains(e));

    if (shouldEncrypt) {
      if (options.data != null && options.data is Map<String, dynamic>) {
        final originalDataStr = options.data.toString();
        try {
          options.data = EncryptionService.encryptJson(options.data);
          bool dataChanged = originalDataStr != options.data.toString();
          if (dataChanged) {
            SecureLogger.d(
                'SECURE LAYER: Payload encrypted effectively for $path');
          } else {
            SecureLogger.d(
                'SECURE LAYER: Encryption matched but no sensitive fields found for $path');
          }
        } catch (e) {
          SecureLogger.e('ENCRYPTION ERROR: $e');
        }
      }
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    SecureLogger.logResponse(response);

    // 3. Decryption for sensitive Response endpoints
    final path = response.requestOptions.path;
    bool shouldDecrypt =
        AppConfig.encryptedEndpoints.any((e) => path.contains(e));

    if (shouldDecrypt &&
        response.data != null &&
        response.data is Map<String, dynamic>) {
      response.data = EncryptionService.decryptJson(response.data);
      SecureLogger.d('Response decrypted for: $path');
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    SecureLogger.logError(err);

    // 4. Global Error Handling
    if (err.response?.statusCode == 401) {
      // 5. Session Expired handling
      await SessionManager.logout();
      // Logic for session expired message would go here or be handled by state
    }

    // Global messages based on rule 7
    SecureLogger.e('DIO ERROR: [${err.type}] ${err.error}');
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      SecureLogger.e('Network connection lost or timeout');
    }

    return handler.next(err);
  }
}
