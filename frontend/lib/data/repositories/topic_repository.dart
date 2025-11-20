import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../models/topic.dart';

class TopicRepository {
  final DioClient _dioClient = DioClient();

  Future<List<Topic>> getTopics(String orgId) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/organizations/$orgId/topics',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final topicsList = data['topics'] as List;
        return topicsList.map((json) => Topic.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch topics: ${response.statusCode}');
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
        throw Exception('Failed to fetch topics: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Topic> createTopic({
    required String orgId,
    required String name,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/organizations/$orgId/topics',
        data: {'name': name},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Topic.fromJson(data);
      } else {
        throw Exception('Failed to create topic: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid input';
        throw Exception(message);
      } else if (e.response?.statusCode == 403) {
        throw Exception('You do not have permission to create topics');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Organization not found');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please try again later.');
      } else {
        throw Exception('Failed to create topic: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<void> assignUserToTopic({
    required String orgId,
    required String topicId,
    required String userId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/organizations/$orgId/topics/$topicId/users',
        data: {'userId': userId},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to assign user to topic: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid input';
        throw Exception(message);
      } else if (e.response?.statusCode == 403) {
        throw Exception('You do not have permission to assign users to topics');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Topic or user not found');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please try again later.');
      } else {
        throw Exception('Failed to assign user to topic: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
