class BroadcastMessage {
  final String messageId;
  final String level;
  final String title;
  final String message;
  final String? code;
  final DateTime timestamp;

  BroadcastMessage({
    required this.messageId,
    required this.level,
    required this.title,
    required this.message,
    this.code,
    required this.timestamp,
  });

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) {
    return BroadcastMessage(
      messageId: json['messageId'] as String,
      level: json['level'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      code: json['code'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'level': level,
      'title': title,
      'message': message,
      'code': code,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isLowSeverity => level == 'low';
  bool get isMediumSeverity => level == 'medium';
  bool get isHighSeverity => level == 'high';
}
