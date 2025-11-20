import 'package:get/get.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/websocket_service.dart';
import '../../core/utils/logger.dart';
import '../../data/models/broadcast_message.dart';
import '../../data/repositories/message_repository.dart';
import '../../services/auth_service.dart';

class MessageDetailController extends GetxController {
  final Logger _logger = Logger('MessageDetailController');
  final MessageRepository _messageRepository = MessageRepository();
  final AuthService _authService = Get.find<AuthService>();
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  final BroadcastMessage message;

  // Observable state
  final RxBool isAcknowledged = false.obs;
  final RxBool isAcknowledging = false.obs;
  final RxString errorMessage = ''.obs;

  MessageDetailController({required this.message});

  /// Acknowledge the message
  Future<void> acknowledgeMessage() async {
    if (isAcknowledged.value || isAcknowledging.value) {
      return;
    }

    try {
      isAcknowledging.value = true;
      errorMessage.value = '';

      final user = _authService.currentUser.value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call API to acknowledge message
      await _messageRepository.acknowledgeMessage(message.messageId, user.id);

      // Send acknowledgement via WebSocket
      await _wsService.acknowledgeMessage(message.messageId, user.id);

      // Stop notifications
      await _notificationService.stopNotification(message.messageId);

      // Update state
      isAcknowledged.value = true;

      _logger.info('Message acknowledged: ${message.messageId}');

      // Show success message
      Get.snackbar(
        'Success',
        'Message acknowledged',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // Go back after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.back();
      });
    } catch (e) {
      _logger.error('Error acknowledging message', e);
      errorMessage.value = e.toString();

      Get.snackbar(
        'Error',
        'Failed to acknowledge message: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isAcknowledging.value = false;
    }
  }

  /// Get color for message level
  String getLevelColor() {
    switch (message.level.toLowerCase()) {
      case 'low':
        return 'green';
      case 'medium':
        return 'orange';
      case 'high':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Get display name for message level
  String getLevelDisplayName() {
    return message.level.toUpperCase();
  }
}
