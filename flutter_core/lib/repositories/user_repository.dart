import '../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/paginated_response.dart';

class UserRepository {
  final _client = ApiClient().restClient;
  // Warning: Retaining Dio for complex logic if needed
  final _dio = ApiClient().dio;

  // Auth
  Future<AuthResponse> login(String username, String password) async {
    return _client.login({'username': username, 'password': password});
  }

  Future<User> register(Map<String, dynamic> userData) async {
    return _client.register(userData);
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    return _client.refreshToken({'refresh_token': refreshToken});
  }

  Future<void> logout() async {
    await _client.logout();
  }

  // Current User
  Future<User> getMe() async {
    return _client.getMe();
  }

  Future<User> updateMe(Map<String, dynamic> userData) async {
    // 新API返回 UserProfile，但 User.fromJson 能够正确解析核心字段
    return _client.updateMe(userData);
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    await _client.updateOnlineStatus({'is_online': isOnline});
  }

  // User Management
  Future<PaginatedResponse<User>> getUsers({
    int page = 1,
    int size = 20,
    String? search,
  }) async {
    try {
      // Trying to use Retrofit, but keeping the manual logic in mind.
      // If the backend is consistent, we should use _client.getUsers.
      // However, the original code handled List response manually.
      // To be safe and "fully verify" later, we might want to stick to Dio for this ONE method
      // OR assume strict contract.
      // Let's stick to the previous robust implementation using _dio because Retrofit
      // doesn't handle conditional return types (List vs Map) easily.

      final response = await _dio.get(
        '/api/admin/users',
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
    return _client.getUserDetails(id);
  }

  Future<User> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      return await _client.updateUser(id, userData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _client.deleteUser(id);
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
    return _client.adminGetAllUsers(
      page: page,
      size: size,
      search: search,
      role: role,
      isActive: isActive,
    );
  }

  Future<User> adminUpdateUserStatus(int id, bool isActive) async {
    return _client.adminUpdateUserStatus(id, {'is_active': isActive});
  }

  // Create User (Admin) - Using Register endpoint as proxy
  Future<User> createUser(Map<String, dynamic> userData) async {
    return register(userData);
  }
}
