import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/logger.dart';
import '../models/auth_response.dart';

/// Repository for authentication-related API calls
class AuthRepository {
  final DioClient _dioClient = DioClient();
  final Logger _logger = Logger('AuthRepository');

  /// Authenticates a user with PIN and organization ID
  ///
  /// Throws [Exception] with user-friendly message on failure
  Future<AuthResponse> login(String pin, String organizationId) async {
    try {
      _logger.info('Attempting login for organization: $organizationId');

      final response = await _dioClient.dio.post(
        ApiConstants.loginEndpoint,
        data: {'pin': pin, 'organizationId': organizationId},
      );

      if (response.statusCode == 200) {
        _logger.info('Login successful');
        return AuthResponse.fromJson(response.data);
      } else {
        _logger.warning('Login failed with status: ${response.statusCode}');
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.error('Login DioException', e);

      if (e.response?.statusCode == 401) {
        throw Exception('Invalid PIN or Organization ID');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please try again later.');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      _logger.error('Unexpected login error', e);
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Logs out the current user
  ///
  /// Does not throw exceptions - logout should always succeed locally
  Future<void> logout(String refreshToken) async {
    try {
      _logger.info('Attempting logout');

      await _dioClient.dio.post(
        ApiConstants.logoutEndpoint,
        data: {'refreshToken': refreshToken},
      );

      _logger.info('Logout successful');
    } on DioException catch (e) {
      // Log error but don't throw - logout should always succeed locally
      _logger.warning('Logout API call failed: ${e.message}');
    } catch (e) {
      _logger.error('Unexpected logout error', e);
    }
  }
}
