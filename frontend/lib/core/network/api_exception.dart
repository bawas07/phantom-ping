import 'package:dio/dio.dart';

/// Base class for all API exceptions
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

/// Exception thrown when network connection fails
class NetworkException extends ApiException {
  NetworkException([super.message = 'Network connection failed']);
}

/// Exception thrown when request times out
class TimeoutException extends ApiException {
  TimeoutException([super.message = 'Request timeout']);
}

/// Exception thrown for unauthorized access (401)
class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Unauthorized access'])
    : super(statusCode: 401);
}

/// Exception thrown for forbidden access (403)
class ForbiddenException extends ApiException {
  ForbiddenException([super.message = 'Access forbidden'])
    : super(statusCode: 403);
}

/// Exception thrown when resource not found (404)
class NotFoundException extends ApiException {
  NotFoundException([super.message = 'Resource not found'])
    : super(statusCode: 404);
}

/// Exception thrown for validation errors (400, 422)
class ValidationException extends ApiException {
  ValidationException(super.message, {super.data}) : super(statusCode: 400);
}

/// Exception thrown for server errors (500+)
class ServerException extends ApiException {
  ServerException([super.message = 'Server error occurred'])
    : super(statusCode: 500);
}

/// Exception thrown for unknown errors
class UnknownException extends ApiException {
  UnknownException([super.message = 'An unknown error occurred']);
}

/// Helper class to convert DioException to custom ApiException
class ApiExceptionHandler {
  static ApiException handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Request timeout. Please try again.');

      case DioExceptionType.connectionError:
        return NetworkException(
          'Network connection failed. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return UnknownException('Request was cancelled');

      default:
        return UnknownException(error.message ?? 'An unknown error occurred');
    }
  }

  static ApiException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Try to extract error message from response
    String message = 'An error occurred';
    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? message;
    }

    switch (statusCode) {
      case 400:
      case 422:
        return ValidationException(message, data: data);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(message);
      default:
        return UnknownException(message);
    }
  }
}
