/// 首页状态管理Cubit
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/core.dart';
import 'device_control_state.dart';
import 'user_data_cubit.dart';

/// 首页状态
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// 加载中状态
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// 数据加载完成
class HomeLoaded extends HomeState {
  final List<QuickAction> quickActions;
  final List<MessageInfo> recentMessages;
  final bool isDeviceConnected;
  final String? connectedDeviceName;

  const HomeLoaded({
    required this.quickActions,
    required this.recentMessages,
    this.isDeviceConnected = false,
    this.connectedDeviceName,
  });

  @override
  List<Object?> get props => [
    quickActions,
    recentMessages,
    isDeviceConnected,
    connectedDeviceName,
  ];
}

/// 错误状态
class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 快速操作数据模型
class QuickAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const QuickAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

/// 消息信息数据模型
class MessageInfo {
  final String id;
  final String title;
  final String content;
  final String time;
  final bool isRead;

  const MessageInfo({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    this.isRead = false,
  });
}

/// 首页Cubit
class HomeCubit extends Cubit<HomeState> {
  final DeviceControlCubit _deviceControlCubit;
  final UserDataCubit _userDataCubit;

  HomeCubit({
    required DeviceControlCubit deviceControlCubit,
    required UserDataCubit userDataCubit,
  }) : _deviceControlCubit = deviceControlCubit,
       _userDataCubit = userDataCubit,
       super(const HomeInitial()) {
    _initialize();
  }

  /// 初始化首页数据
  Future<void> _initialize() async {
    emit(const HomeLoading());

    try {
      // 等待用户数据加载完成
      await _userDataCubit.loadUserData();

      // 获取设备连接状态
      final isConnected = _deviceControlCubit.isConnected;
      final deviceName = _deviceControlCubit.connectedDeviceName;

      // 获取最近消息
      final recentMessages = _getRecentMessages();

      // 获取快速操作
      final quickActions = _getQuickActions();

      emit(
        HomeLoaded(
          quickActions: quickActions,
          recentMessages: recentMessages,
          isDeviceConnected: isConnected,
          connectedDeviceName: deviceName,
        ),
      );
    } catch (e) {
      Logger.error('首页初始化失败: $e');
      emit(HomeError('加载数据失败: $e'));
    }
  }

  /// 获取快速操作列表
  List<QuickAction> _getQuickActions() {
    return [
      QuickAction(
        id: 'send_message',
        title: '发送消息',
        subtitle: '向设备发送通知',
        icon: Icons.message,
        color: Colors.blue,
      ),
      QuickAction(
        id: 'test_vibration',
        title: '震动测试',
        subtitle: '测试设备震动',
        icon: Icons.vibration,
        color: Colors.orange,
      ),
      QuickAction(
        id: 'test_led',
        title: 'LED测试',
        subtitle: '测试设备LED',
        icon: Icons.lightbulb,
        color: Colors.yellow,
      ),
      QuickAction(
        id: 'emergency',
        title: '紧急呼叫',
        subtitle: '发送紧急通知',
        icon: Icons.emergency,
        color: Colors.red,
      ),
    ];
  }

  /// 获取最近消息列表
  List<MessageInfo> _getRecentMessages() {
    return [
      MessageInfo(
        id: '1',
        title: '设备连接成功',
        content: '您的设备已成功连接，可以开始使用了',
        time: '刚刚',
        isRead: true,
      ),
      MessageInfo(
        id: '2',
        title: '欢迎使用BiPuPu',
        content: '欢迎使用BiPuPu寻呼机，开始您的智能体验',
        time: '5分钟前',
        isRead: true,
      ),
      MessageInfo(
        id: '3',
        title: '新功能更新',
        content: '我们添加了新的LED效果，快来试试吧',
        time: '1小时前',
        isRead: false,
      ),
    ];
  }

  /// 刷新数据
  Future<void> refreshData() async {
    if (state is! HomeLoaded) return;

    emit(const HomeLoading());

    try {
      // 重新加载用户数据
      await _userDataCubit.loadUserData();

      // 更新状态
      final currentState = state as HomeLoaded;
      emit(
        HomeLoaded(
          quickActions: currentState.quickActions,
          recentMessages: currentState.recentMessages,
          isDeviceConnected: _deviceControlCubit.isConnected,
          connectedDeviceName: _deviceControlCubit.connectedDeviceName,
        ),
      );
    } catch (e) {
      Logger.error('刷新数据失败: $e');
      emit(HomeError('刷新数据失败: $e'));
    }
  }

  /// 执行快速操作
  Future<void> executeQuickAction(String actionId) async {
    if (state is! HomeLoaded) return;

    final currentState = state as HomeLoaded;
    if (!currentState.isDeviceConnected) {
      emit(HomeError('请先连接设备'));
      return;
    }

    try {
      switch (actionId) {
        case 'send_message':
          await _deviceControlCubit.sendSimpleNotification(text: '快速测试消息');
          break;
        case 'test_vibration':
          await _deviceControlCubit.sendSimpleNotification(
            text: '震动测试',
            vibration: VibrationPattern.medium,
          );
          break;
        case 'test_led':
          await _deviceControlCubit.sendRgbSequence(
            colors: [
              RgbColor.colorRed,
              RgbColor.colorGreen,
              RgbColor.colorBlue,
            ],
            text: 'LED测试',
            duration: 2000,
          );
          break;
        case 'emergency':
          await _deviceControlCubit.sendUrgentNotification('紧急呼叫测试');
          break;
      }

      // 重新加载数据以更新状态
      await refreshData();
    } catch (e) {
      Logger.error('执行快速操作失败: $e');
      emit(HomeError('操作失败: $e'));
    }
  }

  /// 标记消息为已读
  void markMessageAsRead(String messageId) {
    if (state is! HomeLoaded) return;

    final currentState = state as HomeLoaded;
    final updatedMessages = currentState.recentMessages.map((message) {
      if (message.id == messageId) {
        return MessageInfo(
          id: message.id,
          title: message.title,
          content: message.content,
          time: message.time,
          isRead: true,
        );
      }
      return message;
    }).toList();

    emit(
      HomeLoaded(
        quickActions: currentState.quickActions,
        recentMessages: updatedMessages,
        isDeviceConnected: currentState.isDeviceConnected,
        connectedDeviceName: currentState.connectedDeviceName,
      ),
    );
  }
}
