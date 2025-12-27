import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/message_model.dart';
import '../models/paginated_response.dart';

class MessageRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Message> createMessage(Map<String, dynamic> messageData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.messages,
        data: messageData,
      );
      return Message.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<PaginatedResponse<Message>> getMessages({
    int page = 1,
    int size = 100,
    MessageType? messageType,
    MessageStatus? status,
    bool? isRead,
    int? senderId,
    int? receiverId,
  }) async {
    try {
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

      // Backend returns {items: [], total: 0, page: 1, size: 100}
      return PaginatedResponse.fromJson(
        response.data,
        (json) => Message.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<PaginatedResponse<Message>> getFavoriteMessages({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.messageFavorites,
        queryParameters: {'page': page, 'size': size},
      );
      return PaginatedResponse.fromJson(
        response.data,
        (json) => Message.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<PaginatedResponse<Message>> getSentMessages({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.messageSent,
        queryParameters: {'page': page, 'size': size},
      );
      return PaginatedResponse.fromJson(
        response.data,
        (json) => Message.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<PaginatedResponse<Message>> getReceivedMessages({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.messageReceived,
        queryParameters: {'page': page, 'size': size},
      );
      return PaginatedResponse.fromJson(
        response.data,
        (json) => Message.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createSystemNotification({
    required String title,
    required String content,
    int priority = 5,
    List<int>? targetUsers,
    Map<String, dynamic>? pattern,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.systemNotifications,
        queryParameters: {
          'title': title,
          'content': content,
          'priority': priority,
        },
        data: {
          if (targetUsers != null) 'target_users': targetUsers,
          if (pattern != null) 'pattern': pattern,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
