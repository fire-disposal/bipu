import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/models/service_account_model.dart';
import './message_provider.dart';

/// 消息控制器
///
/// 封装消息相关的交互逻辑：
/// - 加载消息列表
/// - 收藏/取消收藏消息
/// - 删除消息
/// - 查看消息详情
class MessageController {
  final Ref ref;
  final MessageFilter filter;

  MessageController({required this.ref, required this.filter});

  /// 获取消息列表 Notifier
  Notifier<MessageListState> get _messageListNotifier =>
      ref.read(getMessageListProvider(filter).notifier);

  /// 加载消息列表
  Future<void> loadMessages({bool refresh = false}) async {
    try {
      final notifier = _messageListNotifier;
      if (notifier is ReceivedMessagesNotifier) {
        await notifier.loadMessages(refresh: refresh);
      } else if (notifier is SentMessagesNotifier) {
        await notifier.loadMessages(refresh: refresh);
      } else if (notifier is SystemMessagesNotifier) {
        await notifier.loadMessages(refresh: refresh);
      } else if (notifier is FavoriteMessagesNotifier) {
        await notifier.loadMessages(refresh: refresh);
      }
    } catch (e) {
      debugPrint('[MessageController] 加载消息失败：$e');
      rethrow;
    }
  }

  /// 加载更多消息
  Future<void> loadMore() async {
    try {
      final notifier = _messageListNotifier;
      if (notifier is ReceivedMessagesNotifier) {
        await notifier.loadMore();
      } else if (notifier is SentMessagesNotifier) {
        await notifier.loadMore();
      } else if (notifier is SystemMessagesNotifier) {
        await notifier.loadMore();
      } else if (notifier is FavoriteMessagesNotifier) {
        await notifier.loadMore();
      }
    } catch (e) {
      debugPrint('[MessageController] 加载更多消息失败：$e');
      rethrow;
    }
  }

  /// 刷新消息列表
  Future<void> refresh() async {
    try {
      final notifier = _messageListNotifier;
      if (notifier is ReceivedMessagesNotifier) {
        await notifier.refresh();
      } else if (notifier is SentMessagesNotifier) {
        await notifier.refresh();
      } else if (notifier is SystemMessagesNotifier) {
        await notifier.refresh();
      } else if (notifier is FavoriteMessagesNotifier) {
        await notifier.refresh();
      }
    } catch (e) {
      debugPrint('[MessageController] 刷新消息失败：$e');
      rethrow;
    }
  }

  /// 收藏消息
  Future<bool> addFavorite(int messageId, {String? note}) async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.addFavorite(
        messageId,
        note != null ? {'note': note} : null,
      );
      return true;
    } catch (e) {
      debugPrint('[MessageController] 收藏消息失败：$e');
      return false;
    }
  }

  /// 取消收藏
  Future<bool> removeFavorite(int messageId) async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.removeFavorite(messageId);
      return true;
    } catch (e) {
      debugPrint('[MessageController] 取消收藏失败：$e');
      return false;
    }
  }

  /// 删除消息
  Future<bool> deleteMessage(int messageId) async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.deleteMessage(messageId);
      return true;
    } catch (e) {
      debugPrint('[MessageController] 删除消息失败：$e');
      return false;
    }
  }

  /// 获取消息详情
  Future<MessageResponse?> getMessageDetail(int messageId) async {
    try {
      return await ref.read(messageDetailProvider(messageId).future);
    } catch (e) {
      debugPrint('[MessageController] 获取消息详情失败：$e');
      return null;
    }
  }

  /// 判断消息是否为系统消息
  static bool isSystemMessage(MessageResponse message) {
    return message.messageType == 'SYSTEM';
  }

  /// 判断消息是否为语音消息
  static bool isVoiceMessage(MessageResponse message) {
    return message.messageType == 'VOICE' || message.waveform != null;
  }

  /// 获取消息显示标题
  static String getMessageTitle(MessageResponse message, String currentUserId) {
    if (message.senderBipupuId == currentUserId) {
      return '发送给 ${message.receiverBipupuId}';
    } else {
      return '来自 ${message.senderBipupuId}';
    }
  }

  /// 格式化消息时间
  static String formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '今天 ${_formatTime(time)}';
    } else if (messageDate == yesterday) {
      return '昨天 ${_formatTime(time)}';
    } else {
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${_formatTime(time)}';
    }
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 消息控制器提供者
final messageControllerProvider =
    Provider.family<MessageController, MessageFilter>(
      (ref, filter) => MessageController(ref: ref, filter: filter),
    );

/// 服务号订阅控制器
class ServiceSubscriptionController {
  final Ref ref;

  ServiceSubscriptionController({required this.ref});

  /// 获取服务号订阅 Notifier
  ServiceSubscriptionNotifier get _subscriptionNotifier =>
      ref.read(serviceSubscriptionProvider.notifier);

  /// 加载服务号订阅列表
  Future<void> loadSubscriptions() async {
    try {
      await _subscriptionNotifier.loadSubscriptions();
    } catch (e) {
      debugPrint('[ServiceSubscriptionController] 加载订阅失败：$e');
      rethrow;
    }
  }

  /// 获取所有可用服务号
  Future<List<ServiceAccountResponse>> getAvailableServices() async {
    try {
      return await _subscriptionNotifier.getAvailableServices();
    } catch (e) {
      debugPrint('[ServiceSubscriptionController] 获取服务号列表失败：$e');
      return [];
    }
  }

  /// 更新订阅设置
  Future<bool> updateSubscription(
    String serviceName, {
    String? pushTime,
    bool? isEnabled,
  }) async {
    try {
      return await _subscriptionNotifier.updateSubscription(
        serviceName,
        pushTime: pushTime,
        isEnabled: isEnabled,
      );
    } catch (e) {
      debugPrint('[ServiceSubscriptionController] 更新订阅设置失败：$e');
      return false;
    }
  }

  /// 订阅服务号
  Future<bool> subscribeService(String serviceName, {String? pushTime}) async {
    try {
      return await _subscriptionNotifier.subscribeService(
        serviceName,
        pushTime: pushTime,
      );
    } catch (e) {
      debugPrint('[ServiceSubscriptionController] 订阅服务号失败：$e');
      return false;
    }
  }

  /// 取消订阅服务号
  Future<bool> unsubscribeService(String serviceName) async {
    try {
      return await _subscriptionNotifier.unsubscribeService(serviceName);
    } catch (e) {
      debugPrint('[ServiceSubscriptionController] 取消订阅失败：$e');
      return false;
    }
  }

  /// 启用订阅
  Future<bool> enableSubscription(String serviceName) async {
    return await updateSubscription(serviceName, isEnabled: true);
  }

  /// 禁用订阅
  Future<bool> disableSubscription(String serviceName) async {
    return await updateSubscription(serviceName, isEnabled: false);
  }

  /// 设置推送时间
  Future<bool> setPushTime(String serviceName, String pushTime) async {
    return await updateSubscription(serviceName, pushTime: pushTime);
  }

  /// 清除推送时间设置
  Future<bool> clearPushTime(String serviceName) async {
    return await updateSubscription(serviceName, pushTime: '');
  }
}

/// 服务号订阅控制器提供者
final serviceSubscriptionControllerProvider =
    Provider<ServiceSubscriptionController>(
      (ref) => ServiceSubscriptionController(ref: ref),
    );
