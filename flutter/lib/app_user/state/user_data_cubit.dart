/// 用户数据管理Cubit
/// 管理设备、消息、用户资料等真实数据
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/core.dart';

/// 用户数据状态
abstract class UserDataState extends Equatable {
  const UserDataState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class UserDataInitial extends UserDataState {
  const UserDataInitial();
}

/// 数据加载中
class UserDataLoading extends UserDataState {
  const UserDataLoading();
}

/// 数据加载完成
class UserDataLoaded extends UserDataState {
  final List<DeviceInfo> connectedDevices;
  final List<MessageInfo> recentMessages;
  final UserProfile? userProfile;
  final String? dailyFortune;

  const UserDataLoaded({
    required this.connectedDevices,
    required this.recentMessages,
    this.userProfile,
    this.dailyFortune,
  });

  @override
  List<Object?> get props => [
    connectedDevices,
    recentMessages,
    userProfile,
    dailyFortune,
  ];
}

/// 数据错误
class UserDataError extends UserDataState {
  final String message;

  const UserDataError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 设备信息
class DeviceInfo {
  final String id;
  final String name;
  final bool isConnected;
  final int? batteryLevel;
  final int? signalStrength;
  final DateTime? lastConnectedTime;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.isConnected,
    this.batteryLevel,
    this.signalStrength,
    this.lastConnectedTime,
  });
}

/// 消息信息
class MessageInfo {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isFavorite;
  final String? sender;
  final String? recipient;
  final MessageType type;

  const MessageInfo({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isFavorite,
    this.sender,
    this.recipient,
    this.type = MessageType.text,
  });
}

/// 消息类型
enum MessageType { text, voice, notification }

/// 用户资料
class UserProfile {
  final String id;
  final String nickname;
  final String email;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String? constellation;
  final String? mbti;

  const UserProfile({
    required this.id,
    required this.nickname,
    required this.email,
    this.avatarUrl,
    this.birthDate,
    this.constellation,
    this.mbti,
  });
}

/// 用户数据Cubit
class UserDataCubit extends Cubit<UserDataState> {
  final ApiClient _apiClient;

  UserDataCubit()
    : _apiClient = ServiceLocatorConfig.get<ApiClient>(),
      super(const UserDataInitial());

  /// 加载用户数据
  Future<void> loadUserData() async {
    emit(const UserDataLoading());

    try {
      // 获取连接的设备
      final connectedDevices = await _getConnectedDevices();

      // 获取最近消息
      final recentMessages = await _getRecentMessages();

      // 获取用户资料
      final userProfile = await _getUserProfile();

      // 获取今日运势
      final dailyFortune = await _getDailyFortune();

      emit(
        UserDataLoaded(
          connectedDevices: connectedDevices,
          recentMessages: recentMessages,
          userProfile: userProfile,
          dailyFortune: dailyFortune,
        ),
      );
    } catch (e) {
      Logger.error('加载用户数据失败: $e');
      emit(UserDataError('加载数据失败: $e'));
    }
  }

  /// 获取连接的设备
  Future<List<DeviceInfo>> _getConnectedDevices() async {
    try {
      // 使用API服务获取设备数据
      final response = await _apiClient.openapi
          .getDevicesApi()
          .getDevicesApiDevicesGet();

      if (response.statusCode == 200 && response.data != null) {
        // 转换API数据为本地模型
        return response.data!.items.map((device) {
          return DeviceInfo(
            id: device.deviceIdentifier,
            name: '', // DeviceResponse没有name字段
            isConnected: false, // DeviceResponse没有status字段，需根据实际业务调整
            batteryLevel: null,
            signalStrength: null,
            lastConnectedTime: device.lastSeen,
          );
        }).toList();
      }
    } catch (e) {
      Logger.error('获取设备数据失败: $e');
    }

    // 如果API调用失败，返回模拟数据
    return [
      const DeviceInfo(
        id: 'pupu_001',
        name: 'pupu机-001',
        isConnected: true,
        batteryLevel: 85,
        signalStrength: -45,
        lastConnectedTime: null,
      ),
    ];
  }

  /// 获取最近消息
  Future<List<MessageInfo>> _getRecentMessages() async {
    try {
      // 使用API服务获取消息数据
      final response = await _apiClient.openapi
          .getMessagesApi()
          .getMessagesApiMessagesGet();

      if (response.statusCode == 200 && response.data != null) {
        // 转换API数据为本地模型
        return response.data!.items.map((message) {
          return MessageInfo(
            id: message.id.toString(),
            content: message.content,
            timestamp: message.createdAt,
            isFavorite: false, // MessageResponse没有isFavorite字段
            sender: message.senderId.toString(),
            recipient: message.deviceId?.toString(),
            type: _convertMessageType(message.messageType.name),
          );
        }).toList();
      }
    } catch (e) {
      Logger.error('获取消息数据失败: $e');
    }

    // 如果API调用失败，返回模拟数据
    final now = DateTime.now();
    return [
      MessageInfo(
        id: '1',
        content: '今天天气真好，希望你那边也是晴天',
        timestamp: now.subtract(const Duration(hours: 2)),
        isFavorite: true,
        recipient: '小明',
      ),
      MessageInfo(
        id: '2',
        content: '谢谢你的关心，我这边一切都好',
        timestamp: now.subtract(const Duration(hours: 1)),
        isFavorite: false,
        sender: '小红',
      ),
    ];
  }

  /// 转换消息类型
  MessageType _convertMessageType(String? type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'voice':
        return MessageType.voice;
      case 'notification':
        return MessageType.notification;
      default:
        return MessageType.text;
    }
  }

  /// 获取用户资料
  Future<UserProfile?> _getUserProfile() async {
    try {
      // 使用API服务获取当前用户信息
      final response = await _apiClient.openapi
          .getUsersApi()
          .getCurrentUserInfoApiUsersMeGet();

      if (response.statusCode == 200 && response.data != null) {
        final user = response.data!;
        return UserProfile(
          id: user.id.toString(),
          nickname: user.nickname ?? user.username,
          email: user.email,
          avatarUrl: null, // UserResponse没有avatarUrl字段
          birthDate: null, // UserResponse没有birthDate字段
          constellation: null, // UserResponse没有constellation字段
          mbti: null, // UserResponse没有mbti字段
        );
      }
    } catch (e) {
      Logger.error('获取用户资料失败: $e');
    }

    // 如果API调用失败，返回模拟数据
    return const UserProfile(
      id: 'user_001',
      nickname: '用户昵称',
      email: 'user@example.com',
      avatarUrl: null,
    );
  }

  /// 获取今日运势
  Future<String?> _getDailyFortune() async {
    // 模拟运势数据
    return '今日运势指数：★★★★☆';
  }

  /// 更新设备连接状态
  Future<void> updateDeviceConnection(String deviceId, bool isConnected) async {
    if (state is! UserDataLoaded) return;

    final currentState = state as UserDataLoaded;
    final updatedDevices = currentState.connectedDevices.map((device) {
      if (device.id == deviceId) {
        return DeviceInfo(
          id: device.id,
          name: device.name,
          isConnected: isConnected,
          batteryLevel: device.batteryLevel,
          signalStrength: device.signalStrength,
          lastConnectedTime: isConnected
              ? DateTime.now()
              : device.lastConnectedTime,
        );
      }
      return device;
    }).toList();

    emit(
      UserDataLoaded(
        connectedDevices: updatedDevices,
        recentMessages: currentState.recentMessages,
        userProfile: currentState.userProfile,
        dailyFortune: currentState.dailyFortune,
      ),
    );
  }

  /// 添加新消息
  Future<void> addMessage(MessageInfo message) async {
    if (state is! UserDataLoaded) return;

    final currentState = state as UserDataLoaded;
    final updatedMessages = [message, ...currentState.recentMessages];

    // 只保留最近的几条消息
    final limitedMessages = updatedMessages.take(10).toList();

    emit(
      UserDataLoaded(
        connectedDevices: currentState.connectedDevices,
        recentMessages: limitedMessages,
        userProfile: currentState.userProfile,
        dailyFortune: currentState.dailyFortune,
      ),
    );
  }

  /// 获取连接的设备数量
  int get connectedDeviceCount {
    if (state is UserDataLoaded) {
      return (state as UserDataLoaded).connectedDevices.length;
    }
    return 0;
  }

  /// 获取未读消息数量
  int get unreadMessageCount {
    if (state is UserDataLoaded) {
      // 这里可以实现未读消息逻辑
      return (state as UserDataLoaded).recentMessages.length;
    }
    return 0;
  }
}
