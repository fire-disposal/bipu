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
    required Object content, // can be String or Map (JSON)
    String msgType = 'NORMAL',
    Map<String, dynamic>? pattern,
  }) async {
    // Normalize to new `message_type` key while keeping legacy `msg_type` for compatibility
    final normalized = _normalizeToNewType(msgType);
    final body = {
      'receiver_id': receiverId,
      'content': content,
      'message_type': normalized,
      'msg_type': msgType, // legacy
      'pattern': pattern,
    };
    final response = await _dio.post('/api/messages/', data: body);
    return MessageResponse.fromJson(response.data);
  }

  String _normalizeToNewType(String raw) {
    final s = raw.toUpperCase();
    switch (s) {
      case 'SYSTEM':
      case 'ALERT':
      case 'NOTIFICATION':
        return 'SYSTEM';
      case 'VOICE':
      case 'VOICE_TRANSCRIPT':
        return 'VOICE';
      case 'USER':
      case 'USER_POSTCARD':
      case 'COSMIC_BROADCAST':
      case 'SERVICE_REPLY':
      default:
        return 'NORMAL';
    }
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
      import 'api.dart';
      import '../models/message/message_response.dart';
      import '../models/favorite/favorite.dart';
      import '../models/common/paginated_response.dart';

      class MessageApi {
        final ApiClient _api;

        MessageApi([ApiClient? client]) : _api = client ?? api;

        Future<PaginatedResponse<MessageResponse>> getMessages({
          String direction = 'received', // 'sent' or 'received'
          int page = 1,
          int size = 20,
        }) async {
          final data = await _api.get<Map<String, dynamic>>(
            '/api/messages/',
            queryParameters: {
              'direction': direction,
              'page': page,
              'page_size': size,
            },
          );

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
          required Object content, // can be String or Map (JSON)
          String msgType = 'NORMAL',
          Map<String, dynamic>? pattern,
        }) async {
          final normalized = _normalizeToNewType(msgType);
          final body = {
            'receiver_id': receiverId,
            'content': content,
            'message_type': normalized,
            'msg_type': msgType,
            'pattern': pattern,
          };
          final resp = await _api.post<Map<String, dynamic>>('/api/messages/', data: body);
          return MessageResponse.fromJson(resp);
        }

        String _normalizeToNewType(String raw) {
          final s = raw.toUpperCase();
          switch (s) {
            case 'SYSTEM':
            case 'ALERT':
            case 'NOTIFICATION':
              return 'SYSTEM';
            case 'VOICE':
            case 'VOICE_TRANSCRIPT':
              return 'VOICE';
            case 'USER':
            case 'USER_POSTCARD':
            case 'COSMIC_BROADCAST':
            case 'SERVICE_REPLY':
            default:
              return 'NORMAL';
          }
        }

        Future<void> deleteMessage(int messageId) async {
          await _api.delete<void>('/api/messages/$messageId');
        }

        // Favorites
        Future<PaginatedResponse<Favorite>> getFavorites({
          int page = 1,
          int size = 20,
        }) async {
          final data = await _api.get<Map<String, dynamic>>(
            '/api/messages/favorites',
            queryParameters: {'page': page, 'page_size': size},
          );
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
          final resp = await _api.post<Map<String, dynamic>>(
            '/api/messages/$messageId/favorite',
            data: note != null ? {'note': note} : null,
          );
          return Favorite.fromJson(resp);
        }

        Future<void> removeFavorite(int messageId) async {
          await _api.delete<void>('/api/messages/$messageId/favorite');
        }
      }
