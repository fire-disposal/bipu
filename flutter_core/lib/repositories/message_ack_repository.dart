import '../core/network/api_client.dart';
import '../models/message_ack_event.dart';
import '../models/paginated_response.dart';

class MessageAckRepository {
  final _client = ApiClient().restClient;

  Future<MessageAckEvent> createMessageAckEvent(MessageAckEventCreate event) {
    return _client.createMessageAckEvent(event.toJson());
  }

  Future<List<MessageAckEvent>> getMessageAckEvents(int messageId) {
    return _client.getMessageAckEvents(messageId);
  }

  Future<PaginatedResponse<MessageAckEvent>> getAllAckEvents({
    int page = 1,
    int size = 100,
  }) {
    return _client.getAllAckEvents(page: page, size: size);
  }

  Future<dynamic> getStats() {
    return _client.getAckStats();
  }
}
