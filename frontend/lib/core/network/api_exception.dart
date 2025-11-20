/// Custom exception class for API-related errors
/// Provides structured error information with error codes and messages
class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.code, this.statusCode, this.data});

  factory ApiException.fromDioError(dynamic error) {
    if (error.response != null) {
      final response = error.response;
      final statusCode = response?.statusCode;
      final responseData = response?.data;

      String message = 'An error occurred';
      String? code;

      if (responseData is Map<String, dynamic>) {
        message = responseData['message'] ?? message;
        code = responseData['data']?['code'];
      }

      return ApiException(
        message: message,
        code: code,
        statusCode: statusCode,
        data: responseData,
      );
    }

    return ApiException(
      message: error.message ?? 'An unexpected error occurred',
      statusCode: null,
      code: null,
    );
  }

  @override
  String toString() {
    if (code != null) {
      return 'ApiException: $message (Code: $code, Status: $statusCode)';
    }
    return 'ApiException: $message (Status: $statusCode)';
  }
}

/// Exception for network connectivity issues
class NetworkException extends ApiException {
  NetworkException({String? message})
    : super(
        message: message ?? 'No internet connection. Please try again.',
        code: 'NETWORK_ERROR',
      );
}

/// Exception for timeout errors
class TimeoutException extends ApiException {
  TimeoutException({String? message})
    : super(
        message:
            message ??
            'Connection timeout. Please check your internet connection.',
        code: 'TIMEOUT_ERROR',
      );
}

/// Exception for authentication errors
class AuthException extends ApiException {
  AuthException({String? message})
    : super(
        message: message ?? 'Authentication failed. Please login again.',
        code: 'AUTH_ERROR',
        statusCode: 401,
      );
}

/// Exception for authorization/permission errors
class PermissionException extends ApiException {
  PermissionException({String? message})
    : super(
        message:
            message ?? 'You do not have permission to perform this action.',
        code: 'PERMISSION_ERROR',
        statusCode: 403,
      );
}

/// Exception for resource not found errors
class NotFoundException extends ApiException {
  NotFoundException({String? message})
    : super(
        message: message ?? 'The requested resource was not found.',
        code: 'NOT_FOUND',
        statusCode: 404,
      );
}

/// Exception for validation errors
class ValidationException extends ApiException {
  ValidationException({String? message})
    : super(
        message: message ?? 'Invalid input. Please check your data.',
        code: 'VALIDATION_ERROR',
        statusCode: 400,
      );
}
