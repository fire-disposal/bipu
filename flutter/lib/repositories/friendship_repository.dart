import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/friendship_model.dart';
import '../models/paginated_response.dart';

class FriendshipRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Friendship> sendFriendRequest(int friendId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.friendships,
        data: {'friend_id': friendId},
      );
      return Friendship.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<PaginatedResponse<Friendship>> getFriendships({
    int page = 1,
    int size = 20,
    FriendshipStatus? status,
  }) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  Future<PaginatedResponse<Friendship>> getFriendRequests({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.friendRequests,
        queryParameters: {'page': page, 'size': size},
      );

      return PaginatedResponse.fromJson(
        response.data,
        (json) => Friendship.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }
}
