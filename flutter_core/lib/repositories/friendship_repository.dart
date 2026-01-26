import '../core/network/api_client.dart';
import '../models/friendship_model.dart';
import '../models/paginated_response.dart';
import '../models/user_model.dart';

class FriendshipRepository {
  final _client = ApiClient().restClient;

  // Create Request
  Future<Friendship> sendFriendRequest(int friendId) {
    return _client.sendFriendRequest({'friend_id': friendId});
  }

  // Get Friendships (All statuses, usually filterable)
  Future<PaginatedResponse<Friendship>> getFriendships({
    int page = 1,
    int size = 20,
    FriendshipStatus? status,
  }) {
    return _client.getFriendships(
      page: page,
      size: size,
      status: status?.toString().split('.').last,
    );
  }

  // Get Pending Requests
  Future<PaginatedResponse<Friendship>> getFriendRequests({
    int page = 1,
    int size = 20,
  }) {
    return _client.getFriendRequests(page: page, size: size);
  }

  // Get Friends (Accepted) - Returns User objects
  Future<PaginatedResponse<User>> getFriends({int page = 1, int size = 20}) {
    return _client.getFriends(page: page, size: size);
  }

  // Actions
  Future<Friendship> acceptFriendRequest(int friendshipId) {
    return _client.acceptFriendRequest(friendshipId);
  }

  Future<Friendship> rejectFriendRequest(int friendshipId) {
    return _client.rejectFriendRequest(friendshipId);
  }

  Future<void> deleteFriendship(int friendshipId) {
    return _client.deleteFriendship(friendshipId);
  }

  // Admin
  Future<PaginatedResponse<Friendship>> adminGetAllFriendships({
    int page = 1,
    int size = 20,
  }) {
    return _client.adminGetAllFriendships(page: page, size: size);
  }

  Future<void> adminDeleteFriendship(int friendshipId) {
    return _client.adminDeleteFriendship(friendshipId);
  }
}
