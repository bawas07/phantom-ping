import 'package:dio/dio.dart';

import '../../services/storage_service.dart';
import '../../utils/logger.dart';

/// Interceptor for handling authentication tokens
/// Automatically adds access token to requests and refreshes expired tokens
class AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final Dio _dio;
  final Logger _logger = Logger('AuthInterceptor');

  AuthInterceptor(this._storageService, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for login and refresh endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    // Add access token to request headers
    final accessToken = await _storageService.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - attempt token refresh
    if (err.response?.statusCode == 401) {
      _logger.info('Received 401, attempting token refresh');

      try {
        // Try to refresh the token
        final refreshed = await _refreshToken();

        if (refreshed) {
          // Retry the original request with new token
          final response = await _retry(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (e) {
        _logger.error('Token refresh failed', e);
        // Clear tokens and let the error propagate
        await _storageService.clearTokens();
      }
    }

    handler.next(err);
  }

  /// Refresh the access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        _logger.warning('No refresh token available');
        return false;
      }

      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {'Authorization': null}, // Don't send old access token
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['data']?['accessToken'] as String?;
        final newRefreshToken = data['data']?['refreshToken'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await _storageService.saveTokens(newAccessToken, newRefreshToken);
          _logger.info('Token refreshed successfully');
          return true;
        }
      }

      return false;
    } catch (e) {
      _logger.error('Error refreshing token', e);
      return false;
    }
  }

  /// Retry the failed request with new token
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final accessToken = await _storageService.getAccessToken();

    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $accessToken',
      },
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
