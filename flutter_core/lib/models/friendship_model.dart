enum FriendshipStatus { pending, accepted, blocked }

class Friendship {
  final int id;
  final int userId;
  final int friendId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      friendId: json['friend_id'] as int,
      status: FriendshipStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
