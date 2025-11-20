import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/organization.dart';
import '../models/organization_create_response.dart';
import '../models/user.dart';

/// Repository for managing organization-related API calls
/// Handles user management, role updates, and ownership transfers
class OrganizationRepository {
  final DioClient _dioClient;

  OrganizationRepository({DioClient? dioClient})
    : _dioClient = dioClient ?? DioClient();

  /// Handles Dio exceptions and converts them to custom exceptions
  Never _handleError(DioException e, String operation) {
    if (e.response?.statusCode == 400) {
      final message = e.response?.data['message'] ?? 'Invalid input';
      throw ValidationException(message: message);
    } else if (e.response?.statusCode == 401) {
      throw AuthException();
    } else if (e.response?.statusCode == 403) {
      final message =
          e.response?.data['message'] ??
          'You do not have permission to perform this action';
      throw PermissionException(message: message);
    } else if (e.response?.statusCode == 404) {
      final message = e.response?.data['message'] ?? 'Resource not found';
      throw NotFoundException(message: message);
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw TimeoutException();
    } else if (e.type == DioExceptionType.connectionError) {
      throw NetworkException(
        message: 'Unable to connect to server. Please try again later.',
      );
    } else {
      throw ApiException(
        message: 'Failed to $operation: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Creates a new organization with an owner user
  ///
  /// [organizationId] must be unique and max 15 characters
  /// Returns [OrganizationCreateResponse] with organization details and owner PIN
  /// Throws [ValidationException] if organization ID already exists or is invalid
  Future<OrganizationCreateResponse> createOrganization({
    required String organizationId,
    required String organizationName,
    required String ownerName,
    required String ownerEmail,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/organizations',
        data: {
          'organizationId': organizationId,
          'organizationName': organizationName,
          'ownerName': ownerName,
          'ownerEmail': ownerEmail,
        },
      );
      return OrganizationCreateResponse.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleError(e, 'create organization');
    }
  }

  /// Fetches organization statistics including user count and topic count
  ///
  /// Throws [ApiException] or its subclasses if the request fails
  Future<Map<String, dynamic>> getOrganizationStats(String orgId) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/organizations/$orgId/stats',
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e, 'fetch organization stats');
    }
  }

  /// Fetches organization details by ID
  ///
  /// Returns [Organization] object with full organization information
  /// Throws [Exception] if the request fails or organization is not found
  Future<Organization> getOrganization(String orgId) async {
    try {
      final response = await _dioClient.dio.get('/api/organizations/$orgId');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Organization.fromJson(data);
      } else {
        throw Exception('Failed to fetch organization: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Organization not found');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please try again later.');
      } else {
        throw Exception('Failed to fetch organization: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Fetches all users in an organization
  ///
  /// Returns list of [User] objects
  /// Throws [Exception] if the request fails or organization is not found
  Future<List<User>> getUsers(String orgId) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/organizations/$orgId/users',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final usersList = data['users'] as List;
        return usersList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Organization not found');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please try again later.');
      } else {
        throw Exception('Failed to fetch users: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Registers a new user in the organization
  ///
  /// Returns a map containing the new user data and generated PIN
  /// [topicId] is required when registering a Supervisor
  /// Throws [Exception] if validation fails or user lacks permission
  Future<Map<String, dynamic>> registerUser({
    required String orgId,
    required String name,
    required String email,
    required String role,
    String? topicId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/organizations/$orgId/users',
        data: {
          'name': name,
          'email': email,
          'role': role,
          if (topicId != null) 'topicId': topicId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to register user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid input';
        throw Exception(message);
      } else if (e.response?.statusCode == 403) {
        throw Exception('You do not have permission to register users');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please try again later.');
      } else {
        throw Exception('Failed to register user: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Updates a user's role within the organization
  ///
  /// [topicId] is required when promoting to Supervisor role
  /// Throws [Exception] if validation fails, user not found, or lacks permission
  Future<void> updateUserRole({
    required String orgId,
    required String userId,
    required String role,
    String? topicId,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/organizations/$orgId/users/$userId/role',
        data: {'role': role, if (topicId != null) 'topicId': topicId},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user role: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid input';
        throw Exception(message);
      } else if (e.response?.statusCode == 403) {
        throw Exception('You do not have permission to update user roles');
      } else if (e.response?.statusCode == 404) {
        throw Exception('User not found');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please try again later.');
      } else {
        throw Exception('Failed to update user role: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Removes a user from the organization
  ///
  /// Throws [Exception] if user not found or lacks permission
  Future<void> kickUser({required String orgId, required String userId}) async {
    try {
      final response = await _dioClient.dio.delete(
        '/api/organizations/$orgId/users/$userId',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to kick user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('You do not have permission to kick users');
      } else if (e.response?.statusCode == 404) {
        throw Exception('User not found');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please try again later.');
      } else {
        throw Exception('Failed to kick user: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Transfers organization ownership to an existing Admin
  ///
  /// Only the current Owner can perform this action
  /// The new owner must already be an Admin
  /// Current owner will be demoted to Admin role
  /// Throws [Exception] if validation fails or user lacks permission
  Future<void> transferOwnership({
    required String orgId,
    required String newOwnerId,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/organizations/$orgId/ownership',
        data: {'newOwnerId': newOwnerId},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to transfer ownership: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message =
            e.response?.data['message'] ??
            'Can only transfer ownership to existing Admins';
        throw Exception(message);
      } else if (e.response?.statusCode == 403) {
        throw Exception('Only the Owner can transfer ownership');
      } else if (e.response?.statusCode == 404) {
        throw Exception('User not found');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please try again later.');
      } else {
        throw Exception('Failed to transfer ownership: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
