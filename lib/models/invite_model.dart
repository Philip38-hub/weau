/// Direction of the invite from the current user's perspective.
enum InviteDirection { incoming, outgoing }

/// Status reported by the backend.
enum InviteStatus { pending, accepted, declined }

/// Represents an invite returned from GET /invites/{user_id}.
class InviteModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final InviteDirection direction;
  final InviteStatus status;

  const InviteModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.direction,
    required this.status,
  });

  factory InviteModel.fromJson(Map<String, dynamic> json) {
    return InviteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userAvatar: json['user_avatar'] as String?,
      direction: (json['direction'] as String) == 'incoming'
          ? InviteDirection.incoming
          : InviteDirection.outgoing,
      status: _parseStatus(json['status'] as String?),
    );
  }

  static InviteStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'accepted':
        return InviteStatus.accepted;
      case 'declined':
        return InviteStatus.declined;
      default:
        return InviteStatus.pending;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        if (userAvatar != null) 'user_avatar': userAvatar,
        'direction': direction.name,
        'status': status.name,
      };
}
