import 'package:flutter/material.dart';

import 'logic/message_provider.dart';
import 'ui/message_main_screen.dart';
import 'ui/message_list_screen.dart';
import 'ui/message_detail_screen.dart';
import 'ui/service_subscription_screen.dart';

/// 消息功能模块导出文件
///
/// 本模块提供完整的消息管理功能，包括：
/// 1. 消息列表查看（收到的消息、发出的消息、系统消息、收藏消息）
/// 2. 消息详情查看（支持语音消息波形显示和导出）
/// 3. 服务号订阅管理（推送时间设置、启用/禁用）
/// 4. 消息收藏、删除等操作

// 导出逻辑层
export 'logic/message_provider.dart';
export 'logic/message_controller.dart';

// 导出UI层
export 'ui/message_main_screen.dart';
export 'ui/message_list_screen.dart';
export 'ui/message_detail_screen.dart';
export 'ui/service_subscription_screen.dart';

// 导出类型定义
export 'logic/message_provider.dart' show MessageFilter, MessageStatus;

/// 消息功能路由配置
class MessageRoutes {
  static const String main = '/messages';
  static const String list = '/messages/list';
  static const String detail = '/messages/detail';
  static const String subscriptions = '/messages/subscriptions';

  /// 获取消息功能的路由配置
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      main: (context) => const MessageMainScreen(),
      list: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final filter = args is MessageFilter ? args : MessageFilter.received;
        return MessageListScreen(initialFilter: filter);
      },
      detail: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final messageId = args is int ? args : 0;
        return MessageDetailScreen(messageId: messageId);
      },
      subscriptions: (context) => const ServiceSubscriptionScreen(),
    };
  }
}

/// 消息功能初始化
///
/// 在应用启动时调用，初始化消息相关的Provider和监听器
class MessageFeature {
  /// 初始化消息功能
  static void initialize() {
    // 初始化消息轮询服务
    // 初始化消息缓存
    // 注册消息通知处理
  }

  /// 清理消息功能资源
  static void dispose() {
    // 停止消息轮询
    // 清理缓存
  }
}
