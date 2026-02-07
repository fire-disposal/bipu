import '../common/enums.dart';

class FriendshipResponse {
  final int userId;
  final int friendId;
  final FriendshipStatus status;
  final int id;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FriendshipResponse({
    required this.userId,
    required this.friendId,
    this.status = FriendshipStatus.pending,
    required this.id,
    required this.createdAt,
    this.updatedAt,
  });

  static FriendshipStatus _parseStatus(dynamic v) {
    if (v == null) return FriendshipStatus.pending;
    if (v is FriendshipStatus) return v;
    final s = v.toString().toLowerCase();
    if (s.contains('accepted')) return FriendshipStatus.accepted;
    if (s.contains('blocked')) return FriendshipStatus.blocked;
    return FriendshipStatus.pending;
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    throw FormatException('Cannot parse DateTime from $v');
  }

  factory FriendshipResponse.fromJson(Map<String, dynamic> json) {
    return FriendshipResponse(
      userId: (json['user_id'] ?? json['userId']) is int
          ? (json['user_id'] ?? json['userId']) as int
          : int.parse('${json['user_id'] ?? json['userId']}'),
      friendId: (json['friend_id'] ?? json['friendId']) is int
          ? (json['friend_id'] ?? json['friendId']) as int
          : int.parse('${json['friend_id'] ?? json['friendId']}'),
      status: _parseStatus(json['status']),
      id: (json['id'] is int) ? json['id'] as int : int.parse('${json['id']}'),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? _parseDateTime(json['updated_at'] ?? json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'friend_id': friendId,
    'status': status.toString().split('.').last,
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
