/// Represents a friend returned from GET /friends.
class FriendModel {
  final String id;
  final String name;
  final String? avatar;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSeen;

  const FriendModel({
    required this.id,
    required this.name,
    this.avatar,
    this.latitude,
    this.longitude,
    this.lastSeen,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (avatar != null) 'avatar': avatar,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      };
}
