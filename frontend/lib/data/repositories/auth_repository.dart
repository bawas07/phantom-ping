import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final DioClient _dioClient = DioClient();

  Future<AuthResponse> login(String pin, String organizationId) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.loginEndpoint,
        data: {'pin': pin, 'organizationId': organizationId},
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(response.data);
      } else {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
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
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.logoutEndpoint,
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      // Log error but don't throw - logout should always succeed locally
      print('Logout API call failed: ${e.message}');
    }
  }
}
