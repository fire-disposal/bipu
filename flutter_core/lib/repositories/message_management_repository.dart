import '../core/network/api_client.dart';
import '../models/message_model.dart';
import '../models/paginated_response.dart';

class MessageManagementRepository {
  final _client = ApiClient().restClient;

  // Favorite (Star)
  Future<void> favoriteMessage(int messageId) {
    return _client.favoriteMessage(messageId);
  }

  Future<void> unfavoriteMessage(int messageId) {
    return _client.unfavoriteMessage(messageId);
  }

  Future<PaginatedResponse<Message>> getFavoriteMessages({
    int page = 1,
    int size = 20,
  }) {
    return _client.getFavoriteMessages(page: page, size: size);
  }

  // Sent/Received
  Future<PaginatedResponse<Message>> getSentMessages({
    int page = 1,
    int size = 20,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return _client.getSentMessages(
      page: page,
      size: size,
      dateFrom: dateFrom?.toIso8601String(),
      dateTo: dateTo?.toIso8601String(),
    );
  }

  Future<PaginatedResponse<Message>> getReceivedMessages({
    int page = 1,
    int size = 20,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return _client.getReceivedMessages(
      page: page,
      size: size,
      dateFrom: dateFrom?.toIso8601String(),
      dateTo: dateTo?.toIso8601String(),
    );
  }

  // Archive
  Future<void> archiveMessage(int id) {
    return _client.archiveMessage(id);
  }

  // Batch
  Future<void> batchDeleteMessages(List<int> ids) {
    return _client.batchDeleteMessages({'ids': ids});
  }

  // Stats
  Future<dynamic> getStats() {
    return _client.getMessageManagementStats();
  }

  // Export
  Future<dynamic> exportMessagesAdvanced({
    required DateTime dateFrom,
    required DateTime dateTo,
    String format = 'json',
  }) {
    return _client.exportMessagesAdvanced({
      'date_from': dateFrom.toIso8601String(),
      'date_to': dateTo.toIso8601String(),
      'format': format,
    });
  }

  // Search
  Future<PaginatedResponse<Message>> searchMessages({
    String? query,
    int page = 1,
    int size = 20,
  }) {
    return _client.searchMessages(query: query, page: page, size: size);
  }
}
