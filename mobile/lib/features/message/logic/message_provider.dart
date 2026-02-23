import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/models/service_account_model.dart';

/// 消息类型筛选
enum MessageFilter {
  /// 收到的消息（非系统消息）
  received,

  /// 发出的消息
  sent,

  /// 系统消息/订阅消息
  system,

  /// 收藏的消息
  favorites,
}

/// 消息状态
enum MessageStatus {
  /// 初始状态
  initial,

  /// 加载中
  loading,

  /// 已加载
  loaded,

  /// 错误
  error,

  /// 加载更多中
  loadingMore,
}

/// 消息列表状态
class MessageListState {
  final MessageStatus status;
  final List<MessageResponse> messages;
  final int page;
  final int total;
  final bool hasMore;
  final String? error;

  const MessageListState({
    required this.status,
    required this.messages,
    required this.page,
    required this.total,
    required this.hasMore,
    this.error,
  });

  MessageListState copyWith({
    MessageStatus? status,
    List<MessageResponse>? messages,
    int? page,
    int? total,
    bool? hasMore,
    String? error,
  }) {
    return MessageListState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }

  factory MessageListState.initial() {
    return MessageListState(
      status: MessageStatus.initial,
      messages: [],
      page: 1,
      total: 0,
      hasMore: true,
    );
  }
}

/// 收到的消息列表提供者
final receivedMessagesProvider =
    NotifierProvider<ReceivedMessagesNotifier, MessageListState>(
      ReceivedMessagesNotifier.new,
    );

class ReceivedMessagesNotifier extends Notifier<MessageListState> {
  @override
  MessageListState build() {
    return MessageListState.initial();
  }

  /// 加载收到的消息
  Future<void> loadMessages({bool refresh = false}) async {
    try {
      if (refresh) {
        state = state.copyWith(
          status: MessageStatus.loading,
          page: 1,
          messages: [],
          error: null,
        );
      } else {
        state = state.copyWith(status: MessageStatus.loading, error: null);
      }

      final restClient = ref.read(restClientProvider);
      final page = refresh ? 1 : state.page;
      final pageSize = 20;

      final response = await restClient.getMessages(
        direction: 'received',
        page: page,
        pageSize: pageSize,
      );

      final messageList = MessageListResponse.fromJson(response.data);

      state = state.copyWith(
        status: MessageStatus.loaded,
        messages: refresh
            ? messageList.messages
            : [...state.messages, ...messageList.messages],
        page: page + 1,
        total: messageList.total,
        hasMore: messageList.messages.length == pageSize,
      );
    } catch (e) {
      debugPrint('[ReceivedMessagesNotifier] 加载消息失败：$e');
      state = state.copyWith(status: MessageStatus.error, error: e.toString());
    }
  }

  /// 加载更多消息
  Future<void> loadMore() async {
    if (state.status == MessageStatus.loadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(status: MessageStatus.loadingMore);
    await loadMessages(refresh: false);
  }

  /// 刷新消息
  Future<void> refresh() async {
    await loadMessages(refresh: true);
  }
}

/// 发出的消息列表提供者
final sentMessagesProvider =
    NotifierProvider<SentMessagesNotifier, MessageListState>(
      SentMessagesNotifier.new,
    );

class SentMessagesNotifier extends Notifier<MessageListState> {
  @override
  MessageListState build() {
    return MessageListState.initial();
  }

  /// 加载发出的消息
  Future<void> loadMessages({bool refresh = false}) async {
    try {
      if (refresh) {
        state = state.copyWith(
          status: MessageStatus.loading,
          page: 1,
          messages: [],
          error: null,
        );
      } else {
        state = state.copyWith(status: MessageStatus.loading, error: null);
      }

      final restClient = ref.read(restClientProvider);
      final page = refresh ? 1 : state.page;
      final pageSize = 20;

      final response = await restClient.getMessages(
        direction: 'sent',
        page: page,
        pageSize: pageSize,
      );

      final messageList = MessageListResponse.fromJson(response.data);

      state = state.copyWith(
        status: MessageStatus.loaded,
        messages: refresh
            ? messageList.messages
            : [...state.messages, ...messageList.messages],
        page: page + 1,
        total: messageList.total,
        hasMore: messageList.messages.length == pageSize,
      );
    } catch (e) {
      debugPrint('[SentMessagesNotifier] 加载消息失败：$e');
      state = state.copyWith(status: MessageStatus.error, error: e.toString());
    }
  }

  /// 加载更多消息
  Future<void> loadMore() async {
    if (state.status == MessageStatus.loadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(status: MessageStatus.loadingMore);
    await loadMessages(refresh: false);
  }

  /// 刷新消息
  Future<void> refresh() async {
    await loadMessages(refresh: true);
  }
}

/// 系统消息列表提供者
final systemMessagesProvider =
    NotifierProvider<SystemMessagesNotifier, MessageListState>(
      SystemMessagesNotifier.new,
    );

class SystemMessagesNotifier extends Notifier<MessageListState> {
  @override
  MessageListState build() {
    return MessageListState.initial();
  }

  /// 加载系统消息
  Future<void> loadMessages({bool refresh = false}) async {
    try {
      if (refresh) {
        state = state.copyWith(
          status: MessageStatus.loading,
          page: 1,
          messages: [],
          error: null,
        );
      } else {
        state = state.copyWith(status: MessageStatus.loading, error: null);
      }

      final restClient = ref.read(restClientProvider);
      final page = refresh ? 1 : state.page;
      final pageSize = 20;

      // 先获取所有收到的消息，然后筛选系统消息
      final response = await restClient.getMessages(
        direction: 'received',
        page: page,
        pageSize: pageSize,
      );

      final messageList = MessageListResponse.fromJson(response.data);
      final systemMessages = messageList.messages
          .where((msg) => msg.messageType == 'SYSTEM')
          .toList();

      state = state.copyWith(
        status: MessageStatus.loaded,
        messages: refresh
            ? systemMessages
            : [...state.messages, ...systemMessages],
        page: page + 1,
        total: systemMessages.length,
        hasMore: messageList.messages.length == pageSize,
      );
    } catch (e) {
      debugPrint('[SystemMessagesNotifier] 加载消息失败：$e');
      state = state.copyWith(status: MessageStatus.error, error: e.toString());
    }
  }

  /// 加载更多消息
  Future<void> loadMore() async {
    if (state.status == MessageStatus.loadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(status: MessageStatus.loadingMore);
    await loadMessages(refresh: false);
  }

  /// 刷新消息
  Future<void> refresh() async {
    await loadMessages(refresh: true);
  }
}

/// 收藏消息列表提供者
final favoriteMessagesProvider =
    NotifierProvider<FavoriteMessagesNotifier, MessageListState>(
      FavoriteMessagesNotifier.new,
    );

class FavoriteMessagesNotifier extends Notifier<MessageListState> {
  @override
  MessageListState build() {
    return MessageListState.initial();
  }

  /// 加载收藏消息
  Future<void> loadMessages({bool refresh = false}) async {
    try {
      if (refresh) {
        state = state.copyWith(
          status: MessageStatus.loading,
          page: 1,
          messages: [],
          error: null,
        );
      } else {
        state = state.copyWith(status: MessageStatus.loading, error: null);
      }

      final restClient = ref.read(restClientProvider);
      final page = refresh ? 1 : state.page;
      final pageSize = 20;

      final response = await restClient.getFavorites(
        page: page,
        pageSize: pageSize,
      );

      final favoriteList = FavoriteListResponse.fromJson(response.data);

      // 需要获取消息详情来填充完整信息
      final messages = <MessageResponse>[];
      for (final favorite in favoriteList.favorites) {
        // TODO: 需要实现获取消息详情的API
        // 暂时创建占位消息
        final message = MessageResponse(
          id: favorite.messageId,
          senderBipupuId: '', // 需要从消息详情获取
          receiverBipupuId: '',
          content: '收藏的消息',
          messageType: '',
          createdAt: favorite.createdAt,
        );
        messages.add(message);
      }

      state = state.copyWith(
        status: MessageStatus.loaded,
        messages: refresh ? messages : [...state.messages, ...messages],
        page: page + 1,
        total: favoriteList.total,
        hasMore: favoriteList.favorites.length == pageSize,
      );
    } catch (e) {
      debugPrint('[FavoriteMessagesNotifier] 加载消息失败：$e');
      state = state.copyWith(status: MessageStatus.error, error: e.toString());
    }
  }

  /// 加载更多消息
  Future<void> loadMore() async {
    if (state.status == MessageStatus.loadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(status: MessageStatus.loadingMore);
    await loadMessages(refresh: false);
  }

  /// 刷新消息
  Future<void> refresh() async {
    await loadMessages(refresh: true);
  }
}

/// 消息详情提供者
final messageDetailProvider = FutureProvider.family<MessageResponse?, int>((
  ref,
  messageId,
) async {
  try {
    final restClient = ref.read(restClientProvider);

    // 尝试从所有消息类型中查找
    final receivedResponse = await restClient.getMessages(
      direction: 'received',
      page: 1,
      pageSize: 100,
    );
    final receivedList = MessageListResponse.fromJson(receivedResponse.data);
    for (final msg in receivedList.messages) {
      if (msg.id == messageId) {
        return msg;
      }
    }

    final sentResponse = await restClient.getMessages(
      direction: 'sent',
      page: 1,
      pageSize: 100,
    );
    final sentList = MessageListResponse.fromJson(sentResponse.data);
    for (final msg in sentList.messages) {
      if (msg.id == messageId) {
        return msg;
      }
    }

    return null;
  } catch (e) {
    debugPrint('[messageDetailProvider] 获取消息详情失败：$e');
    return null;
  }
});

/// 服务号订阅状态
class ServiceSubscriptionState {
  final bool isLoading;
  final List<UserSubscriptionResponse> subscriptions;
  final String? error;

  const ServiceSubscriptionState({
    required this.isLoading,
    required this.subscriptions,
    this.error,
  });

  factory ServiceSubscriptionState.initial() {
    return ServiceSubscriptionState(isLoading: false, subscriptions: []);
  }
}

/// 服务号订阅提供者
final serviceSubscriptionProvider =
    NotifierProvider<ServiceSubscriptionNotifier, ServiceSubscriptionState>(
      ServiceSubscriptionNotifier.new,
    );

class ServiceSubscriptionNotifier extends Notifier<ServiceSubscriptionState> {
  @override
  ServiceSubscriptionState build() {
    return ServiceSubscriptionState.initial();
  }

  /// 加载服务号订阅列表
  Future<void> loadSubscriptions() async {
    try {
      state = ServiceSubscriptionState(
        isLoading: true,
        subscriptions: state.subscriptions,
      );

      final restClient = ref.read(restClientProvider);
      final response = await restClient.getUserSubscriptions();
      final subscriptionList = UserSubscriptionList.fromJson(response.data);

      state = ServiceSubscriptionState(
        isLoading: false,
        subscriptions: subscriptionList.subscriptions,
      );
    } catch (e) {
      debugPrint('[ServiceSubscriptionNotifier] 加载订阅失败：$e');
      state = ServiceSubscriptionState(
        isLoading: false,
        subscriptions: state.subscriptions,
        error: e.toString(),
      );
    }
  }

  /// 更新订阅设置
  Future<bool> updateSubscription(
    String serviceName, {
    String? pushTime,
    bool? isEnabled,
  }) async {
    try {
      final restClient = ref.read(restClientProvider);

      final updateData = <String, dynamic>{};
      if (pushTime != null) {
        updateData['push_time'] = pushTime;
      }
      if (isEnabled != null) {
        updateData['is_enabled'] = isEnabled;
      }

      await restClient.updateSubscriptionSettings(serviceName, updateData);

      // 重新加载订阅列表以获取更新后的数据
      await loadSubscriptions();
      return true;
    } catch (e) {
      debugPrint('[ServiceSubscriptionNotifier] 更新订阅设置失败：$e');
      return false;
    }
  }

  /// 订阅服务号
  Future<bool> subscribeService(String serviceName, {String? pushTime}) async {
    try {
      final restClient = ref.read(restClientProvider);

      final subscribeData = <String, dynamic>{};
      if (pushTime != null) {
        subscribeData['push_time'] = pushTime;
      }

      await restClient.subscribeServiceAccount(
        serviceName,
        subscribeData.isNotEmpty ? subscribeData : null,
      );

      // 重新加载订阅列表
      await loadSubscriptions();
      return true;
    } catch (e) {
      debugPrint('[ServiceSubscriptionNotifier] 订阅服务号失败：$e');
      return false;
    }
  }

  /// 取消订阅服务号
  Future<bool> unsubscribeService(String serviceName) async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.unsubscribeServiceAccount(serviceName);

      // 重新加载订阅列表
      await loadSubscriptions();
      return true;
    } catch (e) {
      debugPrint('[ServiceSubscriptionNotifier] 取消订阅失败：$e');
      return false;
    }
  }

  /// 获取所有可用服务号
  Future<List<ServiceAccountResponse>> getAvailableServices() async {
    try {
      final restClient = ref.read(restClientProvider);
      final response = await restClient.getServiceAccounts(limit: 100);
      final serviceList = ServiceAccountList.fromJson(response.data);
      return serviceList.items;
    } catch (e) {
      debugPrint('[ServiceSubscriptionNotifier] 获取服务号列表失败：$e');
      return [];
    }
  }
}

/// 消息轮询服务
final messagePollingProvider = StreamProvider<List<MessageResponse>>((ref) {
  final streamController = StreamController<List<MessageResponse>>.broadcast();
  Timer? pollTimer;
  int lastMsgId = 0;

  Future<void> pollMessages() async {
    try {
      final restClient = ref.read(restClientProvider);
      final response = await restClient.pollMessages(
        lastMsgId: lastMsgId,
        timeout: 30,
      );

      final newMessages = (response.data as List)
          .map((json) => MessageResponse.fromJson(json))
          .toList();

      if (newMessages.isNotEmpty) {
        lastMsgId = newMessages.last.id;
        streamController.add(newMessages);
      }
    } catch (e) {
      debugPrint('[messagePollingProvider] 轮询失败：$e');
    }
  }

  void startPolling() {
    pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      pollMessages();
    });
  }

  void stopPolling() {
    pollTimer?.cancel();
    pollTimer = null;
  }

  // 开始轮询
  startPolling();

  // 清理函数
  ref.onDispose(() {
    stopPolling();
    streamController.close();
  });

  return streamController.stream;
});

/// 服务号列表状态
class ServiceAccountListState {
  final bool isLoading;
  final List<ServiceAccountResponse> accounts;
  final String? error;

  const ServiceAccountListState({
    required this.isLoading,
    required this.accounts,
    this.error,
  });

  factory ServiceAccountListState.initial() {
    return ServiceAccountListState(isLoading: false, accounts: []);
  }
}

/// 服务号列表提供者
final serviceAccountsProvider =
    NotifierProvider<ServiceAccountsNotifier, ServiceAccountListState>(
      ServiceAccountsNotifier.new,
    );

class ServiceAccountsNotifier extends Notifier<ServiceAccountListState> {
  @override
  ServiceAccountListState build() {
    return ServiceAccountListState.initial();
  }

  /// 加载服务号列表
  Future<void> loadServiceAccounts() async {
    try {
      state = ServiceAccountListState(
        isLoading: true,
        accounts: state.accounts,
      );

      final restClient = ref.read(restClientProvider);
      final response = await restClient.getServiceAccounts(limit: 100);
      final serviceList = ServiceAccountList.fromJson(response.data);

      state = ServiceAccountListState(
        isLoading: false,
        accounts: serviceList.items,
      );
    } catch (e) {
      debugPrint('[ServiceAccountsNotifier] 加载服务号列表失败：$e');
      state = ServiceAccountListState(
        isLoading: false,
        accounts: state.accounts,
        error: e.toString(),
      );
    }
  }
}

/// 根据MessageFilter获取对应的provider
NotifierProvider<Notifier<MessageListState>, MessageListState>
getMessageListProvider(MessageFilter filter) {
  switch (filter) {
    case MessageFilter.received:
      return receivedMessagesProvider;
    case MessageFilter.sent:
      return sentMessagesProvider;
    case MessageFilter.system:
      return systemMessagesProvider;
    case MessageFilter.favorites:
      return favoriteMessagesProvider;
  }
}
