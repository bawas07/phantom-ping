import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/logger.dart';
import '../models/broadcast_message.dart';

/// Repository for message-related API operations
class MessageRepository {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final Logger _logger = Logger('MessageRepository');

  /// Get message history for the current user
  ///
  /// [organizationId] - Organization ID to filter messages
  /// [userId] - User ID to get messages for
  /// [limit] - Optional limit on number of messages to return
  ///
  /// Returns list of broadcast messages
  /// Throws [ApiException] on error
  Future<List<BroadcastMessage>> getMessageHistory({
    required String organizationId,
    required String userId,
    int? limit,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/messages/history',
        queryParameters: {
          'organizationId': organizationId,
          'userId': userId,
          if (limit != null) 'limit': limit,
        },
      );

      // Handle standard API response format: {status: true, data: {...}}
      if (response['status'] == true && response['data'] != null) {
        final messagesData = response['data']['messages'] as List;
        return messagesData
            .map(
              (json) => BroadcastMessage.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw UnknownException('Invalid response format');
      }
    } on ApiException catch (e) {
      _logger.error('Error fetching message history: ${e.message}', e);
      rethrow;
    } catch (e) {
      _logger.error('Unexpected error fetching message history', e);
      throw UnknownException('Failed to fetch message history: $e');
    }
  }

  /// Acknowledge a message
  ///
  /// [messageId] - ID of the message to acknowledge
  /// [userId] - ID of the user acknowledging the message
  ///
  /// Throws [ApiException] on error
  Future<void> acknowledgeMessage(String messageId, String userId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/messages/$messageId/acknowledge',
        data: {'userId': userId},
      );

      // Handle standard API response format
      if (response['status'] != true) {
        throw UnknownException(
          response['message'] as String? ?? 'Failed to acknowledge message',
        );
      }
    } on ApiException catch (e) {
      _logger.error('Error acknowledging message: ${e.message}', e);
      rethrow;
    } catch (e) {
      _logger.error('Unexpected error acknowledging message', e);
      throw UnknownException('Failed to acknowledge message: $e');
    }
  }
}
