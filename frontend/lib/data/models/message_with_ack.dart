import 'broadcast_message.dart';

/// Wrapper class for BroadcastMessage with acknowledgement status
class MessageWithAck {
  final BroadcastMessage message;
  final bool isAcknowledged;
  final DateTime? acknowledgedAt;

  MessageWithAck({
    required this.message,
    required this.isAcknowledged,
    this.acknowledgedAt,
  });

  factory MessageWithAck.fromJson(Map<String, dynamic> json) {
    return MessageWithAck(
      message: BroadcastMessage.fromJson(
        json['message'] as Map<String, dynamic>,
      ),
      isAcknowledged: json['isAcknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message.toJson(),
      'isAcknowledged': isAcknowledged,
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    };
  }
}
