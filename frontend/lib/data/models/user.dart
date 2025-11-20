class User {
  final String id;
  final String organizationId;
  final String name;
  final String email;
  final String role;
  final String? supervisorTopicId;
  final bool notificationEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.email,
    required this.role,
    this.supervisorTopicId,
    required this.notificationEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      supervisorTopicId: json['supervisorTopicId'] as String?,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'name': name,
      'email': email,
      'role': role,
      'supervisorTopicId': supervisorTopicId,
      'notificationEnabled': notificationEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isSupervisor => role == 'supervisor';
  bool get isNormalUser => role == 'normal';
}
