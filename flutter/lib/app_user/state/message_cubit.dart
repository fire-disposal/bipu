/// 消息中心状态管理Cubit
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/core.dart';
import 'user_data_cubit.dart';

/// 消息中心状态
abstract class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class MessageInitial extends MessageState {
  const MessageInitial();
}

/// 加载中状态
class MessageLoading extends MessageState {
  const MessageLoading();
}

/// 数据加载完成
class MessageLoaded extends MessageState {
  final List<MessageCategory> categories;
  final List<MessageInfo> receivedMessages;
  final List<MessageInfo> sentMessages;
  final List<MessageInfo> subscriptionMessages;
  final MessageFilter? currentFilter;

  const MessageLoaded({
    required this.categories,
    required this.receivedMessages,
    required this.sentMessages,
    required this.subscriptionMessages,
    this.currentFilter,
  });

  @override
  List<Object?> get props => [
    categories,
    receivedMessages,
    sentMessages,
    subscriptionMessages,
    currentFilter,
  ];
}

/// 错误状态
class MessageError extends MessageState {
  final String message;

  const MessageError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 消息分类数据模型
class MessageCategory {
  final String id;
  final IconData icon;
  final String title;
  final bool isOnline;
  final int unreadCount;
  final MessageType type;

  const MessageCategory({
    required this.id,
    required this.icon,
    required this.title,
    this.isOnline = false,
    this.unreadCount = 0,
    required this.type,
  });
}

/// 消息信息数据模型
class MessageInfo {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool isFavorite;
  final String? sender;
  final String? recipient;
  final MessageType type;
  final MessageStatus status;

  const MessageInfo({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.isFavorite = false,
    this.sender,
    this.recipient,
    required this.type,
    this.status = MessageStatus.received,
  });
}

/// 消息类型
enum MessageType { received, sent, subscription, system }

/// 消息状态
enum MessageStatus { received, read, sent, delivered, failed }

/// 消息过滤器
class MessageFilter {
  final MessageType? type;
  final bool? isRead;
  final bool? isFavorite;
  final DateTime? startDate;
  final DateTime? endDate;

  const MessageFilter({
    this.type,
    this.isRead,
    this.isFavorite,
    this.startDate,
    this.endDate,
  });
}

/// 消息中心Cubit
class MessageCubit extends Cubit<MessageState> {
  final UserDataCubit _userDataCubit;

  MessageCubit({required UserDataCubit userDataCubit})
    : _userDataCubit = userDataCubit,
      super(const MessageInitial()) {
    _initialize();
  }

  /// 初始化消息中心
  Future<void> _initialize() async {
    emit(const MessageLoading());

    try {
      // 等待用户数据加载完成
      await _userDataCubit.loadUserData();

      // 获取消息分类
      final categories = _getMessageCategories();

      // 获取各类消息
      final receivedMessages = _getReceivedMessages();
      final sentMessages = _getSentMessages();
      final subscriptionMessages = _getSubscriptionMessages();

      emit(
        MessageLoaded(
          categories: categories,
          receivedMessages: receivedMessages,
          sentMessages: sentMessages,
          subscriptionMessages: subscriptionMessages,
        ),
      );
    } catch (e) {
      Logger.error('消息中心初始化失败: $e');
      emit(MessageError('加载消息失败: $e'));
    }
  }

  /// 获取消息分类
  List<MessageCategory> _getMessageCategories() {
    return [
      MessageCategory(
        id: 'received',
        icon: Icons.mark_email_unread_outlined,
        title: '收到的消息',
        isOnline: true,
        unreadCount: 3,
        type: MessageType.received,
      ),
      MessageCategory(
        id: 'sent',
        icon: Icons.send_outlined,
        title: '发出的消息',
        isOnline: false,
        unreadCount: 0,
        type: MessageType.sent,
      ),
      MessageCategory(
        id: 'subscription',
        icon: Icons.subscriptions_outlined,
        title: '订阅消息',
        isOnline: false,
        unreadCount: 1,
        type: MessageType.subscription,
      ),
      MessageCategory(
        id: 'management',
        icon: Icons.settings_outlined,
        title: '消息管理',
        isOnline: false,
        unreadCount: 0,
        type: MessageType.system,
      ),
    ];
  }

  /// 获取收到的消息
  List<MessageInfo> _getReceivedMessages() {
    final now = DateTime.now();
    return [
      MessageInfo(
        id: 'recv_1',
        title: '设备连接成功',
        content: '您的设备已成功连接，可以开始使用了',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isRead: true,
        sender: '系统',
        type: MessageType.received,
        status: MessageStatus.read,
      ),
      MessageInfo(
        id: 'recv_2',
        title: '新消息提醒',
        content: '您有一条新的消息，请查收',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
        sender: '好友',
        type: MessageType.received,
        status: MessageStatus.received,
      ),
      MessageInfo(
        id: 'recv_3',
        title: '设备状态更新',
        content: '设备电量低，请及时充电',
        timestamp: now.subtract(const Duration(hours: 1)),
        isRead: false,
        sender: '系统',
        type: MessageType.received,
        status: MessageStatus.received,
      ),
    ];
  }

  /// 获取发出的消息
  List<MessageInfo> _getSentMessages() {
    final now = DateTime.now();
    return [
      MessageInfo(
        id: 'sent_1',
        title: '问候消息',
        content: '你好，今天过得怎么样？',
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: true,
        recipient: '好友',
        type: MessageType.sent,
        status: MessageStatus.delivered,
      ),
      MessageInfo(
        id: 'sent_2',
        title: '测试消息',
        content: '这是一条测试消息',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
        recipient: '设备',
        type: MessageType.sent,
        status: MessageStatus.delivered,
      ),
    ];
  }

  /// 获取订阅消息
  List<MessageInfo> _getSubscriptionMessages() {
    final now = DateTime.now();
    return [
      MessageInfo(
        id: 'sub_1',
        title: '新功能发布',
        content: '我们发布了新功能，快来体验吧',
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: false,
        sender: 'BiPuPu团队',
        type: MessageType.subscription,
        status: MessageStatus.received,
      ),
    ];
  }

  /// 刷新消息
  Future<void> refreshMessages() async {
    if (state is! MessageLoaded) return;

    emit(const MessageLoading());

    try {
      // 重新加载用户数据
      await _userDataCubit.loadUserData();

      // 重新获取消息
      final currentState = state as MessageLoaded;
      final receivedMessages = _getReceivedMessages();
      final sentMessages = _getSentMessages();
      final subscriptionMessages = _getSubscriptionMessages();

      emit(
        MessageLoaded(
          categories: currentState.categories,
          receivedMessages: receivedMessages,
          sentMessages: sentMessages,
          subscriptionMessages: subscriptionMessages,
          currentFilter: currentState.currentFilter,
        ),
      );
    } catch (e) {
      Logger.error('刷新消息失败: $e');
      emit(MessageError('刷新消息失败: $e'));
    }
  }

  /// 标记消息为已读
  void markMessageAsRead(String messageId) {
    if (state is! MessageLoaded) return;

    final currentState = state as MessageLoaded;

    // 更新收到的消息
    final updatedReceivedMessages = currentState.receivedMessages.map((
      message,
    ) {
      if (message.id == messageId) {
        return MessageInfo(
          id: message.id,
          title: message.title,
          content: message.content,
          timestamp: message.timestamp,
          isRead: true,
          isFavorite: message.isFavorite,
          sender: message.sender,
          recipient: message.recipient,
          type: message.type,
          status: MessageStatus.read,
        );
      }
      return message;
    }).toList();

    emit(
      MessageLoaded(
        categories: currentState.categories,
        receivedMessages: updatedReceivedMessages,
        sentMessages: currentState.sentMessages,
        subscriptionMessages: currentState.subscriptionMessages,
        currentFilter: currentState.currentFilter,
      ),
    );
  }

  /// 切换消息收藏状态
  void toggleMessageFavorite(String messageId) {
    if (state is! MessageLoaded) return;

    final currentState = state as MessageLoaded;

    // 更新所有消息列表
    final updateFavorite = (List<MessageInfo> messages) {
      return messages.map((message) {
        if (message.id == messageId) {
          return MessageInfo(
            id: message.id,
            title: message.title,
            content: message.content,
            timestamp: message.timestamp,
            isRead: message.isRead,
            isFavorite: !message.isFavorite,
            sender: message.sender,
            recipient: message.recipient,
            type: message.type,
            status: message.status,
          );
        }
        return message;
      }).toList();
    };

    emit(
      MessageLoaded(
        categories: currentState.categories,
        receivedMessages: updateFavorite(currentState.receivedMessages),
        sentMessages: updateFavorite(currentState.sentMessages),
        subscriptionMessages: updateFavorite(currentState.subscriptionMessages),
        currentFilter: currentState.currentFilter,
      ),
    );
  }

  /// 删除消息
  void deleteMessage(String messageId) {
    if (state is! MessageLoaded) return;

    final currentState = state as MessageLoaded;

    // 从所有列表中删除消息
    final deleteFromList = (List<MessageInfo> messages) {
      return messages.where((message) => message.id != messageId).toList();
    };

    emit(
      MessageLoaded(
        categories: currentState.categories,
        receivedMessages: deleteFromList(currentState.receivedMessages),
        sentMessages: deleteFromList(currentState.sentMessages),
        subscriptionMessages: deleteFromList(currentState.subscriptionMessages),
        currentFilter: currentState.currentFilter,
      ),
    );
  }

  /// 应用消息过滤器
  void applyFilter(MessageFilter filter) {
    if (state is! MessageLoaded) return;

    final currentState = state as MessageLoaded;
    emit(
      MessageLoaded(
        categories: currentState.categories,
        receivedMessages: currentState.receivedMessages,
        sentMessages: currentState.sentMessages,
        subscriptionMessages: currentState.subscriptionMessages,
        currentFilter: filter,
      ),
    );
  }

  /// 清除过滤器
  void clearFilter() {
    if (state is! MessageLoaded) return;

    final currentState = state as MessageLoaded;
    emit(
      MessageLoaded(
        categories: currentState.categories,
        receivedMessages: currentState.receivedMessages,
        sentMessages: currentState.sentMessages,
        subscriptionMessages: currentState.subscriptionMessages,
        currentFilter: null,
      ),
    );
  }

  /// 获取未读消息数量
  int getUnreadCount() {
    if (state is! MessageLoaded) return 0;

    final currentState = state as MessageLoaded;
    return currentState.receivedMessages.where((msg) => !msg.isRead).length;
  }

  /// 获取收藏消息数量
  int getFavoriteCount() {
    if (state is! MessageLoaded) return 0;

    final currentState = state as MessageLoaded;
    final allMessages = [
      ...currentState.receivedMessages,
      ...currentState.sentMessages,
      ...currentState.subscriptionMessages,
    ];
    return allMessages.where((msg) => msg.isFavorite).length;
  }
}
