import 'package:get/get.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/websocket_service.dart';
import '../../core/utils/logger.dart';
import '../../data/models/broadcast_message.dart';
import '../../data/repositories/message_repository.dart';
import '../../services/auth_service.dart';

class MessageInboxController extends GetxController {
  final Logger _logger = Logger('MessageInboxController');
  final MessageRepository _messageRepository = MessageRepository();
  final AuthService _authService = Get.find<AuthService>();
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  // Observable state
  final RxList<BroadcastMessage> messages = <BroadcastMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxMap<String, bool> acknowledgedMessages = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMessages();
    _listenToWebSocket();
  }

  /// Load message history from API
  Future<void> _loadMessages() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _authService.currentUser.value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final fetchedMessages = await _messageRepository.getMessageHistory(
        organizationId: user.organizationId,
        userId: user.id,
        limit: 100,
      );

      messages.value = fetchedMessages;
      _logger.info('Loaded ${messages.length} messages');
    } catch (e) {
      _logger.error('Error loading messages', e);
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh messages (pull-to-refresh)
  Future<void> refreshMessages() async {
    try {
      isRefreshing.value = true;
      errorMessage.value = '';

      final user = _authService.currentUser.value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final fetchedMessages = await _messageRepository.getMessageHistory(
        organizationId: user.organizationId,
        userId: user.id,
        limit: 100,
      );

      messages.value = fetchedMessages;
      _logger.info('Refreshed ${messages.length} messages');
    } catch (e) {
      _logger.error('Error refreshing messages', e);
      errorMessage.value = e.toString();
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Listen to WebSocket for new messages
  void _listenToWebSocket() {
    _wsService.messageStream.listen((message) {
      _logger.info('Received new message via WebSocket: ${message.messageId}');

      // Add new message to the top of the list
      messages.insert(0, message);

      // Trigger notification
      _notificationService.triggerNotification(message);
    });
  }

  /// Check if a message is acknowledged
  bool isMessageAcknowledged(String messageId) {
    return acknowledgedMessages[messageId] ?? false;
  }

  /// Mark message as acknowledged locally
  void markAsAcknowledged(String messageId) {
    acknowledgedMessages[messageId] = true;
  }

  /// Get color for message level
  String getLevelColor(String level) {
    switch (level.toLowerCase()) {
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
}
