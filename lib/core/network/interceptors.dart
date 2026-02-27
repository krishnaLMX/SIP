import 'package:dio/dio.dart';
import '../security/secure_storage_service.dart';
import '../security/session_manager.dart';
import '../utils/logger.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    String? token = await SecureStorageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    AppLogger.d('NETWORK REQUEST: [${options.method}] ${options.uri}');
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d(
      'NETWORK RESPONSE: [${response.statusCode}] ${response.requestOptions.uri}',
    );
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    AppLogger.e(
      'NETWORK ERROR: [${err.response?.statusCode}] ${err.requestOptions.uri}',
    );

    if (err.response?.statusCode == 401) {
      // Access token expired, global logout mechanism
      await SessionManager.logout();
      // Logic to redirect to login would ideally be here via a Global Navigator Key
      // but logout clears session and main.dart handles initial state.
    }
    return handler.next(err);
  }
}
