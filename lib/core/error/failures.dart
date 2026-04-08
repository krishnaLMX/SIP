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
      
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        if (status == 401 || status == 403) {
          return AuthenticationFailure();
        }
        if (status != null && status >= 500) {
          return ServerFailure(statusCode: status);
        }
        return ServerFailure(
          message: err.response?.data?['message'] ?? 'Server error code: $status',
          statusCode: status
        );

      case DioExceptionType.cancel:
        return InvalidResponseFailure('Request cancelled');
      
      default:
        return ServerFailure(message: 'Something went wrong. Please try again later.');
    }
  }
}
