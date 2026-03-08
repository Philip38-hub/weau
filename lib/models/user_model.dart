/// Represents the authenticated user returned from /auth.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final bool trackingEnabled;
  final String visibilityLevel;
  final String precisionLevel;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.trackingEnabled = true,
    this.visibilityLevel = 'friends',
    this.precisionLevel = 'exact',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      trackingEnabled: (json['tracking_enabled'] ?? 1) == 1,
      visibilityLevel: json['visibility_level'] as String? ?? 'friends',
      precisionLevel: json['precision_level'] as String? ?? 'exact',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (avatar != null) 'avatar': avatar,
        'tracking_enabled': trackingEnabled ? 1 : 0,
        'visibility_level': visibilityLevel,
        'precision_level': precisionLevel,
      };
}
