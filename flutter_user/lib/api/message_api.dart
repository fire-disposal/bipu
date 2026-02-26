import 'package:dio/dio.dart';
import 'package:flutter_user/models/message/message_response.dart';
import 'package:flutter_user/models/message/message_create.dart';
import 'package:flutter_user/models/favorite/favorite.dart';
import 'package:flutter_user/models/common/paginated_response.dart';

class MessageApi {
  final Dio _dio;

  MessageApi(this._dio);

  Future<PaginatedResponse<MessageResponse>> getMessages({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/messages/',
      queryParameters: {'page': page, 'page_size': size},
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['messages'] as List)
        .map((item) => MessageResponse.fromJson(item))
        .toList();

    return PaginatedResponse<MessageResponse>(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      size: data['page_size'] as int,
    );
  }

  Future<MessageResponse> sendMessage(MessageCreate body) async {
    final response = await _dio.post('/api/messages/', data: body.toJson());
    return MessageResponse.fromJson(response.data);
  }

  Future<MessageResponse> sendMessageSimple({
    required String receiverId,
    required String content,
    String messageType = 'NORMAL',
    Map<String, dynamic>? pattern,
    List<int>? waveform,
  }) async {
    final body = MessageCreate(
      receiverId: receiverId,
      content: content,
      messageType: messageType,
      pattern: pattern,
      waveform: waveform,
    );
    return sendMessage(body);
  }

  Future<PaginatedResponse<MessageResponse>> pollMessages({
    int? lastMessageId,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/messages/poll',
      queryParameters: {
        if (lastMessageId != null) 'last_message_id': lastMessageId,
        'page_size': size,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['messages'] as List)
        .map((item) => MessageResponse.fromJson(item))
        .toList();

    return PaginatedResponse<MessageResponse>(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      size: data['page_size'] as int,
    );
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

    final data = response.data as Map<String, dynamic>;
    final items = (data['favorites'] as List)
        .map((item) => Favorite.fromJson(item))
        .toList();

    return PaginatedResponse<Favorite>(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      size: data['page_size'] as int,
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
