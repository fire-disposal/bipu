import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user_model.dart';
import '../models/paginated_response.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient();

  // Auth
  Future<AuthResponse> login(String username, String password) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.login,
      data: {'username': username, 'password': password},
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<User> register(Map<String, dynamic> userData) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.register,
      data: userData,
    );
    return User.fromJson(response.data);
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': refreshToken},
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<void> logout() async {
    await _apiClient.dio.post(ApiEndpoints.logout);
  }

  // Current User
  Future<User> getMe() async {
    final response = await _apiClient.dio.get(ApiEndpoints.me);
    return User.fromJson(response.data);
  }

  Future<User> updateMe(Map<String, dynamic> userData) async {
    final response = await _apiClient.dio.put(ApiEndpoints.me, data: userData);
    return User.fromJson(response.data);
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    await _apiClient.dio.put(
      ApiEndpoints.onlineStatus,
      queryParameters: {'is_online': isOnline},
    );
  }

  // User Management
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

  Future<User> getUser(int id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.userDetails(id));
    return User.fromJson(response.data);
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

  // Admin
  Future<PaginatedResponse<User>> adminGetAllUsers({
    int page = 1,
    int size = 20,
    String? search,
    String? role,
    bool? isActive,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.adminUsersAll,
      queryParameters: {
        'page': page,
        'size': size,
        if (search != null) 'search': search,
        if (role != null) 'role': role,
        if (isActive != null) 'is_active': isActive,
      },
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => User.fromJson(json),
    );
  }

  Future<User> adminUpdateUserStatus(int id, bool isActive) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.adminUserStatus(id),
      data: {'is_active': isActive},
    );
    return User.fromJson(response.data);
  }

  // Create User (Admin) - Using Register endpoint as proxy
  Future<User> createUser(Map<String, dynamic> userData) async {
    return register(userData);
  }
}
