import 'package:dio/dio.dart';

abstract class Failure {
  final String message;
  final int? statusCode;

  Failure(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  NetworkFailure([String? message]) : super(message ?? 'Network connection lost');
}

class ServerFailure extends Failure {
  ServerFailure({String? message, int? statusCode}) 
    : super(message ?? 'Server temporarily unavailable', statusCode: statusCode);
}

class AuthenticationFailure extends Failure {
  AuthenticationFailure([String? message]) : super(message ?? 'Session expired');
}

/// Thrown when the server returns **409 Conflict** with SESSION_INVALIDATED.
/// The interceptor handles the dialog + forced logout automatically;
/// this failure type allows callers to silently swallow the error in
/// their catch blocks instead of showing duplicate error UI.
class SessionInvalidatedFailure extends Failure {
  SessionInvalidatedFailure([String? message])
      : super(message ?? 'Session invalidated. Please log in again.');
}

class InvalidResponseFailure extends Failure {
  InvalidResponseFailure([String? message]) : super(message ?? 'Invalid response from server');
}

class ApiFailureMapper {
  static Failure map(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure();

      // 409 session-invalidated errors are rejected as `cancel` by the
      // interceptor. Map them to SessionInvalidatedFailure so callers
      // can silently ignore (the interceptor already shows the dialog).
      case DioExceptionType.cancel:
        if (err.error?.toString().contains('Session invalidated') == true) {
          return SessionInvalidatedFailure();
        }
        return InvalidResponseFailure('Request cancelled');
      
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        if (status == 409) {
          return SessionInvalidatedFailure();
        }
        if (status == 401 || status == 403) {
          return AuthenticationFailure();
        }
        if (status != null && status >= 500) {
          return ServerFailure(statusCode: status);
        }
        // Extract message from nested error structures:
        // { "error": { "message": "..." } } or { "data": { "message": "..." } }
        final responseData = err.response?.data;
        String? serverMessage;
        if (responseData is Map<String, dynamic>) {
          serverMessage = responseData['message']?.toString() ??
              (responseData['error'] as Map<String, dynamic>?)?['message']
                  ?.toString() ??
              (responseData['data'] as Map<String, dynamic>?)?['message']
                  ?.toString();
        }
        return ServerFailure(
          message: serverMessage ?? 'Server error code: $status',
          statusCode: status,
        );
      
      default:
        return ServerFailure(message: 'Something went wrong. Please try again later.');
    }
  }
}
