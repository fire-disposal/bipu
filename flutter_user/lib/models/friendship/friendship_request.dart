import '../common/enums.dart';

class FriendshipCreateRequest {
  final int userId;
  final int friendId;
  final FriendshipStatus status;

  FriendshipCreateRequest({
    required this.userId,
    required this.friendId,
    this.status = FriendshipStatus.pending,
  });

  factory FriendshipCreateRequest.fromJson(Map<String, dynamic> json) {
    return FriendshipCreateRequest(
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.parse(json['user_id'].toString()),
      friendId: json['friend_id'] is int
          ? json['friend_id'] as int
          : int.parse(json['friend_id'].toString()),
      status: _parseFriendshipStatus(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'friend_id': friendId,
    'status': _friendshipStatusToString(status),
  };
}

class FriendshipUpdateRequest {
  final FriendshipStatus status;

  FriendshipUpdateRequest({required this.status});

  factory FriendshipUpdateRequest.fromJson(Map<String, dynamic> json) {
    return FriendshipUpdateRequest(
      status: _parseFriendshipStatus(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': _friendshipStatusToString(status),
  };
}

FriendshipStatus _parseFriendshipStatus(String? value) {
  switch (value) {
    case 'pending':
      return FriendshipStatus.pending;
    case 'accepted':
      return FriendshipStatus.accepted;
    case 'blocked':
      return FriendshipStatus.blocked;
    default:
      return FriendshipStatus.pending;
  }
}

String _friendshipStatusToString(FriendshipStatus status) {
  switch (status) {
    case FriendshipStatus.pending:
      return 'pending';
    case FriendshipStatus.accepted:
      return 'accepted';
    case FriendshipStatus.blocked:
      return 'blocked';
  }
}
