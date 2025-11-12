class UserProfile {
  final String id;
  final String organizationId;
  final String name;
  final String email;
  final String role;
  final String? supervisorTopicId;
  final bool notificationEnabled;

  UserProfile({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.email,
    required this.role,
    this.supervisorTopicId,
    required this.notificationEnabled,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      supervisorTopicId: json['supervisorTopicId'] as String?,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
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
    };
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isSupervisor => role == 'supervisor';
  bool get isNormalUser => role == 'normal';
  bool get canBroadcastOrgWide => isOwner || isAdmin;
  bool get canManageUsers => isOwner || isAdmin;
}
