import 'package:dio/dio.dart';
import '../models/auth/token.dart';
import '../models/user/user_response.dart';
import '../models/message/message_response.dart';
import '../models/friendship/friendship_response.dart';
import '../models/common/paginated_response.dart';
import '../models/auth/auth_request.dart';
import '../models/user/user_request.dart';
import '../models/friendship/friendship_request.dart';
import '../models/message/message_request.dart';
import '../models/subscription/subscription_response.dart';

class ApiService {
  final Dio _dio;
  final String? baseUrl;

  ApiService(this._dio, {this.baseUrl});

  // Generic helper methods
  Future<PaginatedResponse<T>> _fetchPaginated<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(endpoint, queryParameters: queryParameters);
    return PaginatedResponse.fromJson(
      response.data,
      (item) => fromJson(item as Map<String, dynamic>),
    );
  }

  Future<List<T>> _fetchList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(endpoint, queryParameters: queryParameters);
    final List items = response.data['items'] ?? response.data;
    return items.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  // Auth endpoints (Public)
  Future<Token> login(LoginRequest body) async {
    final response = await _dio.post('/api/public/login', data: body.toJson());
    return Token.fromJson(response.data);
  }

  Future<Token> register(RegisterRequest body) async {
    final response = await _dio.post(
      '/api/public/register',
      data: body.toJson(),
    );
    return Token.fromJson(response.data);
  }

  Future<Token> refreshToken(RefreshTokenRequest body) async {
    final response = await _dio.post(
      '/api/public/refresh',
      data: body.toJson(),
    );
    return Token.fromJson(response.data);
  }

  Future<void> logout() async {
    await _dio.post('/api/public/logout');
  }

  // User endpoints (Client Profile)
  Future<UserResponse> getMe() async {
    final response = await _dio.get('/api/client/profile/me');
    return UserResponse.fromJson(response.data);
  }

  Future<UserResponse> updateMe(UserUpdateRequest body) async {
    final response = await _dio.put(
      '/api/client/profile/',
      data: body.toJson(),
    );
    return UserResponse.fromJson(response.data);
  }

  Future<UserResponse> updateAvatar(MultipartFile file) async {
    final formData = FormData.fromMap({'file': file});
    final response = await _dio.post(
      '/api/client/profile/avatar',
      data: formData,
    );
    return UserResponse.fromJson(response.data);
  }

  Future<void> updateOnlineStatus(OnlineStatusUpdate body) async {
    await _dio.put('/api/client/profile/online-status', data: body.toJson());
  }

  // Friendship endpoints (Client Friends)
  Future<PaginatedResponse<FriendshipResponse>> getFriendships({
    int? page,
    int? size,
  }) async {
    final response = await _dio.get(
      '/api/client/friends/',
      queryParameters: {
        if (page != null) 'page': page,
        if (size != null) 'size': size,
      },
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => FriendshipResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PaginatedResponse<FriendshipResponse>> getFriendRequests({
    int? page,
    int? size,
  }) async {
    final response = await _dio.get(
      '/api/client/friends/requests',
      queryParameters: {
        if (page != null) 'page': page,
        if (size != null) 'size': size,
      },
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => FriendshipResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<FriendshipResponse> createFriendship(
    FriendshipCreateRequest body,
  ) async {
    final response = await _dio.post(
      '/api/client/friends/',
      data: body.toJson(),
    );
    return FriendshipResponse.fromJson(response.data);
  }

  Future<FriendshipResponse> acceptFriendRequest(int id) async {
    final response = await _dio.put('/api/client/friends/$id/accept');
    return FriendshipResponse.fromJson(response.data);
  }

  Future<FriendshipResponse> rejectFriendRequest(int id) async {
    final response = await _dio.put('/api/client/friends/$id/reject');
    return FriendshipResponse.fromJson(response.data);
  }

  Future<void> deleteFriendship(int id) async {
    await _dio.delete('/api/client/friends/$id');
  }

  // Message endpoints (Client Messages)
  Future<PaginatedResponse<MessageResponse>> getMessages({
    int? page,
    int? size,
    int? friendshipId,
    bool? isRead,
  }) async {
    final response = await _dio.get(
      '/api/client/messages/',
      queryParameters: {
        if (page != null) 'page': page,
        if (size != null) 'size': size,
        if (friendshipId != null) 'friendship_id': friendshipId,
        if (isRead != null) 'is_read': isRead,
      },
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => MessageResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<MessageResponse>> getReceivedMessages({
    int page = 1,
    int size = 50,
  }) async {
    return _fetchList(
      '/api/client/messages/received',
      MessageResponse.fromJson,
      queryParameters: {'page': page, 'size': size},
    );
  }

  Future<List<MessageResponse>> getSentMessages({
    int page = 1,
    int size = 50,
  }) async {
    return _fetchList(
      '/api/client/messages/sent',
      MessageResponse.fromJson,
      queryParameters: {'page': page, 'size': size},
    );
  }

  Future<PaginatedResponse<MessageResponse>> getConversationMessages(
    int friendshipId, {
    int page = 1,
    int size = 50,
  }) async {
    return _fetchPaginated(
      '/api/client/messages/conversation/$friendshipId',
      MessageResponse.fromJson,
      queryParameters: {'page': page, 'size': size},
    );
  }

  Future<MessageResponse> sendMessage(MessageCreateRequest body) async {
    final response = await _dio.post(
      '/api/client/messages/',
      data: body.toJson(),
    );
    return MessageResponse.fromJson(response.data);
  }

  // Subscription endpoints (Client Subscriptions)
  Future<PaginatedResponse<SubscriptionTypeResponse>>
  getAvailableSubscriptions({int? page, int? size, String? category}) async {
    final response = await _dio.get(
      '/api/client/subscriptions/available',
      queryParameters: {
        if (page != null) 'page': page,
        if (size != null) 'size': size,
        if (category != null) 'category': category,
      },
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => SubscriptionTypeResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PaginatedResponse<MySubscriptionItem>> getMySubscriptions({
    int? page,
    int? size,
  }) async {
    final response = await _dio.get(
      '/api/client/subscriptions/my',
      queryParameters: {
        if (page != null) 'page': page,
        if (size != null) 'size': size,
      },
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => MySubscriptionItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<UserResponse> adminGetUser(int id) async {
    final response = await _dio.get('/api/admin/users/$id');
    return UserResponse.fromJson(response.data);
  }

  Future<List<UserResponse>> adminGetUsers({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/admin/users',
      queryParameters: {'page': page, 'size': size},
    );
    final List items = response.data['items'] ?? response.data;
    return items
        .map((e) => UserResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
