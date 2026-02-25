import 'package:get/get.dart';
import '../services/message_service.dart';
import '../models/message_model.dart';
import '../controllers/auth_controller.dart';

/// 极简消息控制器 - 使用新的MessageService
class MessageController extends GetxController {
  static MessageController get to => Get.find();

  // 依赖服务
  final MessageService _message = MessageService.instance;

  // 计算属性 - 直接暴露服务的状态
  List<MessageResponse> get messages => _message.messages;
  List<MessageResponse> get favorites => _message.favorites;
  bool get isLoading => _message.isLoading.value;
  String get error => _message.error.value;
  int get lastMessageId => _message.lastMessageId.value;

  /// 发送消息
  Future<void> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'NORMAL',
    Map<String, dynamic>? pattern,
    List<int>? waveform,
  }) async {
    final response = await _message.sendMessage(
      receiverId: receiverId,
      content: content,
      messageType: messageType,
      pattern: pattern,
      waveform: waveform,
    );

    if (response.success) {
      // 消息发送成功，状态已由MessageService更新
      // 可以在这里添加额外的UI逻辑
    } else if (response.error != null) {
      // 错误处理已由MessageService完成
      // 可以在这里添加额外的错误处理逻辑
    }
  }

  /// 获取消息列表
  Future<void> loadMessages({
    String? direction,
    int? page,
    int? pageSize,
  }) async {
    final response = await _message.getMessages(
      direction: direction,
      page: page,
      pageSize: pageSize,
    );

    if (response.success) {
      // 消息加载成功，状态已由MessageService更新
    } else if (response.error != null) {
      // 错误处理已由MessageService完成
    }
  }

  /// 长轮询获取新消息
  Future<void> pollNewMessages({int? timeout}) async {
    final response = await _message.pollMessages(
      lastMsgId: lastMessageId,
      timeout: timeout,
    );

    if (response.success &&
        response.data != null &&
        response.data!.isNotEmpty) {
      // 有新消息到达，状态已由MessageService更新
      // 可以在这里添加新消息通知逻辑
      Get.snackbar('新消息', '收到${response.data!.length}条新消息');
    }
  }

  /// 获取收藏消息列表
  Future<void> loadFavorites({int? page, int? pageSize}) async {
    final response = await _message.getFavorites(
      page: page,
      pageSize: pageSize,
    );

    if (response.success) {
      // 收藏消息加载成功，状态已由MessageService更新
    } else if (response.error != null) {
      // 错误处理已由MessageService完成
    }
  }

  /// 收藏消息
  Future<void> addToFavorites(int messageId) async {
    final response = await _message.addFavorite(messageId);

    if (response.success) {
      // 收藏成功，状态已由MessageService更新
    } else if (response.error != null) {
      // 错误处理已由MessageService完成
    }
  }

  /// 取消收藏
  Future<void> removeFromFavorites(int messageId) async {
    final response = await _message.removeFavorite(messageId);

    if (response.success) {
      // 取消收藏成功，状态已由MessageService更新
    } else if (response.error != null) {
      // 错误处理已由MessageService完成
    }
  }

  /// 删除消息
  Future<void> deleteMessage(int messageId) async {
    final response = await _message.deleteMessage(messageId);

    if (response.success) {
      // 删除成功，状态已由MessageService更新
    } else if (response.error != null) {
      // 错误处理已由MessageService完成
    }
  }

  /// 获取消息统计
  Map<String, int> getMessageStats() {
    final currentUserBipupuId = AuthController.to.currentUser?.bipupuId;
    return _message.getMessageStats(currentUserBipupuId);
  }

  /// 根据ID查找消息
  MessageResponse? findMessageById(int messageId) {
    return _message.findMessageById(messageId);
  }

  /// 清空错误信息
  void clearError() {
    _message.clearError();
  }

  /// 清空所有消息
  void clearAll() {
    _message.clearAll();
  }

  /// 开始轮询消息
  void startPolling({int intervalSeconds = 30}) {
    // 在实际项目中，这里应该实现定时轮询逻辑
    // 例如使用Timer.periodic或Worker
    // 这里只提供接口定义
  }

  /// 停止轮询消息
  void stopPolling() {
    // 停止定时轮询
  }

  /// 初始化
  @override
  void onInit() {
    super.onInit();
    // 可以在这里初始化消息轮询
  }

  /// 清理资源
  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }
}
