import 'package:get/get.dart';
import '../repos/message_repo.dart';
import '../shared/models/message_model.dart';
import '../controllers/auth_controller.dart';

/// 极简消息控制器 - GetX风格
class MessageController extends GetxController {
  static MessageController get to => Get.find();

  // 状态
  final messages = <MessageResponse>[].obs;
  final favorites = <MessageResponse>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final lastMessageId = 0.obs;

  // 仓库
  final MessageRepo _repo = MessageRepo();

  /// 发送消息
  Future<void> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'NORMAL',
    Map<String, dynamic>? pattern,
    List<int>? waveform,
  }) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.sendMessage(
        receiverId: receiverId,
        content: content,
        messageType: messageType,
        pattern: pattern,
        waveform: waveform,
      );

      if (result['success'] == true) {
        Get.snackbar('成功', '消息发送成功');

        // 刷新消息列表
        await loadMessages();
      } else {
        error.value = result['error'] as String;
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '发送失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载消息列表
  Future<void> loadMessages({
    String? direction,
    int? page,
    int? pageSize,
  }) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.getMessages(
        direction: direction,
        page: page,
        pageSize: pageSize,
      );

      if (result['success'] == true) {
        final newMessages = result['data'] as List<MessageResponse>;
        messages.value = newMessages;

        // 更新最后一条消息ID
        if (newMessages.isNotEmpty) {
          lastMessageId.value = newMessages.last.id;
        }
      } else {
        error.value = result['error'] as String;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// 轮询新消息
  Future<void> pollNewMessages() async {
    try {
      final result = await _repo.pollMessages(
        lastMsgId: lastMessageId.value,
        timeout: 30,
      );

      if (result['success'] == true) {
        final newMessages = result['data'] as List<MessageResponse>;
        if (newMessages.isNotEmpty) {
          messages.addAll(newMessages);
          lastMessageId.value = newMessages.last.id;

          // 显示通知
          if (newMessages.length == 1) {
            Get.snackbar('新消息', '收到1条新消息');
          } else {
            Get.snackbar('新消息', '收到${newMessages.length}条新消息');
          }
        }
      }
    } catch (e) {
      // 轮询失败是正常的，不显示错误
    }
  }

  /// 加载收藏消息
  Future<void> loadFavorites({int? page, int? pageSize}) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.getFavorites(page: page, pageSize: pageSize);

      if (result['success'] == true) {
        favorites.value = result['data'] as List<MessageResponse>;
      } else {
        error.value = result['error'] as String;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// 收藏消息
  Future<void> addFavorite(int messageId) async {
    try {
      final result = await _repo.addFavorite(messageId);

      if (result['success'] == true) {
        Get.snackbar('成功', '已收藏');

        // 刷新收藏列表
        await loadFavorites();
      } else {
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      Get.snackbar('错误', '收藏失败: $e');
    }
  }

  /// 取消收藏
  Future<void> removeFavorite(int messageId) async {
    try {
      final result = await _repo.removeFavorite(messageId);

      if (result['success'] == true) {
        Get.snackbar('成功', '已取消收藏');

        // 刷新收藏列表
        await loadFavorites();
      } else {
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      Get.snackbar('错误', '取消收藏失败: $e');
    }
  }

  /// 删除消息
  Future<void> deleteMessage(int messageId) async {
    try {
      final result = await _repo.deleteMessage(messageId);

      if (result['success'] == true) {
        Get.snackbar('成功', '消息已删除');

        // 从列表中移除
        messages.removeWhere((msg) => msg.id == messageId);
        favorites.removeWhere((msg) => msg.id == messageId);
      } else {
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      Get.snackbar('错误', '删除失败: $e');
    }
  }

  /// 获取消息统计
  Map<String, int> getMessageStats() {
    final currentUserBipupuId = AuthController.to.user.value?.bipupuId;
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

  /// 初始化
  @override
  void onInit() {
    super.onInit();
    // 初始加载消息
    loadMessages();
    loadFavorites();
  }
}
