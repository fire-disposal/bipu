import 'package:equatable/equatable.dart';

abstract class FriendshipEvent extends Equatable {
  const FriendshipEvent();

  @override
  List<Object?> get props => [];
}

class LoadFriendships extends FriendshipEvent {
  final bool refresh;

  const LoadFriendships({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class LoadFriendRequests extends FriendshipEvent {
  final bool refresh;

  const LoadFriendRequests({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class AcceptFriendRequest extends FriendshipEvent {
  final int friendshipId;

  const AcceptFriendRequest(this.friendshipId);

  @override
  List<Object?> get props => [friendshipId];
}

class RejectFriendRequest extends FriendshipEvent {
  final int friendshipId;

  const RejectFriendRequest(this.friendshipId);

  @override
  List<Object?> get props => [friendshipId];
}

class SendFriendRequest extends FriendshipEvent {
  final int friendId;

  const SendFriendRequest(this.friendId);

  @override
  List<Object?> get props => [friendId];
}
