import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/broadcast_message.dart';
import 'websocket_service.dart';

/// Notification service that handles broadcast message notifications
/// This is a stub implementation - full notification logic will be implemented in task 11
class NotificationService extends GetxService {
  final WebSocketService _wsService = Get.find<WebSocketService>();
  StreamSubscription<BroadcastMessage>? _messageSubscription;

  // Observable state for active notifications
  final RxList<BroadcastMessage> activeNotifications = <BroadcastMessage>[].obs;

  @override
  void onInit() {
    super.onInit();
    _listenToMessages();
  }

  /// Listen to incoming broadcast messages from WebSocket
  void _listenToMessages() {
    _messageSubscription = _wsService.messageStream.listen((message) {
      _handleBroadcastMessage(message);
    });
  }

  /// Handle incoming broadcast message
  void _handleBroadcastMessage(BroadcastMessage message) {
    print('Received broadcast message: ${message.title} (${message.level})');

    // Add to active notifications
    activeNotifications.add(message);

    // Trigger notification based on severity level
    // This will be fully implemented in task 11
    _triggerNotification(message);
  }

  /// Trigger notification based on message severity
  /// Stub implementation - will be completed in task 11
  void _triggerNotification(BroadcastMessage message) {
    // TODO: Implement notification patterns in task 11
    // - Low: vibrate only
    // - Medium: vibrate + screen pulse
    // - High: vibrate + screen pulse + sound (continuous until acknowledged)
    print(
      'Triggering ${message.level} severity notification for: ${message.title}',
    );
  }

  /// Acknowledge a message and stop its notification
  Future<void> acknowledgeMessage(
    BroadcastMessage message,
    String userId,
  ) async {
    try {
      // Send acknowledgement to server via WebSocket
      await _wsService.acknowledgeMessage(message.messageId, userId);

      // Remove from active notifications
      activeNotifications.removeWhere((m) => m.messageId == message.messageId);

      // Stop notification alerts
      // This will be fully implemented in task 11
      _stopNotification(message);

      print('Message acknowledged: ${message.messageId}');
    } catch (e) {
      print('Error acknowledging message: $e');
      rethrow;
    }
  }

  /// Stop notification for a specific message
  /// Stub implementation - will be completed in task 11
  void _stopNotification(BroadcastMessage message) {
    // TODO: Implement in task 11
    // - Stop vibration
    // - Stop screen pulse
    // - Stop sound playback
    print('Stopping notification for: ${message.messageId}');
  }

  @override
  void onClose() {
    _messageSubscription?.cancel();
    super.onClose();
  }
}
