import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../../core/config/app_config.dart';
import '../security/encryption_service.dart';
import '../security/secure_storage_service.dart';
import '../security/session_manager.dart';
import '../security/secure_logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../shared/widgets/session_invalidated_dialog.dart';

class ApiSecurityInterceptor extends Interceptor {
  // ── Public Key Bootstrap ─────────────────────────────────────────────────
  /// Fetches the RSA public key from the server and caches it.
  /// Safe to call multiple times – skips fetch if already loaded.
  static Future<void> fetchAndCachePublicKey() async {
    if (EncryptionService.isRsaReady) return; // already loaded

    // First, try to load from local secure cache
    await EncryptionService.loadPublicKey();
    if (EncryptionService.isRsaReady) return;

    // Not in cache – fetch from server
    SecureLogger.d('ENCRYPTION: Fetching RSA public key from server...');
    try {
      final plainDio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

      final response = await plainDio.get(AppConfig.publicKeyEndpoint);

      if (response.statusCode == 200 && response.data != null) {
        // Attempt to extract from root ('public_key') or from nested 'data' ('data' -> 'public_key')
        final dynamic respData = response.data;
        final String? publicKey = respData is Map
            ? (respData['public_key'] ?? respData['data']?['public_key'])
            : null;

        if (publicKey != null && publicKey.isNotEmpty) {
          await EncryptionService.setPublicKeyFromServer(pemKey: publicKey);
          SecureLogger.d(
              'ENCRYPTION: RSA public key fetched and cached successfully.');
        } else {
          SecureLogger.e(
              'ENCRYPTION: Public key not found in API response. Sensitive requests will fail.');
        }
      } else {
        SecureLogger.e(
            'ENCRYPTION: Server returned unexpected response for public key endpoint.');
      }
    } on DioException catch (e) {
      SecureLogger.e(
          'ENCRYPTION: Failed to fetch RSA public key (DioException: ${e.type}). Sensitive requests will fail until key is fetched.');
    } catch (e) {
      SecureLogger.e(
          'ENCRYPTION: Unexpected error fetching RSA public key: $e');
    }
  }

  // ── Request Interceptor ──────────────────────────────────────────────────
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    SecureLogger.logRequest(options);

    // Rule 8: Offline Handling
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

    // 1. Ensure RSA public key is loaded before any sensitive request
    final isSensitive =
        AppConfig.encryptedEndpoints.any((e) => path.contains(e));
    if (isSensitive && !EncryptionService.isRsaReady) {
      // Attempt a last-chance fetch (non-blocking on failure)
      await fetchAndCachePublicKey();
    }

    // 2. Attach Authorization token (except auth and public endpoints)
    if (!path.contains('/auth/') && !path.contains('shared/country-codes')) {
      String? token = await SecureStorageService.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // 3. Encrypt sensitive fields for designated endpoints
    if (isSensitive) {
      if (options.data != null && options.data is Map) {
        final originalDataStr = options.data.toString();
        try {
          // Safe cast to Map<String, dynamic> for the encryption service
          final mapData = Map<String, dynamic>.from(options.data);
          options.data = EncryptionService.encryptJson(mapData);
          final dataChanged = originalDataStr != options.data.toString();
          final algo =
              EncryptionService.isRsaReady ? 'RSA-OAEP-SHA256' : 'AES-256-CBC';
          SecureLogger.d(
              'SECURE LAYER: Payload ${dataChanged ? 'encrypted ($algo)' : 'has no sensitive fields'} for $path');
        } catch (e) {
          SecureLogger.e('ENCRYPTION ERROR: $e');
        }
      }
    }

    return handler.next(options);
  }

  // ── Response Interceptor ─────────────────────────────────────────────────
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    SecureLogger.logResponse(response);

    final path = response.requestOptions.path;
    final shouldDecrypt =
        AppConfig.encryptedEndpoints.any((e) => path.contains(e));

    if (shouldDecrypt &&
        response.data != null &&
        response.data is Map) {
      // Safe cast
      final mapData = Map<String, dynamic>.from(response.data);
      response.data = EncryptionService.decryptJson(mapData);
      SecureLogger.d('SECURE LAYER: Response decrypted (AES-256) for $path');
    }

    return handler.next(response);
  }

  // ── Error Interceptor ────────────────────────────────────────────────────
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    SecureLogger.logError(err);

    // 4. Silent Token Refresh on 401
    if (err.response?.statusCode == 401) {
      final refreshToken = await SecureStorageService.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        SecureLogger.d('TOKEN REFRESH: Attempting silent refresh...');
        try {
          final refreshDio = Dio(BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout:
                const Duration(milliseconds: AppConfig.connectTimeout),
            receiveTimeout:
                const Duration(milliseconds: AppConfig.receiveTimeout),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ));

          final refreshResponse = await refreshDio.post(
            'users/auth/token/refresh',
            data: {'refresh': refreshToken},
          );

          if (refreshResponse.statusCode == 200 &&
              refreshResponse.data['success'] == true) {
            final newAccess = refreshResponse.data['data']['access'];
            final newRefresh = refreshResponse.data['data']['refresh'];

            await SecureStorageService.saveToken(newAccess);
            await SecureStorageService.saveRefreshToken(newRefresh);
            SecureLogger.d(
                'TOKEN REFRESH: Success. Retrying original request.');

            final retryOptions = err.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newAccess';

            final retryResponse = await refreshDio.fetch(retryOptions);
            return handler.resolve(retryResponse);
          } else {
            SecureLogger.e(
                'TOKEN REFRESH: Server rejected refresh. Logging out.');
            await SessionManager.logout();
          }
        } catch (e) {
          SecureLogger.e('TOKEN REFRESH: Failed with error: $e. Logging out.');
          await SessionManager.logout();
        }
      } else {
        SecureLogger.e('TOKEN REFRESH: No refresh token found. Logging out.');
        await SessionManager.logout();
      }
    }

    // 5. Session Invalidated on 409 Conflict (logged in from another device)
    if (err.response?.statusCode == 409) {
      final data = err.response?.data;
      if (data is Map && data['error']?['code'] == 'session_invalidated') {
        final serverMsg =
            data['error']?['message'] as String? ?? '';
        SecureLogger.e(
            'SESSION INVALIDATED: 409 Conflict — $serverMsg');

        // Show the premium dialog on the UI thread.
        // Use addPostFrameCallback so we never call into the widget
        // tree from inside a Dio async handler.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SessionInvalidatedDialog.show(message: serverMsg);
        });
      }
    }

    // Global error info (Rule 7)
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      SecureLogger.e('Network connection lost or timeout (${err.type})');
    }

    return handler.next(err);
  }
}
