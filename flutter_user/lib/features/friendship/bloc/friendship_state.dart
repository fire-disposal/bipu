import 'package:equatable/equatable.dart';
import 'package:flutter_user/models/friendship_model.dart';
import 'package:flutter_user/models/user_model.dart';

class FriendRequestItem extends Equatable {
  final Friendship friendship;
  final User sender;

  const FriendRequestItem({required this.friendship, required this.sender});

  @override
  List<Object?> get props => [friendship, sender];
}

abstract class FriendshipState extends Equatable {
  const FriendshipState();

  @override
  List<Object?> get props => [];
}

class FriendshipInitial extends FriendshipState {}

class FriendshipLoading extends FriendshipState {}

class FriendshipError extends FriendshipState {
  final String message;

  const FriendshipError(this.message);

  @override
  List<Object?> get props => [message];
}

class FriendshipLoaded extends FriendshipState {
  final List<User> friends;
  // Requests with sender details
  final List<FriendRequestItem> requests;
  final int friendsCount;
  final int requestsCount;

  const FriendshipLoaded({
    this.friends = const [],
    this.requests = const [],
    this.friendsCount = 0,
    this.requestsCount = 0,
  });

  @override
  List<Object?> get props => [friends, requests, friendsCount, requestsCount];

  FriendshipLoaded copyWith({
    List<User>? friends,
    List<FriendRequestItem>? requests,
    int? friendsCount,
    int? requestsCount,
  }) {
    return FriendshipLoaded(
      friends: friends ?? this.friends,
      requests: requests ?? this.requests,
      friendsCount: friendsCount ?? this.friendsCount,
      requestsCount: requestsCount ?? this.requestsCount,
    );
  }
}

class FriendshipOperationSuccess extends FriendshipState {
  final String message;

  const FriendshipOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
