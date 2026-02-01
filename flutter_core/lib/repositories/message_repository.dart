import '../core/network/api_client.dart';
import '../models/message_model.dart';
import '../models/paginated_response.dart';

class MessageRepository {
  final _client = ApiClient().restClient;

  // Create
  Future<Message> createMessage(Map<String, dynamic> messageData) {
    return _client.createMessage(messageData);
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
  }) {
    return _client.getMessages(
      page: page,
      size: size,
      messageType: messageType?.toString().split('.').last,
      status: status?.toString().split('.').last,
      isRead: isRead,
      senderId: senderId,
      receiverId: receiverId,
    );
  }

  // Delete All Read
  Future<void> deleteReadMessages() {
    return _client.deleteReadMessages();
  }

  // Conversation
  Future<PaginatedResponse<Message>> getConversationMessages(
    int userId, {
    int page = 1,
    int size = 20,
  }) {
    return _client.getConversationMessages(userId, page: page, size: size);
  }

  // Unread
  Future<int> getUnreadCount() async {
    final count = await _client.getUnreadCount();
    return count;
  }

  Future<PaginatedResponse<Message>> getUnreadMessages({
    int page = 1,
    int size = 20,
  }) {
    return _client.getUnreadMessages(page: page, size: size);
  }

  // Recent
  Future<List<Message>> getRecentMessages({int limit = 10}) {
    return _client.getRecentMessages(limit: limit);
  }

  // Get Received Messages
  Future<PaginatedResponse<Message>> getReceivedMessages({
    int page = 1,
    int size = 20,
    int? userId,
  }) {
    // Note: userId param is unused in the original implementation for the API call
    return _client.getReceivedMessages(page: page, size: size);
  }

  // Get Sent Messages
  Future<PaginatedResponse<Message>> getSentMessages({
    int page = 1,
    int size = 20,
    int? userId,
  }) {
    return _client.getSentMessages(page: page, size: size);
  }

  // Message Detail
  Future<Message> getMessage(int id) {
    return _client.getMessage(id);
  }

  Future<Message> updateMessage(int id, Map<String, dynamic> data) {
    return _client.updateMessage(id, data);
  }

  Future<void> deleteMessage(int id) {
    return _client.deleteMessage(id);
  }

  // Read Status
  Future<void> markAsRead(int id) {
    return _client.markAsRead(id);
  }

  Future<void> markAllAsRead() {
    return _client.markAllAsRead();
  }

  // Stats
  Future<dynamic> getMessageStats() {
    return _client.getMessageStats();
  }

  // Admin
  Future<PaginatedResponse<Message>> adminGetAllMessages({
    int page = 1,
    int size = 20,
    // Add other filters as needed
  }) {
    return _client.adminGetAllMessages(page: page, size: size);
  }

  Future<void> adminDeleteMessage(int id) {
    return _client.adminDeleteMessage(id);
  }

  Future<dynamic> adminGetMessageStats() {
    return _client.adminGetMessageStats();
  }
}
