import 'api.dart';
import '../models/message/message_response.dart';
import '../models/favorite/favorite.dart';
import '../models/common/paginated_response.dart';

class MessageApi {
  final ApiClient _api;

  MessageApi([ApiClient? client]) : _api = client ?? api;

  Future<PaginatedResponse<MessageResponse>> getMessages({
    String direction = 'received',
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

    // Normalize backend variations
    if (data.containsKey('items')) {
      return PaginatedResponse.fromJson(
        data,
        (json) => MessageResponse.fromJson(json as Map<String, dynamic>),
      );
    }

    final mapped = {
      'items': data['messages'] ?? data['items'] ?? [],
      'total': data['total'] ?? 0,
      'page': data['page'] ?? page,
      'size': data['page_size'] ?? data['size'] ?? size,
      'pages':
          data['pages'] ??
          ((data['total'] ?? 0) / (data['page_size'] ?? size)).ceil(),
    };

    return PaginatedResponse.fromJson(
      Map<String, dynamic>.from(mapped),
      (json) => MessageResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MessageResponse> sendMessage({
    required String receiverId,
    required Object content,
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

    final resp = await _api.post<Map<String, dynamic>>(
      '/api/messages/',
      data: body,
    );
    return MessageResponse.fromJson(resp as Map<String, dynamic>);
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

  Future<PaginatedResponse<Favorite>> getFavorites({
    int page = 1,
    int size = 20,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/messages/favorites',
      queryParameters: {'page': page, 'page_size': size},
    );

    if (data.containsKey('items')) {
      return PaginatedResponse.fromJson(
        data,
        (json) => Favorite.fromJson(json as Map<String, dynamic>),
      );
    }

    final mapped = {
      'items': data['favorites'] ?? data['items'] ?? [],
      'total': data['total'] ?? 0,
      'page': data['page'] ?? page,
      'size': data['page_size'] ?? data['size'] ?? size,
      'pages':
          data['pages'] ??
          ((data['total'] ?? 0) / (data['page_size'] ?? size)).ceil(),
    };

    return PaginatedResponse.fromJson(
      Map<String, dynamic>.from(mapped),
      (json) => Favorite.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Favorite> addFavorite(int messageId, {String? note}) async {
    final resp = await _api.post<Map<String, dynamic>>(
      '/api/messages/$messageId/favorite',
      data: note != null ? {'note': note} : null,
    );
    return Favorite.fromJson(resp as Map<String, dynamic>);
  }

  Future<void> removeFavorite(int messageId) async {
    await _api.delete<void>('/api/messages/$messageId/favorite');
  }
}
