import 'package:get/get.dart';
import 'base_service.dart';
import '../models/message_model.dart';

/// 消息服务 - 替换MessageRepo
class MessageService extends BaseService {
  static MessageService get instance => Get.find();

  final messages = <MessageResponse>[].obs;
  final favorites = <MessageResponse>[].obs;
  final isLoading = false.obs;
  final RxString error = ''.obs;
  final lastMessageId = 0.obs;

  /// 发送消息
  Future<ServiceResponse<MessageResponse>> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'NORMAL',
    Map<String, dynamic>? pattern,
    List<int>? waveform,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await post<MessageResponse>(
      '/api/messages/',
      data: {
        'receiver_id': receiverId,
        'content': content,
        'message_type': messageType,
        if (pattern != null) 'pattern': pattern,
        if (waveform != null) 'waveform': waveform,
      },
      fromJson: (json) => MessageResponse.fromJson(json),
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      messages.insert(0, response.data!);
      Get.snackbar('成功', '消息发送成功', duration: const Duration(seconds: 2));
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 获取消息列表
  Future<ServiceResponse<List<MessageResponse>>> getMessages({
    String? direction,
    int? page,
    int? pageSize,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await get<List<dynamic>>(
      '/api/messages/',
      query: {
        if (direction != null) 'direction': direction,
        if (page != null) 'page': page.toString(),
        if (pageSize != null) 'page_size': pageSize.toString(),
      },
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      final messageList = response.data!
          .map((json) => MessageResponse.fromJson(json as Map<String, dynamic>))
          .toList();
      messages.assignAll(messageList);
      return ServiceResponse.success(messageList);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return ServiceResponse.failure(
      response.error ?? ServiceError('获取消息失败', ServiceErrorType.unknown),
    );
  }

  /// 长轮询获取新消息
  Future<ServiceResponse<List<MessageResponse>>> pollMessages({
    required int lastMsgId,
    int? timeout,
  }) async {
    final response = await get<List<dynamic>>(
      '/api/messages/poll',
      query: {
        'last_msg_id': lastMsgId.toString(),
        if (timeout != null) 'timeout': timeout.toString(),
      },
    );

    if (response.success && response.data != null) {
      final newMessages = response.data!
          .map((json) => MessageResponse.fromJson(json as Map<String, dynamic>))
          .toList();

      if (newMessages.isNotEmpty) {
        // 更新最后一条消息ID
        final latestId = newMessages
            .map((msg) => msg.id)
            .reduce((a, b) => a > b ? a : b);
        lastMessageId.value = latestId;

        // 添加新消息到列表
        messages.addAll(newMessages);
      }

      return ServiceResponse.success(newMessages);
    }

    return ServiceResponse.failure(
      response.error ?? ServiceError('轮询消息失败', ServiceErrorType.unknown),
    );
  }

  /// 获取收藏消息列表
  Future<ServiceResponse<List<MessageResponse>>> getFavorites({
    int? page,
    int? pageSize,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await get<List<dynamic>>(
      '/api/messages/favorites',
      query: {
        if (page != null) 'page': page.toString(),
        if (pageSize != null) 'page_size': pageSize.toString(),
      },
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      final favoriteList = response.data!
          .map((json) => MessageResponse.fromJson(json as Map<String, dynamic>))
          .toList();
      favorites.assignAll(favoriteList);
      return ServiceResponse.success(favoriteList);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return ServiceResponse.failure(
      response.error ?? ServiceError('获取收藏消息失败', ServiceErrorType.unknown),
    );
  }

  /// 收藏消息
  Future<ServiceResponse<MessageResponse>> addFavorite(int messageId) async {
    final response = await post<MessageResponse>(
      '/api/messages/$messageId/favorite',
      fromJson: (json) => MessageResponse.fromJson(json),
    );

    if (response.success && response.data != null) {
      // 更新消息的收藏状态
      final index = messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        // 在实际项目中，MessageResponse可能需要添加isFavorite字段
        // 这里简单地将消息添加到收藏列表
        favorites.add(response.data!);
      }
      Get.snackbar('成功', '消息已收藏', duration: const Duration(seconds: 2));
    } else if (response.error != null) {
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 取消收藏
  Future<ServiceResponse<void>> removeFavorite(int messageId) async {
    final response = await delete<void>('/api/messages/$messageId/favorite');

    if (response.success) {
      // 从收藏列表中移除
      favorites.removeWhere((msg) => msg.id == messageId);
      Get.snackbar('成功', '已取消收藏', duration: const Duration(seconds: 2));
    } else if (response.error != null) {
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 删除消息
  Future<ServiceResponse<void>> deleteMessage(int messageId) async {
    final response = await delete<void>('/api/messages/$messageId');

    if (response.success) {
      // 从消息列表中移除
      messages.removeWhere((msg) => msg.id == messageId);
      // 从收藏列表中移除（如果存在）
      favorites.removeWhere((msg) => msg.id == messageId);
      Get.snackbar('成功', '消息已删除', duration: const Duration(seconds: 2));
    } else if (response.error != null) {
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 清空错误信息
  void clearError() {
    error.value = '';
  }

  /// 获取消息统计
  Map<String, int> getMessageStats(String? currentUserBipupuId) {
    if (currentUserBipupuId == null) {
      return {
        'total': messages.length,
        'sent': 0,
        'received': 0,
        'favorites': favorites.length,
      };
    }

    final sent = messages
        .where((msg) => msg.senderBipupuId == currentUserBipupuId)
        .length;
    final received = messages
        .where((msg) => msg.receiverBipupuId == currentUserBipupuId)
        .length;

    return {
      'total': messages.length,
      'sent': sent,
      'received': received,
      'favorites': favorites.length,
    };
  }

  /// 根据ID查找消息
  MessageResponse? findMessageById(int messageId) {
    return messages.firstWhereOrNull((msg) => msg.id == messageId);
  }

  /// 清空所有消息
  void clearAll() {
    messages.clear();
    favorites.clear();
    lastMessageId.value = 0;
    error.value = '';
  }
}
