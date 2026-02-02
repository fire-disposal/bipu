import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core/api/api.dart';
import 'package:flutter_core/core/network/rest_client.dart';
import 'friendship_event.dart';
import 'friendship_state.dart';

class FriendshipBloc extends Bloc<FriendshipEvent, FriendshipState> {
  final RestClient _api;

  FriendshipBloc({RestClient? api})
    : _api = api ?? bipupuApi,
      super(FriendshipInitial()) {
    on<LoadFriendships>(_onLoadFriendships);
    on<LoadFriendRequests>(_onLoadFriendRequests);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<RejectFriendRequest>(_onRejectFriendRequest);
    on<SendFriendRequest>(_onSendFriendRequest);
  }

  Future<void> _onLoadFriendships(
    LoadFriendships event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      if (state is FriendshipInitial || event.refresh) {
        emit(FriendshipLoading());
      }

      // Load Friends
      final friendsResponse = await _api.getFriends(page: 1, size: 50);

      // Load Requests count
      final requestsResponse = await _api.getFriendRequests(page: 1, size: 1);

      // If we are already in Loaded state, preserve the requests
      final currentRequests = state is FriendshipLoaded
          ? (state as FriendshipLoaded).requests
          : <FriendRequestItem>[];

      emit(
        FriendshipLoaded(
          friends: friendsResponse.items,
          friendsCount: friendsResponse.total,
          requests: currentRequests,
          requestsCount: requestsResponse.total,
        ),
      );
    } catch (e) {
      emit(FriendshipError(e.toString()));
    }
  }

  Future<void> _onLoadFriendRequests(
    LoadFriendRequests event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! FriendshipLoaded) {
        emit(FriendshipLoading());
      }

      final requestsResponse = await _api.getFriendRequests(page: 1, size: 50);

      // We need to fetch User details for each request
      final requestItems = await Future.wait(
        requestsResponse.items.map((friendship) async {
          try {
            // userId is the sender
            final sender = await _api.getUserDetails(friendship.userId);
            return FriendRequestItem(friendship: friendship, sender: sender);
          } catch (e) {
            // Fallback or skip
            return null;
          }
        }),
      );

      final validItems = requestItems.whereType<FriendRequestItem>().toList();

      if (currentState is FriendshipLoaded) {
        emit(
          currentState.copyWith(
            requests: validItems,
            requestsCount: requestsResponse.total,
          ),
        );
      } else {
        emit(
          FriendshipLoaded(
            requests: validItems,
            requestsCount: requestsResponse.total,
          ),
        );
      }
    } catch (e) {
      emit(FriendshipError(e.toString()));
    }
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequest event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      await _api.acceptFriendRequest(event.friendshipId);
      add(const LoadFriendRequests(refresh: true));
      add(const LoadFriendships(refresh: true));
    } catch (e) {
      // Handle error (maybe show a toast via listener)
    }
  }

  Future<void> _onRejectFriendRequest(
    RejectFriendRequest event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      await _api.rejectFriendRequest(event.friendshipId);
      add(const LoadFriendRequests(refresh: true));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onSendFriendRequest(
    SendFriendRequest event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      await _api.sendFriendRequest({'friend_id': event.friendId});
      // Maybe emit a "Success" side effect or snackbar
    } catch (e) {
      // Handle error
    }
  }
}
