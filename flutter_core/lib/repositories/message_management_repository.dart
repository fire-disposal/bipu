import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/message_model.dart';
import '../models/paginated_response.dart';

class MessageManagementRepository {
  final ApiClient _apiClient = ApiClient();

  // Favorite (Star)
  Future<void> favoriteMessage(int messageId) async {
    await _apiClient.dio.post(ApiEndpoints.favoriteMessage(messageId));
  }

  Future<void> unfavoriteMessage(int messageId) async {
    await _apiClient.dio.delete(ApiEndpoints.favoriteMessage(messageId));
  }

  Future<PaginatedResponse<Message>> getFavoriteMessages({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.favorites,
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }

  // Sent/Received
  Future<PaginatedResponse<Message>> getSentMessages({
    int page = 1,
    int size = 20,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final Map<String, dynamic> queryParams = {'page': page, 'size': size};
    if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();

    final response = await _apiClient.dio.get(
      ApiEndpoints.sentMessages,
      queryParameters: queryParams,
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }

  Future<PaginatedResponse<Message>> getReceivedMessages({
    int page = 1,
    int size = 20,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final Map<String, dynamic> queryParams = {'page': page, 'size': size};
    if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();

    final response = await _apiClient.dio.get(
      ApiEndpoints.receivedMessages,
      queryParameters: queryParams,
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }

  // Archive
  Future<void> archiveMessage(int id) async {
    await _apiClient.dio.put(ApiEndpoints.archiveMessage(id));
  }

  // Batch
  Future<void> batchDeleteMessages(List<int> ids) async {
    await _apiClient.dio.delete(
      ApiEndpoints.batchDeleteMessages,
      data: {'ids': ids},
    );
  }

  // Stats
  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.messageManagementStats,
    );
    return response.data;
  }

  // Export
  Future<Map<String, dynamic>> exportMessagesAdvanced({
    required DateTime dateFrom,
    required DateTime dateTo,
    String format = 'json',
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.exportMessagesAdvanced,
      data: {
        'date_from': dateFrom.toIso8601String(),
        'date_to': dateTo.toIso8601String(),
        'format': format,
      },
    );
    return response.data;
  }

  // Search
  Future<PaginatedResponse<Message>> searchMessages({
    required String query,
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.searchMessages,
      queryParameters: {'q': query, 'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }
}
