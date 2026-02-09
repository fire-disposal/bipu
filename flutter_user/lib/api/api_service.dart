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
import '../models/user/user_settings_request.dart';

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

  // Auth endpoints (Public)
  Future<Token> login(LoginRequest body) async {
    final response = await _dio.post('/public/login', data: body.toJson());
    final data = response.data;
    // Defensive: ensure backend returned a JSON object we can parse as a Token
    if (data is! Map<String, dynamic>) {
      // Include a short excerpt to aid debugging
      final snippet = data == null ? 'null' : data.toString();
      throw Exception('Unexpected login response (not JSON object): $snippet');
    }
    return Token.fromJson(data);
  }

  Future<Token> register(RegisterRequest body) async {
    final response = await _dio.post('/public/register', data: body.toJson());
    return Token.fromJson(response.data);
  }

  Future<Token> refreshToken(RefreshTokenRequest body) async {
    final response = await _dio.post('/public/refresh', data: body.toJson());
    return Token.fromJson(response.data);
  }

  Future<void> logout() async {
    await _dio.post('/public/logout');
  }

  // User endpoints (Client Profile)
  Future<UserResponse> getMe() async {
    final response = await _dio.get('/client/profile/me');
    return UserResponse.fromJson(response.data);
  }

  Future<UserResponse> updateMe(UserUpdateRequest body) async {
    final response = await _dio.put('/client/profile/', data: body.toJson());
    return UserResponse.fromJson(response.data);
  }

  Future<UserResponse> updateAvatar(MultipartFile file) async {
    final formData = FormData.fromMap({'file': file});
    final response = await _dio.post('/client/profile/avatar', data: formData);
    return UserResponse.fromJson(response.data);
  }

  Future<void> updateOnlineStatus(OnlineStatusUpdate body) async {
    await _dio.put('/client/profile/online-status', data: body.toJson());
  }

  Future<UserResponse> getUserProfile() async {
    final response = await _dio.get('/client/profile/');
    return UserResponse.fromJson(response.data);
  }

  Future<String> getUserAvatar(int userId) async {
    final response = await _dio.get('/client/profile/avatar/$userId');
    return response.data; // Assuming it's a URL or data
  }

  // Friendship endpoints (Client Friends)
  Future<PaginatedResponse<FriendshipResponse>> getFriendships({
    int? page,
    int? size,
    String? status,
  }) async {
    final response = await _dio.get(
      '/client/friends/',
      queryParameters: {
        if (page != null) 'page': page,
        if (size != null) 'size': size,
        if (status != null) 'status': status,
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
      '/client/friends/requests',
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

  Future<PaginatedResponse<FriendshipResponse>> getFriends({
    int? page,
    int? size,
  }) async {
    final response = await _dio.get(
      '/client/friends/friends',
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
    final response = await _dio.post('/client/friends/', data: body.toJson());
    return FriendshipResponse.fromJson(response.data);
  }

  Future<FriendshipResponse> acceptFriendRequest(int id) async {
    final response = await _dio.put('/client/friends/$id/accept');
    return FriendshipResponse.fromJson(response.data);
  }

  Future<FriendshipResponse> rejectFriendRequest(int id) async {
    final response = await _dio.put('/client/friends/$id/reject');
    return FriendshipResponse.fromJson(response.data);
  }

  Future<void> deleteFriendship(int id) async {
    await _dio.delete('/client/friends/$id');
  }

  // Message endpoints (Client Messages)
  Future<PaginatedResponse<MessageResponse>> getMessages({
    int? page,
    int? size,
    int? senderId,
    int? receiverId,
    bool? isRead,
    String? messageType,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      '/client/messages/',
      queryParameters: {
        if (page != null) 'page': page,
        if (size != null) 'size': size,
        if (senderId != null) 'sender_id': senderId,
        if (receiverId != null) 'receiver_id': receiverId,
        if (isRead != null) 'is_read': isRead,
        if (messageType != null) 'message_type': messageType,
        if (status != null) 'status': status,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => MessageResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PaginatedResponse<MessageResponse>> getConversationMessages(
    int userId, {
    int page = 1,
    int size = 50,
  }) async {
    return _fetchPaginated(
      '/client/messages/conversations/$userId',
      MessageResponse.fromJson,
      queryParameters: {'page': page, 'size': size},
    );
  }

  Future<MessageResponse> getMessage(int messageId) async {
    final response = await _dio.get('/client/messages/$messageId');
    return MessageResponse.fromJson(response.data);
  }

  Future<MessageResponse> updateMessage(
    int messageId,
    MessageCreateRequest body,
  ) async {
    final response = await _dio.put(
      '/client/messages/$messageId',
      data: body.toJson(),
    );
    return MessageResponse.fromJson(response.data);
  }

  Future<void> deleteMessage(int messageId) async {
    await _dio.delete('/client/messages/$messageId');
  }

  Future<MessageResponse> sendMessage(MessageCreateRequest body) async {
    final response = await _dio.post('/client/messages/', data: body.toJson());
    return MessageResponse.fromJson(response.data);
  }

  Future<void> markMessageAsRead(int messageId) async {
    await _dio.put('/client/messages/$messageId/read');
  }

  Future<void> markAllMessagesAsRead() async {
    await _dio.put('/client/messages/read-all');
  }

  Future<void> favoriteMessage(int messageId) async {
    await _dio.post('/client/messages/$messageId/favorite');
  }

  Future<void> unfavoriteMessage(int messageId) async {
    await _dio.delete('/client/messages/$messageId/favorite');
  }

  Future<PaginatedResponse<MessageResponse>> getFavoriteMessages({
    int? page,
    int? size,
  }) async {
    return _fetchPaginated(
      '/client/messages/favorites',
      MessageResponse.fromJson,
      queryParameters: {
        if (page != null) 'page': page,
        if (size != null) 'size': size,
      },
    );
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('/client/messages/unread/count');
    return response.data as int;
  }

  Future<MessageStats> getMessageStats() async {
    final response = await _dio.get('/client/messages/stats');
    return MessageStats.fromJson(response.data);
  }

  Future<MessageAckEventResponse> createMessageAckEvent(
    MessageAckEventCreate body,
  ) async {
    final response = await _dio.post(
      '/client/messages/ack',
      data: body.toJson(),
    );
    return MessageAckEventResponse.fromJson(response.data);
  }

  Future<PaginatedResponse<MessageAckEventResponse>> getMessageAckEvents(
    int messageId, {
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/client/messages/ack/message/$messageId',
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => MessageAckEventResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> batchDeleteMessages(List<int> messageIds) async {
    await _dio.delete('/client/messages/batch', data: messageIds);
  }

  Future<void> archiveMessage(int messageId) async {
    await _dio.put('/client/messages/$messageId/archive');
  }

  // Subscription endpoints (Client Subscriptions)
  Future<PaginatedResponse<SubscriptionTypeResponse>>
  getAvailableSubscriptions({int? page, int? size, String? category}) async {
    final response = await _dio.get(
      '/client/subscriptions/available',
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
      '/client/subscriptions/my',
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

  Future<void> subscribeToService(int subscriptionTypeId) async {
    await _dio.post('/client/subscriptions/$subscriptionTypeId/subscribe');
  }

  Future<void> unsubscribeFromService(int subscriptionTypeId) async {
    await _dio.post('/client/subscriptions/$subscriptionTypeId/unsubscribe');
  }

  Future<void> updateSubscriptionSettings(
    int subscriptionTypeId,
    Map<String, dynamic> body,
  ) async {
    await _dio.put(
      '/client/subscriptions/$subscriptionTypeId/settings',
      data: body,
    );
  }

  Future<UserResponse> adminGetUser(int id) async {
    final response = await _dio.get('/admin/users/$id');
    return UserResponse.fromJson(response.data);
  }

  // User block / blacklist endpoints
  Future<void> blockUser(BlockUserRequest body) async {
    await _dio.post('/client/users/block', data: body.toJson());
  }

  Future<void> unblockUser(int userId) async {
    await _dio.delete('/client/users/block/$userId');
  }

  Future<List<UserResponse>> getBlockedUsers({
    int page = 1,
    int size = 50,
  }) async {
    final response = await _dio.get(
      '/client/users/blocked',
      queryParameters: {'page': page, 'size': size},
    );
    final List items = response.data['items'] ?? response.data;
    return items
        .map((e) => UserResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserResponse>> adminGetUsers({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/admin/users',
      queryParameters: {'page': page, 'size': size},
    );
    final List items = response.data['items'] ?? response.data;
    return items
        .map((e) => UserResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
