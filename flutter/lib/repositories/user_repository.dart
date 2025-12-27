import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user_model.dart';
import '../models/paginated_response.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient();

  Future<PaginatedResponse<User>> getUsers({
    int page = 1,
    int size = 20,
    String? search,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.users,
        queryParameters: {
          'page': page,
          'size': size,
          if (search != null) 'search': search,
        },
      );

      // Handle case where backend returns a List instead of PaginatedResponse
      if (response.data is List) {
        final list = response.data as List;
        return PaginatedResponse(
          items: list.map((e) => User.fromJson(e)).toList(),
          total: list.length,
          page: page,
          size: size,
        );
      }

      return PaginatedResponse.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<User> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: userData,
      );
      return User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.userDetails(id),
        data: userData,
      );
      return User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _apiClient.dio.delete(ApiEndpoints.userDetails(id));
    } catch (e) {
      rethrow;
    }
  }
}
