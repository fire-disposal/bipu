import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../api/rest_client.dart';
import '../shared/models/message_model.dart';

/// 极简消息仓库 - 直接调用API
class MessageRepo {
  static MessageRepo get to => Get.find();

  late final RestClient _api;

  MessageRepo() {
    _api = RestClient(Dio());
  }

  /// 发送消息
  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'NORMAL',
    Map<String, dynamic>? pattern,
    List<int>? waveform,
  }) async {
    try {
      final response = await _api.sendMessage({
        'receiver_id': receiverId,
        'content': content,
        'message_type': messageType,
        if (pattern != null) 'pattern': pattern,
        if (waveform != null) 'waveform': waveform,
      });

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '发送失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 获取消息列表
  Future<Map<String, dynamic>> getMessages({
    String? direction,
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await _api.getMessages(
        direction: direction,
        page: page,
        pageSize: pageSize,
      );

      if (response.response.statusCode == 200) {
        final messages = (response.data as List)
            .map((json) => MessageResponse.fromJson(json))
            .toList();
        return {'success': true, 'data': messages};
      } else {
        return {
          'success': false,
          'error': '获取消息失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 长轮询新消息
  Future<Map<String, dynamic>> pollMessages({
    required int lastMsgId,
    int? timeout,
  }) async {
    try {
      final response = await _api.pollMessages(
        lastMsgId: lastMsgId,
        timeout: timeout,
      );

      if (response.response.statusCode == 200) {
        final messages = (response.data as List)
            .map((json) => MessageResponse.fromJson(json))
            .toList();
        return {'success': true, 'data': messages};
      } else {
        return {
          'success': false,
          'error': '轮询失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 获取收藏消息
  Future<Map<String, dynamic>> getFavorites({int? page, int? pageSize}) async {
    try {
      final response = await _api.getFavorites(page: page, pageSize: pageSize);

      if (response.response.statusCode == 200) {
        final messages = (response.data as List)
            .map((json) => MessageResponse.fromJson(json))
            .toList();
        return {'success': true, 'data': messages};
      } else {
        return {
          'success': false,
          'error': '获取收藏失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 收藏消息
  Future<Map<String, dynamic>> addFavorite(int messageId) async {
    try {
      final response = await _api.addFavorite(messageId, null);

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '收藏失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 取消收藏
  Future<Map<String, dynamic>> removeFavorite(int messageId) async {
    try {
      await _api.removeFavorite(messageId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 删除消息
  Future<Map<String, dynamic>> deleteMessage(int messageId) async {
    try {
      await _api.deleteMessage(messageId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
