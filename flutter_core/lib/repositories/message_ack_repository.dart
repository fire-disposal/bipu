import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/message_ack_event.dart';
import '../models/paginated_response.dart';

class MessageAckRepository {
  final ApiClient _apiClient = ApiClient();

  Future<MessageAckEvent> createMessageAckEvent(
    MessageAckEventCreate event,
  ) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.messageAck,
      data: event.toJson(),
    );
    return MessageAckEvent.fromJson(response.data);
  }

  Future<List<MessageAckEvent>> getMessageAckEvents(int messageId) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.messageAcks(messageId),
    );
    // OpenApi says "Get Message Ack Events" -> returns array
    return (response.data as List)
        .map((e) => MessageAckEvent.fromJson(e))
        .toList();
  }

  Future<PaginatedResponse<MessageAckEvent>> getAllAckEvents({
    int page = 1,
    int size = 100,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.adminMessageAcksAll,
      queryParameters: {'page': page, 'size': size},
    );
    // Assuming backend returns PaginatedResponse for admin endpoint, or list?
    // /api/message-ack/admin/all. OpenApi says PaginatedResponse[MessageAckEventResponse] usually.
    // If list:
    if (response.data is List) {
      final list = response.data as List;
      return PaginatedResponse(
        items: list.map((e) => MessageAckEvent.fromJson(e)).toList(),
        total: list.length,
        page: page,
        size: size,
      );
    }
    return PaginatedResponse.fromJson(
      response.data,
      (json) => MessageAckEvent.fromJson(json),
    );
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.adminMessageAckStats,
    );
    return response.data;
  }
}
