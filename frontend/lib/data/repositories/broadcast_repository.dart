import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';

class BroadcastRepository {
  final DioClient _dioClient = DioClient();

  Future<Map<String, dynamic>> sendBroadcast({
    required String level,
    required String title,
    required String message,
    String? code,
    required String scope,
    String? topicId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/broadcast',
        data: {
          'level': level,
          'title': title,
          'message': message,
          if (code != null && code.isNotEmpty) 'code': code,
          'scope': scope,
          if (topicId != null) 'topicId': topicId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to send broadcast: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid input';
        throw Exception(message);
      } else if (e.response?.statusCode == 403) {
        throw Exception('You do not have permission to send broadcasts');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please try again later.');
      } else {
        throw Exception('Failed to send broadcast: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
