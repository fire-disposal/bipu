import 'package:dio/dio.dart';
import '../models/message/message_response.dart';
import '../models/favorite/favorite.dart';
import '../models/common/paginated_response.dart';

class MessageApi {
  final Dio _dio;

  MessageApi(this._dio);

  Future<PaginatedResponse<MessageResponse>> getMessages({
    String direction = 'received', // 'sent' or 'received'
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/messages/',
      queryParameters: {
        'direction': direction,
        'page': page,
        'page_size': size,
      },
    );
    // Note: Backend might return 'total', 'messages', 'page', 'page_size' directly
    // If the backend returns { "messages": [...], "total": ... } we need to adapt PaginatedResponse
    // or manually parse. Let's assume standard PaginatedResponse format or adapt.
    // If backend returns: { messages: [], total: 100, page: 1, page_size: 20 }

    // Custom parsing if PaginatedResponse expects "items" or similar
    final data = response.data;
    return PaginatedResponse(
      items: (data['messages'] as List)
          .map((e) => MessageResponse.fromJson(e))
          .toList(),
      total: data['total'],
      page: data['page'],
      size: data['page_size'],
      pages: (data['total'] / data['page_size']).ceil(),
    );
  }

  Future<MessageResponse> sendMessage({
    required String receiverId, // bipupu_id or service name
    required String content,
    String msgType = 'USER_POSTCARD',
    Map<String, dynamic>? pattern,
  }) async {
    final response = await _dio.post(
      '/api/messages/',
      data: {
        'receiver_id': receiverId,
        'content': content,
        'msg_type': msgType,
        'pattern': pattern,
      },
    );
    return MessageResponse.fromJson(response.data);
  }

  Future<void> deleteMessage(int messageId) async {
    await _dio.delete('/api/messages/$messageId');
  }

  // Favorites
  Future<PaginatedResponse<Favorite>> getFavorites({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/messages/favorites',
      queryParameters: {'page': page, 'page_size': size},
    );
    final data = response.data;
    return PaginatedResponse(
      items: (data['favorites'] as List)
          .map((e) => Favorite.fromJson(e))
          .toList(),
      total: data['total'],
      page: data['page'],
      size: data['page_size'],
      pages: (data['total'] / data['page_size']).ceil(),
    );
  }

  Future<Favorite> addFavorite(int messageId, {String? note}) async {
    final response = await _dio.post(
      '/api/messages/$messageId/favorite',
      data: note != null ? {'note': note} : null,
    );
    return Favorite.fromJson(response.data);
  }

  Future<void> removeFavorite(int messageId) async {
    await _dio.delete('/api/messages/$messageId/favorite');
  }
}
