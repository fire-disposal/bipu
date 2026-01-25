import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/message_model.dart';
import '../models/paginated_response.dart';

class MessageRepository {
  final ApiClient _apiClient = ApiClient();

  // Create
  Future<Message> createMessage(Map<String, dynamic> messageData) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.messages,
      data: messageData,
    );
    return Message.fromJson(response.data);
  }

  // Get List
  Future<PaginatedResponse<Message>> getMessages({
    int page = 1,
    int size = 20,
    MessageType? messageType,
    MessageStatus? status,
    bool? isRead,
    int? senderId,
    int? receiverId,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.messages,
      queryParameters: {
        'page': page,
        'size': size,
        if (messageType != null)
          'message_type': messageType.toString().split('.').last,
        if (status != null) 'status': status.toString().split('.').last,
        if (isRead != null) 'is_read': isRead,
        if (senderId != null) 'sender_id': senderId,
        if (receiverId != null) 'receiver_id': receiverId,
      },
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }

  // Delete All Read
  Future<void> deleteReadMessages() async {
    await _apiClient.dio.delete(ApiEndpoints.messages);
  }

  // Conversation
  Future<PaginatedResponse<Message>> getConversationMessages(
    int userId, {
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.conversationMessages(userId),
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }

  // Unread
  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get(ApiEndpoints.unreadCount);
    return response.data['count'] ?? 0;
  }

  Future<PaginatedResponse<Message>> getUnreadMessages({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.unreadMessages,
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }

  // Recent
  Future<List<Message>> getRecentMessages({int limit = 10}) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.recentMessages,
      queryParameters: {'limit': limit},
    );
    if (response.data is List) {
      return (response.data as List).map((e) => Message.fromJson(e)).toList();
    }
    return [];
  }

  // Get Received Messages
  Future<PaginatedResponse<Message>> getReceivedMessages({
    int page = 1,
    int size = 20,
    int? userId,
  }) async {
    // If specific endpoints exist for current user, prefer them if userId is null or matches current
    // Here we use the generic endpoint with filter if userId provided,
    // OR we could use ApiEndpoints.receivedMessages if available.
    // Given ApiEndpoints.receivedMessages exists:

    // Note: If userId is provided and it's NOT the current user, we can't really get their received messages easily
    // unless we are admin. But this is Client App.
    // Let's assume this method is for "Current User's Received Messages".

    final response = await _apiClient.dio.get(
      ApiEndpoints.receivedMessages,
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }

  // Get Sent Messages
  Future<PaginatedResponse<Message>> getSentMessages({
    int page = 1,
    int size = 20,
    int? userId,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.sentMessages,
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }

  // Message Detail
  Future<Message> getMessage(int id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.messageDetails(id));
    return Message.fromJson(response.data);
  }

  Future<Message> updateMessage(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.messageDetails(id),
      data: data,
    );
    return Message.fromJson(response.data);
  }

  Future<void> deleteMessage(int id) async {
    await _apiClient.dio.delete(ApiEndpoints.messageDetails(id));
  }

  // Read Status
  Future<void> markAsRead(int id) async {
    await _apiClient.dio.put(ApiEndpoints.messageRead(id));
  }

  Future<void> markAllAsRead() async {
    await _apiClient.dio.put(ApiEndpoints.readAllMessages);
  }

  // Stats
  Future<Map<String, dynamic>> getMessageStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.messageStats);
    return response.data;
  }

  // Admin
  Future<PaginatedResponse<Message>> adminGetAllMessages({
    int page = 1,
    int size = 20,
    // Add other filters as needed
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.adminMessagesAll,
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }

  Future<void> adminDeleteMessage(int id) async {
    await _apiClient.dio.delete(ApiEndpoints.adminMessageDetails(id));
  }

  Future<Map<String, dynamic>> adminGetMessageStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminMessageStats);
    return response.data;
  }
}
