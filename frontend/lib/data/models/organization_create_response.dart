/// Response model for organization creation
/// Contains the created organization details and owner PIN
class OrganizationCreateResponse {
  final String organizationId;
  final String organizationName;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String ownerPin;

  OrganizationCreateResponse({
    required this.organizationId,
    required this.organizationName,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPin,
  });

  factory OrganizationCreateResponse.fromJson(Map<String, dynamic> json) {
    return OrganizationCreateResponse(
      organizationId: json['organizationId'] as String,
      organizationName: json['organizationName'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      ownerEmail: json['ownerEmail'] as String,
      ownerPin: json['ownerPin'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'organizationName': organizationName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPin': ownerPin,
    };
  }
}
