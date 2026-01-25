import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/friendship_model.dart';
import '../models/paginated_response.dart';
import '../models/user_model.dart';

class FriendshipRepository {
  final ApiClient _apiClient = ApiClient();

  // Create Request
  Future<Friendship> sendFriendRequest(int friendId) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.friendships,
      data: {'friend_id': friendId},
    );
    return Friendship.fromJson(response.data);
  }

  // Get Friendships (All statuses, usually filterable)
  Future<PaginatedResponse<Friendship>> getFriendships({
    int page = 1,
    int size = 20,
    FriendshipStatus? status,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.friendships,
      queryParameters: {
        'page': page,
        'size': size,
        if (status != null) 'status': status.toString().split('.').last,
      },
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Friendship.fromJson(json),
    );
  }

  // Get Pending Requests
  Future<PaginatedResponse<Friendship>> getFriendRequests({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.friendRequests,
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Friendship.fromJson(json),
    );
  }

  // Get Friends (Accepted) - Returns User objects
  Future<PaginatedResponse<User>> getFriends({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.friends,
      queryParameters: {'page': page, 'size': size},
    );
    // Verified against openapi.json: returns PaginatedResponse[UserResponse]
    return PaginatedResponse.fromJson(
      response.data,
      (json) => User.fromJson(json),
    );
  }

  // Actions
  Future<Friendship> acceptFriendRequest(int friendshipId) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.acceptFriendRequest(friendshipId),
    );
    return Friendship.fromJson(response.data);
  }

  Future<Friendship> rejectFriendRequest(int friendshipId) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.rejectFriendRequest(friendshipId),
    );
    return Friendship.fromJson(response.data);
  }

  Future<void> deleteFriendship(int friendshipId) async {
    await _apiClient.dio.delete(ApiEndpoints.friendshipDetails(friendshipId));
  }

  // Admin
  Future<PaginatedResponse<Friendship>> adminGetAllFriendships({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.adminFriendshipsAll,
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Friendship.fromJson(json),
    );
  }

  Future<void> adminDeleteFriendship(int friendshipId) async {
    await _apiClient.dio.delete(
      ApiEndpoints.adminFriendshipDetails(friendshipId),
    );
  }
}
