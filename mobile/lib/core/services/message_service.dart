/// 消息业务逻辑层 - 统一处理消息相关的业务逻辑
/// 作用：解耦 UI 层和 API 层，提供一致的错误处理和验证
library message_service;

import 'package:bipupu/core/network/network.dart';
import 'dart:developer' as developer;

/// 消息发送结果
class MessageSendResult {
  final MessageResponse? message;
  final bool success;
  final String? errorMessage;
  final MessageSendStatus status;

  MessageSendResult({
    this.message,
    required this.success,
    this.errorMessage,
    required this.status,
  });

  factory MessageSendResult.success(MessageResponse message) {
    return MessageSendResult(
      message: message,
      success: true,
      status: MessageSendStatus.success,
    );
  }

  factory MessageSendResult.failure(String errorMessage) {
    return MessageSendResult(
      success: false,
      errorMessage: errorMessage,
      status: MessageSendStatus.failed,
    );
  }
}

enum MessageSendStatus { sending, success, failed, retry }

/// 消息服务层 - 提供统一的消息操作接口
class MessageService {
  static final MessageService _instance = MessageService._internal();

  factory MessageService() => _instance;

  MessageService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  /// 获取消息列表
  Future<MessageListResponse> getMessages({
    required String direction,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      developer.log(
        'MessageService: Fetching messages, direction=$direction, page=$page',
      );

      final MessageListResponse response;
      if (direction == 'sent') {
        response = await _apiClient.api.messages.getApiMessagesSent(
          page: page,
          pageSize: pageSize,
        );
      } else {
        response = await _apiClient.api.messages.getApiMessagesInbox(
          page: page,
          pageSize: pageSize,
        );
      }

      developer.log('MessageService: Got ${response.messages.length} messages');
      return response;
    } on ApiException catch (e) {
      developer.log('MessageService: Error fetching messages: ${e.message}');
      rethrow;
    } catch (e) {
      developer.log('MessageService: Unknown error fetching messages: $e');
      rethrow;
    }
  }

  /// 获取发送的消息
  Future<MessageListResponse> getSentMessages({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      developer.log('MessageService: Fetching sent messages, page=$page');

      final response = await _apiClient.api.messages.getApiMessagesSent(
        page: page,
        pageSize: pageSize,
      );

      return response;
    } on ApiException catch (e) {
      developer.log(
        'MessageService: Error fetching sent messages: ${e.message}',
      );
      rethrow;
    }
  }

  /// 发送消息（统一接口，包含验证和错误处理）
  Future<MessageSendResult> sendMessage({
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.normal,
    Map<String, dynamic>? pattern,
    List<int>? waveform,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    developer.log('MessageService: Sending message to $receiverId');

    // 前置验证
    try {
      _validateMessageInput(receiverId: receiverId, content: content);
    } catch (e) {
      developer.log('MessageService: Validation failed: $e');
      return MessageSendResult.failure(e.toString());
    }

    try {
      final messageCreate = MessageCreate(
        receiverId: receiverId,
        content: content,
        messageType: messageType,
        pattern: pattern,
        waveform: waveform,
      );

      final response = await _apiClient
          .execute(
            () => _apiClient.api.messages.postApiMessages(body: messageCreate),
            operationName: 'SendMessage',
          )
          .timeout(timeout);

      developer.log('MessageService: Message sent successfully');
      return MessageSendResult.success(response);
    } on ApiException catch (e) {
      developer.log('MessageService: API error: ${e.message}');
      return MessageSendResult.failure(_mapApiErrorToMessage(e));
    } catch (e) {
      // 捕获 TimeoutException 和其他异常
      if (e.toString().contains('TimeoutException')) {
        developer.log('MessageService: Send timeout');
        return MessageSendResult.failure('发送超时，请检查网络连接');
      }
      developer.log('MessageService: Unknown error: $e');
      return MessageSendResult.failure('发送失败: $e');
    }
  }

  /// 批量发送消息（用于转发等场景）
  Future<List<MessageSendResult>> sendMessagesBatch({
    required List<String> receiverIds,
    required String content,
    MessageType messageType = MessageType.normal,
  }) async {
    developer.log(
      'MessageService: Batch sending to ${receiverIds.length} receivers',
    );

    final results = <MessageSendResult>[];

    for (final receiverId in receiverIds) {
      final result = await sendMessage(
        receiverId: receiverId,
        content: content,
        messageType: messageType,
      );
      results.add(result);

      // 避免过快，防止限流
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final successCount = results.where((r) => r.success).length;
    developer.log(
      'MessageService: Batch send completed, $successCount/${receiverIds.length} success',
    );

    return results;
  }

  /// 获取收藏消息
  Future<FavoriteListResponse> getFavorites({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      developer.log('MessageService: Fetching favorites, page=$page');

      final response = await _apiClient.api.messages.getApiMessagesFavorites(
        page: page,
        pageSize: pageSize,
      );

      return response;
    } on ApiException catch (e) {
      developer.log('MessageService: Error fetching favorites: ${e.message}');
      rethrow;
    }
  }

  /// 添加收藏
  Future<void> addFavorite(int messageId, {String note = ''}) async {
    try {
      developer.log('MessageService: Adding favorite for message $messageId');

      await _apiClient.api.messages.postApiMessagesMessageIdFavorite(
        messageId: messageId,
        body: FavoriteCreate(note: note),
      );

      developer.log('MessageService: Favorite added successfully');
    } on ApiException catch (e) {
      developer.log('MessageService: Error adding favorite: ${e.message}');
      rethrow;
    }
  }

  /// 删除收藏
  Future<void> removeFavorite(int messageId) async {
    try {
      developer.log('MessageService: Removing favorite for message $messageId');

      await _apiClient.api.messages.deleteApiMessagesMessageIdFavorite(
        messageId: messageId,
      );

      developer.log('MessageService: Favorite removed successfully');
    } on ApiException catch (e) {
      developer.log('MessageService: Error removing favorite: ${e.message}');
      rethrow;
    }
  }

  /// 前置验证
  void _validateMessageInput({
    required String receiverId,
    required String content,
  }) {
    if (receiverId.isEmpty) {
      throw ArgumentError('接收者 ID 不能为空');
    }

    if (content.trim().isEmpty) {
      throw ArgumentError('消息内容不能为空');
    }

    if (content.length > 5000) {
      throw ArgumentError('消息内容不能超过5000字符');
    }
  }

  /// 将 API 异常映射为用户友好的错误消息
  String _mapApiErrorToMessage(ApiException e) {
    if (e is AuthException) {
      return '认证失败，请重新登录';
    } else if (e is NetworkException) {
      return '网络错误，请检查连接';
    } else if (e.statusCode == 404) {
      return '接收者不存在';
    } else if (e.statusCode == 429) {
      return '发送过于频繁，请稍后再试';
    } else if (e.statusCode == 400) {
      return '请求参数错误';
    } else if (e.statusCode == 500) {
      return '服务器错误，请稍后重试';
    } else {
      return e.message;
    }
  }
}
